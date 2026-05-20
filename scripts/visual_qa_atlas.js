#!/usr/bin/env node
/* eslint-disable no-console */
"use strict";

const fs = require("fs");
const path = require("path");
const os = require("os");
const http = require("http");
const { pathToFileURL } = require("url");
const { spawn } = require("child_process");

function chromeCandidates() {
  return [
    process.env.CHROME_PATH,
    "C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe",
    "C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe",
    "C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe",
    "C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe",
    "/usr/bin/google-chrome",
    "/usr/bin/chromium",
    "/usr/bin/chromium-browser",
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  ].filter(Boolean);
}

function findBrowser() {
  const hit = chromeCandidates().find(candidate => fs.existsSync(candidate));
  if (!hit) {
    throw new Error("No Chrome/Chromium/Edge executable found. Set CHROME_PATH to run visual QA.");
  }
  return hit;
}

function htmlDecode(value) {
  return String(value || "")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

function routeUrl(baseUrl, target, viewport, options) {
  const opts = options || {};
  const url = new URL(baseUrl);
  url.searchParams.set("qaTab", target.tab);
  if (target.sub) url.searchParams.set("qaSub", target.sub);
  if (target.search) url.searchParams.set("qaSearch", target.search);
  if (opts.overflow) url.searchParams.set("qaOverflow", "1");
  if (opts.capture !== false) url.searchParams.set("qaCapture", "1");
  url.searchParams.set("qaViewport", viewport.name);
  return url.href;
}

function hashUrl(baseUrl, hash) {
  const url = new URL(baseUrl);
  url.hash = String(hash || "").replace(/^#/, "");
  return url.href;
}

function httpJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, response => {
      let body = "";
      response.setEncoding("utf8");
      response.on("data", chunk => { body += chunk; });
      response.on("end", () => {
        if (response.statusCode < 200 || response.statusCode >= 300) {
          reject(new Error(`HTTP ${response.statusCode} for ${url}: ${body}`));
          return;
        }
        try {
          resolve(JSON.parse(body));
        } catch (error) {
          reject(new Error(`Invalid JSON from ${url}: ${error.message}`));
        }
      });
    }).on("error", reject);
  });
}

async function retry(fn, label, attempts = 40, delay = 150) {
  let lastError = null;
  for (let index = 0; index < attempts; index += 1) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;
      await sleep(delay);
    }
  }
  throw new Error(`${label} failed after ${attempts} attempts: ${lastError ? lastError.message : "unknown error"}`);
}

function pngDimensions(buffer) {
  if (!buffer || buffer.length < 24 || buffer.toString("ascii", 1, 4) !== "PNG") {
    throw new Error("Captured screenshot is not a valid PNG.");
  }
  return {
    width: buffer.readUInt32BE(16),
    height: buffer.readUInt32BE(20)
  };
}

class CdpSession {
  constructor(wsUrl) {
    this.wsUrl = wsUrl;
    this.ws = null;
    this.nextId = 1;
    this.pending = new Map();
    this.waiters = [];
  }

  async open() {
    if (typeof WebSocket !== "function") {
      throw new Error("This Node.js runtime does not expose a WebSocket client.");
    }
    this.ws = new WebSocket(this.wsUrl);
    await new Promise((resolve, reject) => {
      this.ws.addEventListener("open", resolve, { once: true });
      this.ws.addEventListener("error", event => reject(new Error(`CDP websocket failed: ${event.message || "connection error"}`)), { once: true });
    });
    this.ws.addEventListener("message", event => this.handleMessage(event.data));
  }

  handleMessage(data) {
    const message = JSON.parse(String(data));
    if (message.id && this.pending.has(message.id)) {
      const { resolve, reject, timer } = this.pending.get(message.id);
      clearTimeout(timer);
      this.pending.delete(message.id);
      if (message.error) reject(new Error(`${message.error.message || "CDP error"} (${message.error.code || "unknown"})`));
      else resolve(message.result || {});
      return;
    }
    if (message.method) {
      const waiters = this.waiters.slice();
      waiters.forEach(waiter => {
        if (waiter.method === message.method) {
          clearTimeout(waiter.timer);
          this.waiters = this.waiters.filter(item => item !== waiter);
          waiter.resolve(message.params || {});
        }
      });
    }
  }

  send(method, params, timeout = 15000) {
    const id = this.nextId++;
    const payload = JSON.stringify({ id, method, params: params || {} });
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`CDP method timed out: ${method}`));
      }, timeout);
      this.pending.set(id, { resolve, reject, timer });
      this.ws.send(payload);
    });
  }

  waitForEvent(method, timeout = 15000) {
    return new Promise((resolve, reject) => {
      const waiter = { method, resolve, reject, timer: null };
      waiter.timer = setTimeout(() => {
        this.waiters = this.waiters.filter(item => item !== waiter);
        reject(new Error(`Timed out waiting for CDP event: ${method}`));
      }, timeout);
      this.waiters.push(waiter);
    });
  }

  close() {
    if (this.ws) this.ws.close();
  }
}

async function startBrowser(browserPath) {
  const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), "daly-atlas-qa-chrome-"));
  const browserFlags = [
    "--headless=new",
    "--disable-gpu",
    "--disable-gpu-compositing",
    "--disable-software-rasterizer",
    "--disable-dev-shm-usage",
    "--disable-features=VizDisplayCompositor",
    "--no-sandbox",
    "--force-device-scale-factor=1",
    "--hide-scrollbars",
    "--allow-file-access-from-files",
    "--no-first-run",
    "--no-default-browser-check",
    `--user-data-dir=${userDataDir}`,
    "--remote-debugging-port=0",
    "about:blank"
  ];
  const proc = spawn(browserPath, browserFlags, { stdio: ["ignore", "pipe", "pipe"], windowsHide: true });
  let output = "";
  const devtoolsUrl = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`Chrome did not expose DevTools in time.\n${output}`)), 15000);
    const onData = data => {
      output += String(data);
      const match = output.match(/DevTools listening on (ws:\/\/[^\s]+)/);
      if (match) {
        clearTimeout(timer);
        resolve(match[1]);
      }
    };
    proc.stdout.on("data", onData);
    proc.stderr.on("data", onData);
    proc.on("exit", code => {
      clearTimeout(timer);
      reject(new Error(`Chrome exited before DevTools was ready (${code}).\n${output}`));
    });
  });
  const port = new URL(devtoolsUrl).port;
  return { proc, port, userDataDir };
}

async function createPageSession(browserState) {
  const targets = await retry(
    () => httpJson(`http://127.0.0.1:${browserState.port}/json/list`),
    "Chrome target discovery"
  );
  const pageTarget = targets.find(target => target.type === "page" && target.webSocketDebuggerUrl);
  if (!pageTarget) throw new Error("No debuggable Chrome page target was found.");
  const session = new CdpSession(pageTarget.webSocketDebuggerUrl);
  await session.open();
  await session.send("Page.enable");
  await session.send("Runtime.enable");
  return session;
}

async function waitForPageReady(session) {
  await session.send("Runtime.evaluate", {
    expression: `
      new Promise(resolve => {
        const done = () => window.setTimeout(resolve, 900);
        if (document.readyState === "complete") done();
        else window.addEventListener("load", done, { once: true });
      })
    `,
    awaitPromise: true,
    returnByValue: true
  }, 20000);
}

async function renderRoute(session, url, viewport, screenshotPath, label, renderOptions) {
  const options = renderOptions || {};
  await session.send("Emulation.setDeviceMetricsOverride", {
    width: viewport.width,
    height: viewport.height,
    deviceScaleFactor: 1,
    mobile: false,
    screenWidth: viewport.width,
    screenHeight: viewport.height
  });
  try {
    await session.send("Emulation.setVisibleSize", { width: viewport.width, height: viewport.height });
  } catch (error) {
    // Some Chromium builds ignore setVisibleSize under modern headless mode.
  }
  const loadEvent = session.waitForEvent("Page.loadEventFired", 20000).catch(() => null);
  await session.send("Page.navigate", { url });
  await loadEvent;
  await waitForPageReady(session);
  if (options.autoScroll === false) {
    await session.send("Runtime.evaluate", { expression: "window.scrollTo(0, 0)", returnByValue: true });
    await sleep(120);
  } else {
    await session.send("Runtime.evaluate", {
      expression: `
        (() => {
          const params = new URL(location.href).searchParams;
          if (params.get("qaCapture") === "1") return;
          const hashQuery = new URLSearchParams((location.hash.split("?")[1] || ""));
          const routedSearch = params.get("qaSearch") || hashQuery.get("q") || "";
          if (!routedSearch) {
            window.scrollTo(0, 0);
            return;
          }
          const activePane = document.querySelector(".tab-page.active .sub-pane.active") || document.querySelector(".tab-page.active");
          const highlighted = document.querySelector(".search-highlight");
          const target = highlighted || (activePane && (activePane.querySelector(".toolbar") || activePane.querySelector(".panel-head"))) || activePane;
          if (target) target.scrollIntoView({ block: highlighted ? "center" : "start", inline: "nearest" });
        })()
      `,
      returnByValue: true
    });
    await sleep(120);
  }
  if (options.scrollSelector) {
    await session.send("Runtime.evaluate", {
      expression: `
        (() => {
          const target = document.querySelector(${JSON.stringify(options.scrollSelector)});
          if (target) target.scrollIntoView({ block: "start", inline: "nearest" });
        })()
      `,
      returnByValue: true
    });
    await sleep(180);
  }
  const metricsResult = await session.send("Runtime.evaluate", {
    expression: `({
      windowInnerWidth: window.innerWidth,
      windowInnerHeight: window.innerHeight,
      documentElementClientWidth: document.documentElement.clientWidth,
      bodyScrollWidth: document.body.scrollWidth,
      devicePixelRatio: window.devicePixelRatio,
      href: window.location.href,
      hash: window.location.hash,
      globalSearchValue: document.getElementById("global-atlas-search") ? document.getElementById("global-atlas-search").value : "",
      semanticSearchValue: document.getElementById("semantic-search") ? document.getElementById("semantic-search").value : "",
      semanticCodeSearchValue: document.getElementById("semantic-code-search") ? document.getElementById("semantic-code-search").value : "",
      clinicalVariableSearchValue: document.getElementById("clinical-variable-search") ? document.getElementById("clinical-variable-search").value : ""
    })`,
    returnByValue: true
  });
  const metrics = metricsResult.result.value;
  const screenshot = await session.send("Page.captureScreenshot", {
    format: "png",
    fromSurface: true,
    captureBeyondViewport: false
  });
  const screenshotBuffer = Buffer.from(screenshot.data, "base64");
  const screenshotSize = pngDimensions(screenshotBuffer);
  if (screenshotPath) fs.writeFileSync(screenshotPath, screenshotBuffer);
  const domResult = await session.send("Runtime.evaluate", {
    expression: "document.documentElement.outerHTML",
    returnByValue: true
  });
  const dom = domResult.result.value || "";
  const mismatches = [];
  if (metrics.windowInnerWidth !== viewport.width) mismatches.push(`window.innerWidth=${metrics.windowInnerWidth}`);
  if (metrics.documentElementClientWidth !== viewport.width) mismatches.push(`documentElement.clientWidth=${metrics.documentElementClientWidth}`);
  if (screenshotSize.width !== viewport.width) mismatches.push(`screenshotWidth=${screenshotSize.width}`);
  if (mismatches.length) {
    throw new Error(`${label} viewport mismatch for ${viewport.name}; requested ${viewport.width}px but saw ${mismatches.join(", ")}.`);
  }
  return { dom, metrics, screenshotSize };
}

function extractOverflowReport(dom, target, viewport, render) {
  const match = dom.match(/<pre[^>]*id=["']qa-overflow-report["'][^>]*>([\s\S]*?)<\/pre>/i);
  if (!match) {
    throw new Error(`Overflow report was not found in rendered DOM for ${target.name} ${viewport.name}.`);
  }
  const report = JSON.parse(htmlDecode(match[1]));
  report.target = target.name;
  report.viewportName = viewport.name;
  report.requestedViewport = { width: viewport.width, height: viewport.height };
  report.windowInnerWidth = render.metrics.windowInnerWidth;
  report.windowInnerHeight = render.metrics.windowInnerHeight;
  report.documentElementClientWidth = render.metrics.documentElementClientWidth;
  report.bodyScrollWidth = render.metrics.bodyScrollWidth;
  report.screenshotWidth = render.screenshotSize.width;
  report.screenshotHeight = render.screenshotSize.height;
  return report;
}

const htmlPath = path.resolve(process.argv[2] || "site/DALYCARE_atlas.html");
const outDir = path.resolve(process.argv[3] || "qa_screenshots");

if (!fs.existsSync(htmlPath)) {
  console.error(`HTML file not found: ${htmlPath}`);
  process.exit(2);
}

ensureDir(outDir);
const baseUrl = pathToFileURL(htmlPath).href;

const targets = [
  { name: "overview", tab: "overview", sub: "overview-summary" },
  { name: "clinical_variables", tab: "variables", sub: "variables-concepts" },
  { name: "vitals", tab: "clinical", sub: "clinical-vitals" },
  { name: "social_history", tab: "clinical", sub: "clinical-social" },
  { name: "mcl_triangle", tab: "clinical-feasibility", sub: "mcl-triangle-feasibility" },
  { name: "imaging", tab: "clinical", sub: "clinical-imaging" },
  { name: "damyda", tab: "registries", sub: "reg-damyda" },
  { name: "lyfo", tab: "registries", sub: "reg-lyfo" },
  { name: "cll", tab: "registries", sub: "reg-cll" },
  { name: "treatment", tab: "treatment", sub: "treatment-dashboard" },
  { name: "laboratory", tab: "laboratory", sub: "lab-npu" },
  { name: "biobank", tab: "laboratory", sub: "lab-biobank" },
  { name: "microbiology", tab: "clinical", sub: "clinical-microbiology" },
  { name: "pathology", tab: "clinical", sub: "clinical-pathology" },
  { name: "data_dictionary", tab: "dictionary", sub: "dictionary-lineage" }
];

const qaViewports = [
  { name: "desktop", width: 1440, height: 1000 },
  { name: "mobile", width: 390, height: 844 },
  { name: "mobile_375", width: 375, height: 844 }
];

const normalViewports = [
  { name: "normal_360", width: 360, height: 844, suffix: "mobile_360" },
  { name: "normal_375", width: 375, height: 844, suffix: "mobile_375" },
  { name: "normal_390", width: 390, height: 844, suffix: "mobile_390" },
  { name: "normal_414", width: 414, height: 896, suffix: "mobile_414" },
  { name: "normal_482", width: 482, height: 900, suffix: "mobile_482" }
];

// Required normal screenshot names include overview_normal_mobile_360.png,
// overview_normal_mobile_375.png, overview_normal_mobile_390.png,
// overview_normal_mobile_414.png, and overview_normal_mobile_482.png.
const normalScreenshotCaptures = [
  { file: "overview_normal_desktop.png", name: "overview_normal", tab: "overview", sub: "overview-summary", viewport: qaViewports[0] },
  { file: "run_status_normal_desktop.png", name: "run_status_normal", tab: "overview", sub: "overview-summary", viewport: qaViewports[0], scrollSelector: "#overview-run-status" },
  { file: "run_status_normal_mobile_375.png", name: "run_status_normal", tab: "overview", sub: "overview-summary", viewport: normalViewports[1], scrollSelector: "#overview-run-status" },
  { file: "resource_catalog_normal_desktop.png", name: "resource_catalog_normal", tab: "infrastructure", sub: "infra-catalog", viewport: qaViewports[0] },
  { file: "resource_catalog_normal_mobile_375.png", name: "resource_catalog_normal", tab: "infrastructure", sub: "infra-catalog", viewport: normalViewports[1] },
  ...normalViewports.map(viewport => ({ file: `overview_normal_${viewport.suffix}.png`, name: "overview_normal", tab: "overview", sub: "overview-summary", viewport })),
  { file: "overview_normal_mobile.png", name: "overview_normal", tab: "overview", sub: "overview-summary", viewport: normalViewports[2] },
  { file: "overview_normal_mobile_375.png", name: "overview_normal", tab: "overview", sub: "overview-summary", viewport: normalViewports[1] },
  { file: "data_dictionary_normal_mobile_375_smoking.png", name: "data_dictionary_normal", tab: "dictionary", sub: "dictionary-lineage", search: "smoking", viewport: normalViewports[1] },
  { file: "data_dictionary_normal_mobile.png", name: "data_dictionary_normal", tab: "dictionary", sub: "dictionary-lineage", search: "smoking", viewport: normalViewports[2] },
  { file: "code_maps_normal_mobile_375_NPU02319.png", name: "code_maps_normal", tab: "dictionary", sub: "dictionary-codes", search: "NPU02319", viewport: normalViewports[1], autoScroll: false },
  { file: "code_maps_normal_mobile.png", name: "code_maps_normal", tab: "dictionary", sub: "dictionary-codes", search: "NPU02319", viewport: normalViewports[2], autoScroll: false },
  { file: "clinical_variables_normal_mobile_375_height.png", name: "clinical_variables_normal", tab: "variables", sub: "variables-concepts", search: "height", viewport: normalViewports[1] },
  { file: "clinical_variables_normal_mobile.png", name: "clinical_variables_normal", tab: "variables", sub: "variables-concepts", search: "height", viewport: normalViewports[2] },
  { file: "treatment_normal_mobile_375_rituximab.png", name: "treatment_normal", tab: "treatment", sub: "treatment-dashboard", search: "rituximab", viewport: normalViewports[1] },
  { file: "treatment_normal_mobile.png", name: "treatment_normal", tab: "treatment", sub: "treatment-dashboard", search: "rituximab", viewport: normalViewports[2] },
  { file: "mcl_triangle_desktop.png", name: "mcl_triangle_normal", tab: "clinical-feasibility", sub: "mcl-triangle-feasibility", viewport: qaViewports[0] },
  { file: "mcl_triangle_mobile.png", name: "mcl_triangle_normal", tab: "clinical-feasibility", sub: "mcl-triangle-feasibility", viewport: normalViewports[2] }
];

const normalOverflowCaptures = [
  { name: "overview_normal", tab: "overview", sub: "overview-summary" },
  { name: "data_dictionary_normal", tab: "dictionary", sub: "dictionary-lineage", search: "smoking" },
  { name: "code_maps_normal", tab: "dictionary", sub: "dictionary-codes", search: "NPU02319" },
  { name: "clinical_variables_normal", tab: "variables", sub: "variables-concepts", search: "height" },
  { name: "treatment_normal", tab: "treatment", sub: "treatment-dashboard", search: "rituximab" }
];

const deepLinkChecks = [
  { name: "codes-query", hash: "#dictionary/dictionary-codes?q=NPU02319", inputKey: "semanticCodeSearchValue", inputValue: "NPU02319", mustContain: ["dictionary/dictionary-codes", "q=NPU02319"] },
  { name: "codes-query-item", hash: "#dictionary/dictionary-codes?q=NPU02319&item=npu_npu02319_haemoglobin", inputKey: "semanticCodeSearchValue", inputValue: "NPU02319", mustContain: ["q=NPU02319", "item=npu_npu02319_haemoglobin"] },
  { name: "lineage-query", hash: "#dictionary/dictionary-lineage?q=smoking", inputKey: "semanticSearchValue", inputValue: "smoking", mustContain: ["dictionary/dictionary-lineage", "q=smoking"] },
  { name: "variables-query", hash: "#variables/variables-concepts?q=height", inputKey: "clinicalVariableSearchValue", inputValue: "height", mustContain: ["variables/variables-concepts", "q=height"] }
];

async function main() {
  const browserState = await startBrowser(findBrowser());
  let session = null;
  const reports = [];
  try {
    session = await createPageSession(browserState);
    for (const viewport of qaViewports) {
      for (const target of targets) {
        const screenshotPath = path.join(outDir, `${target.name}_${viewport.name}.png`);
        await renderRoute(session, routeUrl(baseUrl, target, viewport, { overflow: false, capture: true }), viewport, screenshotPath, `screenshot ${target.name} ${viewport.name}`);
        const overflowRender = await renderRoute(session, routeUrl(baseUrl, target, viewport, { overflow: true, capture: true }), viewport, null, `overflow ${target.name} ${viewport.name}`);
        const report = extractOverflowReport(overflowRender.dom, target, viewport, overflowRender);
        if (target.name === "overview") {
          report.overviewConsolidationPresent = /What can I find in DALY-CARE\?/.test(overflowRender.dom) &&
            /global-atlas-search/.test(overflowRender.dom) &&
            /Search the atlas/.test(overflowRender.dom) &&
            /Environment:/.test(overflowRender.dom) &&
            /Pipeline status/.test(overflowRender.dom) &&
            /Atlas restoration status/.test(overflowRender.dom) &&
            /Common cross-panel routes/.test(overflowRender.dom) &&
            /Global scope and caveats/.test(overflowRender.dom);
        }
        if (target.name === "data_dictionary") {
          report.dataDictionaryDetailStackPresent = /class=["'][^"']*semantic-detail-stack/.test(overflowRender.dom);
          const fullLineage = overflowRender.dom.match(/<div[^>]*class=["'][^"']*semantic-full-lineage[^"']*["'][^>]*>([\s\S]*?)<div[^>]*class=["'][^"']*lineage-block["'][^>]*>\s*<h3>Value map<\/h3>/i);
          report.dataDictionaryFullLineageTablePresent = fullLineage ? /<table/i.test(fullLineage[1]) : true;
        }
        if (target.name === "microbiology") {
          report.microbiologyAtGlancePresent = /class=["'][^"']*microbiology-at-a-glance/.test(overflowRender.dom) && /At a glance/.test(overflowRender.dom);
        }
        if (target.name === "imaging") {
          report.imagingPanelPresent = /Medical imaging atlas/.test(overflowRender.dom) && /Imaging evidence layers/.test(overflowRender.dom) && /Raw names \/ data lineage/.test(overflowRender.dom);
        }
        if (target.name === "pathology") {
          report.pathologyPanelPresent = /Pathology \/ PATOBANK atlas/.test(overflowRender.dom) && /Pathology evidence layers/.test(overflowRender.dom) && /Raw names \/ data lineage/.test(overflowRender.dom);
        }
        if (target.name === "biobank") {
          report.biobankPanelPresent = /Biobank sample atlas/.test(overflowRender.dom) && /Biobank evidence layers/.test(overflowRender.dom) && /Sample sources/.test(overflowRender.dom) && /Raw names \/ data lineage/.test(overflowRender.dom);
        }
        if (target.name === "mcl_triangle") {
          report.mclTrianglePanelPresent = /MCL \/ TRIANGLE feasibility/.test(overflowRender.dom) &&
            /Study-readiness matrix/.test(overflowRender.dom) &&
            /Treatment-timing feasibility/.test(overflowRender.dom) &&
            /feasibility assessment only/.test(overflowRender.dom);
        }
        reports.push(report);
      }
    }

    for (const capture of normalScreenshotCaptures) {
      await renderRoute(
        session,
        routeUrl(baseUrl, capture, capture.viewport, { overflow: false, capture: false }),
        capture.viewport,
        path.join(outDir, capture.file),
        `normal screenshot ${capture.file}`,
        { autoScroll: capture.autoScroll !== false, scrollSelector: capture.scrollSelector || "" }
      );
    }

    for (const capture of normalOverflowCaptures) {
      for (const viewport of normalViewports) {
        const overflowRender = await renderRoute(
          session,
          routeUrl(baseUrl, capture, viewport, { overflow: true, capture: false }),
          viewport,
          null,
          `normal overflow ${capture.name} ${viewport.name}`
        );
        const report = extractOverflowReport(overflowRender.dom, { name: `${capture.name}_normal` }, viewport, overflowRender);
        reports.push(report);
      }
    }

    for (const check of deepLinkChecks) {
      const render = await renderRoute(
        session,
        hashUrl(baseUrl, check.hash),
        normalViewports[1],
        null,
        `deep link ${check.name}`
      );
      const hash = decodeURIComponent(render.metrics.hash || "");
      const missing = (check.mustContain || []).filter(value => !hash.includes(value));
      if (missing.length || render.metrics[check.inputKey] !== check.inputValue) {
        throw new Error(`Deep-link check ${check.name} failed. Hash=${hash}; ${check.inputKey}=${render.metrics[check.inputKey]}; missing=${missing.join(", ")}`);
      }
    }

    const reportPath = path.join(outDir, "overflow_report.json");
    fs.writeFileSync(reportPath, `${JSON.stringify(reports, null, 2)}\n`);
    const desktopReportPath = path.join(outDir, "overflow_desktop.json");
    const mobileReportPath = path.join(outDir, "overflow_mobile.json");
    fs.writeFileSync(
      desktopReportPath,
      `${JSON.stringify(reports.filter(report => report.viewportName === "desktop"), null, 2)}\n`
    );
    fs.writeFileSync(
      mobileReportPath,
      `${JSON.stringify(reports.filter(report => report.viewportName !== "desktop"), null, 2)}\n`
    );

    const failures = reports.filter(report =>
      report.bodyOverflow ||
      (report.overflowing || []).length ||
      (report.windowInnerWidth !== report.requestedViewport.width) ||
      (report.documentElementClientWidth !== report.requestedViewport.width) ||
      (report.screenshotWidth !== report.requestedViewport.width) ||
      (report.target === "overview" && !report.overviewConsolidationPresent) ||
      (report.target === "data_dictionary" && (!report.dataDictionaryDetailStackPresent || report.dataDictionaryFullLineageTablePresent)) ||
      (report.target === "microbiology" && !report.microbiologyAtGlancePresent) ||
      (report.target === "imaging" && !report.imagingPanelPresent) ||
      (report.target === "pathology" && !report.pathologyPanelPresent) ||
      (report.target === "biobank" && !report.biobankPanelPresent) ||
      (report.target === "mcl_triangle" && !report.mclTrianglePanelPresent)
    );
    if (failures.length) {
      console.error(`Visual overflow QA failed for ${failures.length} rendered views. Report: ${reportPath}`);
      console.error(JSON.stringify(failures.slice(0, 3), null, 2));
      process.exitCode = 1;
      return;
    }
    console.log(`Visual QA passed. Screenshots and split overflow reports written to ${outDir}`);
  } finally {
    if (session) session.close();
    try {
      if (!browserState.proc.killed) {
        const exited = new Promise(resolve => browserState.proc.once("exit", resolve));
        browserState.proc.kill();
        await Promise.race([exited, sleep(1000)]);
      }
    } catch (error) {}
    try {
      fs.rmSync(browserState.userDataDir, { recursive: true, force: true });
    } catch (error) {
      console.warn(`Warning: could not remove temporary Chrome profile ${browserState.userDataDir}: ${error.message}`);
    }
  }
}

main().catch(error => {
  console.error(error.stack || error.message || String(error));
  process.exit(1);
});
