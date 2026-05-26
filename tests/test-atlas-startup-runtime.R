root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = FALSE)
source(file.path(root, "tests", "helper.R"))
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0 || all(is.na(x))) y else x
}

read_text <- function(path) {
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

template_path <- file.path(root, "inst", "templates", "DALYCARE_atlas.html")
template <- read_text(template_path)

cache_pos <- regexpr("let semanticOverlayResolverCache = null", template, fixed = TRUE)[[1]]
derive_pos <- regexpr("const semanticRows = semanticDeriveDisplayRows(rawSemanticRows)", template, fixed = TRUE)[[1]]
expect_true(cache_pos > 0, "Atlas template should initialize semanticOverlayResolverCache.")
expect_true(derive_pos > 0, "Atlas template should derive semantic display rows.")
expect_true(cache_pos < derive_pos, "semanticOverlayResolverCache must be initialized before semanticDeriveDisplayRows is called.")

node_candidates <- unique(c(
  Sys.getenv("NODE", unset = ""),
  Sys.which("node"),
  file.path(Sys.getenv("USERPROFILE", unset = ""), ".cache", "codex-runtimes", "codex-primary-runtime", "dependencies", "node", "bin", "node.exe")
))
node <- node_candidates[nzchar(node_candidates) & file.exists(node_candidates)][1]
expect_true(nzchar(node %||% ""), "Node.js is required for atlas startup runtime regression.")

node_script <- tempfile("atlas-startup-runtime-", fileext = ".js")
template_js_path <- gsub("\\\\", "/", template_path)
template_js_path <- gsub("'", "\\\\'", template_js_path, fixed = TRUE)
writeLines(enc2utf8(c(
  "const fs = require('fs');",
  "const vm = require('vm');",
  sprintf("const html = fs.readFileSync('%s', 'utf8');", template_js_path),
  "const inline = Array.from(html.matchAll(/<script(?:\\s[^>]*)?>([\\s\\S]*?)<\\/script>/gi), m => m[1]).filter(s => s.includes('const payload = window.DALYCARE_ATLAS_PAYLOAD'))[0];",
  "class El {",
  "  constructor(id='') { this.id=id; this.innerHTML=''; this.textContent=''; this.value=''; this.checked=false; this.dataset={}; this.style={}; this.children=[]; this.classList={add(){},remove(){},toggle(){},contains(){return false}}; }",
  "  appendChild(x){ this.children.push(x); return x; } addEventListener(){} removeEventListener(){} setAttribute(k,v){ this[k]=v; } getAttribute(k){ return this[k] || ''; }",
  "  querySelector(){ return new El(); } querySelectorAll(){ return []; } closest(){ return null; } scrollIntoView(){} focus(){}",
  "}",
  "const elements = new Map();",
  "const document = {",
  "  body: new El('body'), documentElement: new El('html'),",
  "  getElementById(id){ if (!elements.has(id)) elements.set(id, new El(id)); return elements.get(id); },",
  "  querySelector(){ return new El(); }, querySelectorAll(){ return []; }, createElement(){ return new El(); },",
  "  addEventListener(evt, cb){ if (evt === 'DOMContentLoaded') cb(); }",
  "};",
  "const payload = {",
  "  run_id: 'runtime-test', generated_at: '2026-05-25T00:00:00+0000', builder_credit: 'runtime test',",
  "  hero_metrics: [{ metric: 'source_count', label: 'Sources', value: '1', tone: 'good' }], catalog_rows: [], panels: {}, panel_groups: [],",
  "  semantic_dictionary_rows: [{ semantic_id: 'npu01459', raw_code: 'NPU01459', code_system: 'NPU', clinical_variable: 'NPU01459', source_name: 'LABKA', mapping_status: 'candidate' }],",
  "  semantic_code_map_rows: [{ semantic_id: 'npu01459-code', code: 'NPU01459', code_system: 'NPU', code_name: 'NPU01459', clinical_variable: 'NPU01459', source_name: 'LABKA', mapping_status: 'candidate' }],",
  "  semantic_overlay_lookup_rows: [{ entity_scope_key: 'NPU:NPU01459', code_system: 'NPU', entity_code: 'NPU01459', target_code_system: 'NPU', comparable_code_system: 'NPU', normalized_code: 'NPU01459', display_label: 'P-Carbamide; subst.c. = ? mmol/L', source_display: 'LABKA', provenance_label: 'Curated semantic overlay from config/semantic-unmapped-entity-map.tsv', overlay_action: 'wired_overlay', mapping_status: 'wired_overlay', promotion_eligible: 'yes' }],",
  "  panel_distribution_rows: [",
  "    { panel_id: 'clinical_social_history', raw_column: 'ryger', raw_value: 'Er holdt op', display_value: 'Former smoker', n: '12' },",
  "    { panel_id: 'clinical_social_history', raw_column: 'drikker', raw_value: 'Ja', display_value: 'Alcohol use yes', n: '8' }",
  "  ],",
  "  panel_raw_field_rows: [",
  "    { panel_id: 'clinical_social_history', source_name: 'SP_Social_Hx', raw_column: 'ryger', clinical_variable: 'Smoking status' },",
  "    { panel_id: 'clinical_social_history', source_name: 'SP_Social_Hx', raw_column: 'drikker', clinical_variable: 'Alcohol use' }",
  "  ],",
  "  semantic_unmapped_entity_overlay_rows: [], semantic_mapping_conflict_rows: []",
  "};",
  "const context = { window: { DALYCARE_ATLAS_PAYLOAD: payload, location: { hash:'', search:'', pathname:'/DALYCARE_atlas.html' }, addEventListener(){}, history:{pushState(){}, replaceState(){}}, navigator:{clipboard:null} }, document, console, URLSearchParams, setTimeout, clearTimeout, Blob, URL: { createObjectURL(){return 'blob:test'}, revokeObjectURL(){} } };",
  "context.window.window = context.window; context.window.document = document;",
  "vm.createContext(context);",
  "vm.runInContext(inline, context, { filename: 'atlas-inline.js', timeout: 120000 });",
  "if ((elements.get('hero-copy') && elements.get('hero-copy').textContent) === 'Loading run payload...') throw new Error('hero-copy was not updated from loading state');",
  "if (!(elements.get('run-id') && /runtime-test/.test(elements.get('run-id').textContent))) throw new Error('run id did not render');",
  "console.log('atlas startup runtime regression passed');"
)), node_script, useBytes = TRUE)

runtime <- system2(node, node_script, stdout = TRUE, stderr = TRUE)
status <- attr(runtime, "status") %||% 0L
expect_equal(as.integer(status), 0L, paste(runtime, collapse = "\n"))

for (path in c(template_path)) {
  text <- read_text(path)
  for (marker in c("â", "Ã", "�")) {
    expect_false(grepl(marker, text, fixed = TRUE), paste("Mojibake marker should not appear in", basename(path), ":", marker))
  }
}

mojibake_codepoint_markers <- c(intToUtf8(0x00E2), intToUtf8(0x00C3), intToUtf8(0xFFFD))
for (path in c(template_path)) {
  text <- read_text(path)
  for (marker in mojibake_codepoint_markers) {
    expect_false(grepl(marker, text, fixed = TRUE), paste("Mojibake codepoint should not appear in", basename(path), ":", marker))
  }
}

cat("Atlas startup runtime regression tests passed\n")
