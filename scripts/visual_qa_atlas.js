#!/usr/bin/env node
/* eslint-disable no-console */
"use strict";

const fs = require("fs");
const path = require("path");
const { pathToFileURL } = require("url");
const { spawnSync } = require("child_process");

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

function run(browser, args, label) {
  const result = spawnSync(browser, args, { encoding: "utf8", windowsHide: true, maxBuffer: 200 * 1024 * 1024 });
  if (result.status !== 0) {
    throw new Error(`${label} failed with exit ${result.status}\nSTDOUT:\n${result.stdout || ""}\nSTDERR:\n${result.stderr || ""}`);
  }
  return result.stdout || "";
}

function htmlDecode(value) {
  return String(value || "")
    .replace(/&quot;/g, "\"")
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">");
}

function routeUrl(baseUrl, target, viewport, overflow) {
  const url = new URL(baseUrl);
  url.searchParams.set("qaTab", target.tab);
  if (target.sub) url.searchParams.set("qaSub", target.sub);
  if (target.search) url.searchParams.set("qaSearch", target.search);
  if (overflow) url.searchParams.set("qaOverflow", "1");
  url.searchParams.set("qaCapture", "1");
  url.searchParams.set("qaViewport", viewport.name);
  return url.href;
}

function ensureDir(dir) {
  fs.mkdirSync(dir, { recursive: true });
}

const htmlPath = path.resolve(process.argv[2] || "site/DALYCARE_atlas.html");
const outDir = path.resolve(process.argv[3] || "qa_screenshots");

if (!fs.existsSync(htmlPath)) {
  console.error(`HTML file not found: ${htmlPath}`);
  process.exit(2);
}

ensureDir(outDir);
const browser = findBrowser();
const baseUrl = pathToFileURL(htmlPath).href;

const targets = [
  { name: "overview", tab: "overview", sub: "overview-summary" },
  { name: "clinical_variables", tab: "variables", sub: "variables-concepts" },
  { name: "vitals", tab: "clinical", sub: "clinical-vitals" },
  { name: "social_history", tab: "clinical", sub: "clinical-social" },
  { name: "damyda", tab: "registries", sub: "reg-damyda" },
  { name: "lyfo", tab: "registries", sub: "reg-lyfo" },
  { name: "data_dictionary", tab: "dictionary", sub: "dictionary-lineage" }
];

const viewports = [
  { name: "desktop", width: 1440, height: 1000 },
  { name: "mobile", width: 390, height: 844 }
];

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
  "--allow-file-access-from-files"
];

const reports = [];
for (const viewport of viewports) {
  for (const target of targets) {
    const screenshotPath = path.join(outDir, `${target.name}_${viewport.name}.png`);
    run(browser, [
      ...browserFlags,
      `--window-size=${viewport.width},${viewport.height}`,
      `--screenshot=${screenshotPath}`,
      routeUrl(baseUrl, target, viewport, false)
    ], `screenshot ${target.name} ${viewport.name}`);

    const dom = run(browser, [
      ...browserFlags,
      `--window-size=${viewport.width},${viewport.height}`,
      "--virtual-time-budget=3000",
      "--dump-dom",
      routeUrl(baseUrl, target, viewport, true)
    ], `overflow ${target.name} ${viewport.name}`);

    const match = dom.match(/<pre[^>]*id=["']qa-overflow-report["'][^>]*>([\s\S]*?)<\/pre>/i);
    if (!match) {
      throw new Error(`Overflow report was not found in rendered DOM for ${target.name} ${viewport.name}.`);
    }
    const report = JSON.parse(htmlDecode(match[1]));
    report.target = target.name;
    report.viewportName = viewport.name;
    if (target.name === "data_dictionary") {
      report.dataDictionaryDetailStackPresent = /class=["'][^"']*semantic-detail-stack/.test(dom);
      const fullLineage = dom.match(/<div[^>]*class=["'][^"']*semantic-full-lineage[^"']*["'][^>]*>([\s\S]*?)<div[^>]*class=["'][^"']*lineage-block["'][^>]*>\s*<h3>Value map<\/h3>/i);
      report.dataDictionaryFullLineageTablePresent = fullLineage ? /<table/i.test(fullLineage[1]) : true;
    }
    reports.push(report);
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
  `${JSON.stringify(reports.filter(report => report.viewportName === "mobile"), null, 2)}\n`
);

const failures = reports.filter(report =>
  report.bodyOverflow ||
  (report.overflowing || []).length ||
  (report.target === "data_dictionary" && (!report.dataDictionaryDetailStackPresent || report.dataDictionaryFullLineageTablePresent))
);
if (failures.length) {
  console.error(`Visual overflow QA failed for ${failures.length} rendered views. Report: ${reportPath}`);
  console.error(JSON.stringify(failures.slice(0, 3), null, 2));
  process.exit(1);
}

console.log(`Visual QA passed. Screenshots and split overflow reports written to ${outDir}`);
