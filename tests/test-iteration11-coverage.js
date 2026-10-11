const {test}=require('node:test');
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const html=fs.readFileSync(require('node:path').join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
function runtime(years=[],regionCounts=[]) {
 const output={},nodes={}; const node=id=>nodes[id]||={value:'',innerHTML:'',options:[],listeners:{},addEventListener(k,fn){this.listeners[k]=fn;}};
 const regions=[{region_code:'01',region_name:'Capital',svg_path:'M0 0',ehr_status:'ehr',lab_status:'nationwide',damyda_n:null,pct_total:null,story:'Nationwide register coverage'},{region_code:'02',region_name:'Zealand',svg_path:'M1 1',damyda_n:0,pct_total:0}];
 const ctx=vm.createContext({URLSearchParams,reviewTemporal:{years},reviewSpatial:{region_counts:regionCounts,region_coverage:[]},reviewDk:{regions,map_regions:regions},regionState:{code:'01'},sourceDisplayName:x=>x,clinicalDisplayEntry:()=>null,setHtml:(id,v)=>output[id]=v,document:{getElementById:node,querySelectorAll:()=>[]}});
 const load=(start,end)=>{const a=html.indexOf(start),b=html.indexOf(end,a);assert.ok(a>=0&&b>a);vm.runInContext(html.slice(a,b),ctx);};
 load('      function text(', '      function metric(');load('      function observedRowsWithheld(', '      function sourceTiles(');load('      function finiteSummary(', '      function fieldPrivacyLabel(');load('      function cssClass(', '      function uniqueValues(');
 return {output,node,ctx,run:code=>vm.runInContext(code,ctx)};
}
// Grouping on source or date alone loses one producer estimate; last-write wins hides conflicts.
test('time counts preserve source field and basis groups with visible count states',()=>{
 const {run,output}=runtime([{table_name:'X',date_column:'A',coverage_basis:'event_date_counts',year:2020,n_rows:12},{table_name:'X',date_column:'A',coverage_basis:'streamed_event_date_counts',year:2020,n_rows:27},{table_name:'X',date_column:'B',coverage_basis:'event_date_counts',year:2020,n_rows:0},{table_name:'X',date_column:'B',coverage_basis:'event_date_counts',year:2022,n_rows:null,count_privacy_status:'withheld_small_cells'}]);
 run('renderTemporalCoverage()');const view=output['temporal-heatmap'];
 assert.equal((view.match(/data-time-source="X"/g)||[]).length,3);assert.match(view,/>12<\/span>/);assert.match(view,/>27<\/span>/);assert.match(view,/>0<\/span>/);assert.match(view,/>Count withheld<\/span>/);assert.match(view,/>Not supplied<\/span>/);assert.match(view,/data-date-field="B"/);assert.match(view,/streamed_event_date_counts/);
 const selected=run("renderSourceYearCounts('X')");assert.equal((selected.match(/class="source-year-counts"/g)||[]).length,3);assert.match(selected,/Recorded year counts \(streamed\)/);
});
test('duplicate time identity is explicit and inferred ranges never paint observed years',()=>{
 const {run,output}=runtime([{table_name:'X',date_column:'A',coverage_basis:'event_date_counts',year:2020,n_rows:12},{table_name:'X',date_column:'A',coverage_basis:'event_date_counts',year:2020,n_rows:99},{table_name:'X',date_column:'B',coverage_basis:'source_date_range',year:2001,n_rows:456,date_privacy_status:'withheld_derived_source_range'}]);
 run('renderTemporalCoverage()');assert.match(output['temporal-heatmap'],/Duplicate evidence; count not selected/);assert.match(output['temporal-heatmap'],/Inferred source date range; bounds withheld/);assert.doesNotMatch(output['temporal-heatmap'],/>2001<|>456<|>99<\/span>|>12<\/span>/);
 const selected=run("renderSourceYearCounts('X')");assert.match(selected,/Duplicate evidence/);assert.doesNotMatch(selected,/>2001<|>456</);
});
// The selected source share denominator must follow evidence basis, without recomputation.
test('place rows format safe counts and preserve the two supplied percentage denominators',()=>{
 const counts=[{table_name:'Direct',region_code:'01',region_column:'area',count_basis:'region_column_counts',n_rows:0,pct_rows:12.345,value_privacy_status:'protected_field'},{table_name:'Registry',region_code:'01',region_column:'Reg_Region',count_basis:'registry_region_panel',n_rows:44,pct_rows:23.456},{table_name:'Unknown',region_code:'01',count_basis:'unknown',n_rows:null,pct_rows:98.765},{table_name:'Protected',region_code:'01',count_basis:'streamed_region_column_counts',n_rows:987654,pct_rows:88,count_privacy_status:'withheld_small_cells'}];
 const {run,output}=runtime([],counts);run('renderRegionDetail()');const view=output.regionDetail;
 assert.match(view,/data-region-source="Direct"/);assert.match(view,/>0<\/strong>/);assert.match(view,/12.3% of all source records/);assert.match(view,/23.5% of retained mapped-region counts/);assert.match(view,/Count withheld/);assert.match(view,/Not supplied/);assert.doesNotMatch(view,/987,654|98.765|88%|Nationwide register coverage|<table/);assert.match(view,/National source scope/);assert.match(view,/inferred from source metadata/);assert.match(view,/Map share: Not supplied/);
});
test('native region selection shares map state and keeps the existing select node',()=>{
 const {run,output,node,ctx}=runtime();run('renderSpatialCoverage()');const select=node('region-select');assert.match(select.innerHTML,/value="02"/);select.value='02';select.listeners.change();assert.equal(ctx.regionState.code,'02');assert.equal(node('region-select'),select);assert.match(output.regionDetail,/Zealand/);assert.match(output.dkMap,/data-region-code="02"/);
});



test('time overview retains a group with an absent year and a withheld count',()=>{
 const {run,output}=runtime([{table_name:'X',date_column:'A',coverage_basis:'event_date_counts',year:null,n_rows:null,count_privacy_status:'withheld_small_cells'}]);
 run('renderTemporalCoverage()');assert.match(output['temporal-heatmap'],/Year not supplied: Count withheld/);assert.match(output['temporal-heatmap'],/A/);assert.doesNotMatch(output['temporal-heatmap'],/>0</);
});

test('unreviewed regional status keeps its uncertainty and none remains a support status',()=>{
 const {run}=runtime();assert.match(run("coveragePill('none')"),/No default EHR support/);assert.doesNotMatch(run("coveragePill('none')"),/No records|No clinical data/i);assert.match(run("coveragePill('new_status')"),/Regional status not interpreted/);assert.match(run("coveragePill('new_status')"),/title="new_status"/);assert.doesNotMatch(run("coveragePill('no')"),/>[^<]*\bno\b/i);
});
