const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
function fn(name,ctx){
  const start=html.indexOf(`      function ${name}(`),end=html.indexOf('\n      function ',start+1);
  assert.ok(start>=0,`Missing function: ${name}`);
  vm.runInContext(html.slice(start,end<0?undefined:end),ctx);
}
function runtime(extra={}){
  const ctx=vm.createContext({URLSearchParams,catalogRows:[],columnRows:[],reviewClinical:{},panelDistributionRows:[],panelRawFieldRows:[],clinicalConceptRows:[],domainPanelRows:[],panelKpiRows:[],
    sourceDisplayName:value=>value,clinicalDisplayEntry:()=>null,...extra});
  const start=html.indexOf('      function text('),end=html.indexOf('      function metric(',start);
  vm.runInContext(html.slice(start,end),ctx);
  for(const name of ['finiteSummary','browseFieldsLink','sourceEvidenceLinks','observedRowsWithheld','scanScopeNote'])fn(name,ctx);
  const helpers=html.split('/* DOMAIN_SOURCE_EVIDENCE_START */')[1]?.split('/* DOMAIN_SOURCE_EVIDENCE_END */')[0];
  assert.ok(helpers,'Exact domain source evidence helpers are missing');
  vm.runInContext(helpers,ctx);
  return {ctx,run:code=>vm.runInContext(code,ctx)};
}
function evidenceRenderers(ctx){
  ctx.semanticOverlayDisplayForRow=()=>null;
  ctx.semanticOverlaySourceForDisplay=value=>value;
  ctx.semanticRawName=row=>row.raw_column || '';
  ctx.renderScopeChip=()=>'';
  const start=html.indexOf('      function scopeLabel('),end=html.indexOf('      function renderConceptCard(',start);
  vm.runInContext(html.slice(start,end),ctx);
  for(const name of ['toneColor','renderBadge','hasDisplayValue'])fn(name,ctx);
}

test('selected field summaries block both counts when availability is withheld and preserve a published zero',()=>{
  const {ctx,run}=runtime();
  for(const values of [{n_available:null,n_missing:null},{n_available:9999,n_missing:1}]){
    ctx.row={table_name:'SP_SocialHX',column_name:'ryger',availability_privacy_status:'withheld_small_complementary_cells',...values};
    const field=run('renderDomainFieldProfile(row)');
    assert.match(field,/Withheld: small groups and related counts/);
    assert.doesNotMatch(field,/9,999|1 missing|counts are not supplied/);
  }
  ctx.row={table_name:'SP_SocialHX',column_name:'ryger',n_available:0,n_missing:50};
  const published=run('renderDomainFieldProfile(row)');assert.match(published,/0 source records with a value/);assert.match(published,/50 missing source records/);
});

test('missing panel metadata retains source routes and separately supplied distribution or lineage evidence',()=>{
  for(const supplied of [{panelDistributionRows:[{panel_id:'diagnosis_atlas',distribution_type:'categorical',raw_value:'Confirmed',n:50}]},{panelRawFieldRows:[{panel_id:'diagnosis_atlas',source_name:'SDS_diagnoser',raw_column:'diagnosekode',raw_field_label:'Diagnosis code'}]}]){
    const {ctx,run}=runtime({catalogRows:[{table_name:'SDS_diagnoser'}],columnRows:[{table_name:'SDS_diagnoser',column_name:'diagnosekode'}],...supplied});
    evidenceRenderers(ctx);fn('renderDomainPanel',ctx);
    const panel=run("renderDomainPanel('diagnosis_atlas')");
    assert.match(panel,/data-source-fields="SDS_diagnoser"/);assert.match(panel,/field=diagnosekode/);
    assert.doesNotMatch(panel,/No generated product-layer domain panel/);
    assert.match(panel,supplied.panelDistributionRows ? /Confirmed[\s\S]*50/ : /Diagnosis code/);
  }
});

test('registry-only privacy-safe imaging distributions survive the source-backed fallback',()=>{
  const row={panel_id:'reg_damyda',source_name:'RKKP_DaMyDa',raw_column:'Reg_Knogleundersoegelser_ct',raw_value:'Yes',n:50,distribution_type:'categorical',clinical_concept_id:'myeloma_ct_modality'};
  const {ctx,run}=runtime({panelDistributionRows:[row],catalogRows:[{table_name:'RKKP_DaMyDa'}]});
  evidenceRenderers(ctx);ctx.renderTermHelp=()=>'';
  const start=html.indexOf('      const imagingLayerSpecs ='),end=html.indexOf('      const microbiologyLayerSpecs =',start);
  vm.runInContext(html.slice(start,end),ctx);
  assert.equal(run("domainPublishedDistributions('clinical_imaging').length"),1);
  assert.doesNotMatch(run("domainSummaryStatus('clinical_imaging')"),/not supplied/);
  const panel=run('renderImagingPanel()');assert.match(panel,/Reg_Knogleundersoegelser_ct \| Yes/);assert.match(panel,/<div class="val">50<\/div>/);
});

test('empty panel curation still exposes exact current diagnosis sources and their field routes',()=>{
  const {ctx,run}=runtime({catalogRows:[{table_name:'SDS_diagnoser',n_rows:100,n_cols:3},{table_name:'SP_BilleddiagnostikeUndersoegelser_Del1',n_rows:40,n_cols:2}],
    columnRows:[{table_name:'SDS_diagnoser',column_name:'diagnosekode',n_available:95}],
    reviewClinical:{diagnoses:[{table_name:'SDS_diagnoser'},{table_name:'SP_BilleddiagnostikeUndersoegelser_Del1'}]}});
  fn('renderDomainPanel',ctx);
  const panel=run("renderDomainPanel('diagnosis_atlas')");
  assert.match(panel,/SDS_diagnoser/);assert.match(panel,/data-source-fields="SDS_diagnoser"/);
  assert.match(panel,/field=diagnosekode/);assert.match(panel,/view=timeplace&amp;source=SDS_diagnoser/);
  assert.doesNotMatch(panel,/SP_BilleddiagnostikeUndersoegelser_Del1|No generated product-layer/);
  assert.equal((panel.match(/data-domain-summary-status/g)||[]).length,1);
});

test('source inventories reject missing and near-match sources and deduplicate only declared aliases',()=>{
  const {ctx,run}=runtime({catalogRows:[{table_name:'BIOBANK_SAMPLES',n_rows:0,n_cols:4},{table_name:'LAB_BIOBANK_SAMPLES',n_rows:0,n_cols:4},{table_name:'BIOBANK_SAMPLES_extra'},{table_name:'similar',n_rows:20}],columnRows:[{table_name:'BIOBANK_SAMPLES',column_name:'Sample_source'}]});
  ctx.specs=[{source:'BIOBANK_SAMPLES',aliases:['LAB_BIOBANK_SAMPLES']},{source:'LAB_BIOBANK_SAMPLES',aliases:['BIOBANK_SAMPLES']},{source:'missing'},{source:'similar'}];
  const names=Array.from(run('domainSourceInventory(specs).map(item=>item.source)'));
  assert.deepEqual(names,['BIOBANK_SAMPLES','similar']);
  const cards=run('renderDomainSourceCards(specs)');
  assert.equal((cards.match(/data-domain-source=/g)||[]).length,2);assert.match(cards,/0 full-source records/);
  assert.doesNotMatch(cards,/BIOBANK_SAMPLES_extra|data-source-fields="LAB_BIOBANK_SAMPLES"|source=missing/);
});

test('admissions and notes exclude substring false positives in declared review inventories',()=>{
  const names=['SP_ADT_haendelser','SP_AdministreretMedicin','SP_Journalnotater_Del1','SDS_epikur','t_mikro'];
  const {run}=runtime({catalogRows:names.map(table_name=>({table_name})),reviewClinical:{admissions:names.slice(0,2).map(table_name=>({table_name})),notes:names.slice(2).map(table_name=>({table_name}))}});
  assert.deepEqual(Array.from(run("domainSourceInventory(domainSourceSpecs('clinical_adt')).map(item=>item.source)")),['SP_ADT_haendelser']);
  assert.deepEqual(Array.from(run("domainSourceInventory(domainSourceSpecs('clinical_notes')).map(item=>item.source)")),['SP_Journalnotater_Del1','t_mikro']);
});

test('missing review arrays do not hide maintained exact sources with current catalog evidence',()=>{
  const {run}=runtime({catalogRows:[{table_name:'SDS_diagnoser'},{table_name:'Flytningshistorik'},{table_name:'SDS_t_udtilsgh'},{table_name:'SDS_forloeb'},{table_name:'forloebsmarkoerer'}]});
  assert.deepEqual(Array.from(run("domainSourceInventory(domainSourceSpecs('diagnosis_atlas')).map(item=>item.source)")),['SDS_diagnoser']);
  assert.deepEqual(Array.from(run("domainSourceInventory(domainSourceSpecs('clinical_adt')).map(item=>item.source)")),['Flytningshistorik','SDS_t_udtilsgh','SDS_forloeb','forloebsmarkoerer']);
});

test('declared alias identities with separate current profiles remain separately reviewable',()=>{
  const {ctx,run}=runtime({catalogRows:[{table_name:'BIOBANK_SAMPLES',n_rows:100},{table_name:'LAB_BIOBANK_SAMPLES',n_rows:200}],columnRows:[{table_name:'BIOBANK_SAMPLES',column_name:'Sample_source'},{table_name:'LAB_BIOBANK_SAMPLES',column_name:'Type'}]});
  ctx.specs=[{source:'BIOBANK_SAMPLES',aliases:['LAB_BIOBANK_SAMPLES']}];
  const cards=run('renderDomainSourceCards(specs)');
  assert.equal((cards.match(/data-domain-source=/g)||[]).length,2);
  assert.match(cards,/100 full-source records/);assert.match(cards,/200 full-source records/);
  assert.match(cards,/data-source-fields="BIOBANK_SAMPLES"/);assert.match(cards,/data-source-fields="LAB_BIOBANK_SAMPLES"/);
});

test('withheld or null categories cannot create dummy bars while a supplied zero count remains published',()=>{
  const {ctx,run}=runtime({panelDistributionRows:[
    {panel_id:'clinical_social_history',raw_column:'ryger',raw_value:'Ja',n:null,value_privacy_status:'withheld_unvalidated_distribution'},
    {panel_id:'clinical_social_history',raw_column:'ryger',raw_value:'Aldrig',n:null},
    {panel_id:'clinical_social_history',raw_column:'drikker',raw_value:'Nej',n:0}
  ]});
  fn('normalizeClinicalKey',ctx);fn('renderSocialValueRows',ctx);
  assert.equal(run("renderSocialValueRows('ryger',[{raw:'Ja',display:'Current smoker'},{raw:'Aldrig',display:'Never smoker'}])").includes('class="track"'),false);
  assert.deepEqual(Array.from(run("domainPublishedDistributions('clinical_social_history').map(row=>row.raw_value)")),['Nej']);
  assert.match(run("domainSummaryStatus('clinical_social_history')"),/withheld/i);
});

test('source and selected field links preserve punctuation and do not invent missing field profiles',()=>{
  const source='SP Ø & part/1',field='value + unit';
  const {ctx,run}=runtime({catalogRows:[{table_name:source,n_rows:25}],columnRows:[{table_name:source,column_name:field,n_available:0,n_missing:25}]});
  ctx.specs=[{source,fields:[field,'absent']}];
  const cards=run('renderDomainSourceCards(specs)');
  const links=[...cards.matchAll(/href="([^"]+)"/g)].map(match=>new URL(match[1].replace(/&amp;/g,'&'),'https://atlas.test/'));
  assert.ok(links.some(link=>link.searchParams.get('view')==='timeplace'&&link.searchParams.get('source')===source));
  assert.ok(links.some(link=>link.searchParams.get('field')===field&&link.searchParams.get('source')===source));
  assert.equal(links.some(link=>link.searchParams.get('field')==='absent'),false);
  assert.match(cards,/0 source records with a value/);assert.match(cards,/25 missing source records/);
});

test('social history uses exact available fields as smoking and alcohol actions',()=>{
  const {ctx,run}=runtime({reviewClinical:{social_history:[{table_name:'SP_SocialHX'}]},catalogRows:[{table_name:'SP_SocialHX',n_rows:100,n_cols:3}],columnRows:['ryger','drikker','pakkeromdagen'].map(column_name=>({table_name:'SP_SocialHX',column_name,n_available:30,n_missing:70}))});
  fn('normalizeClinicalKey',ctx);fn('renderSocialValueRows',ctx);fn('socialHasUnknownMissing',ctx);fn('renderSocialHistoryPanel',ctx);
  const panel=run('renderSocialHistoryPanel()');
  assert.match(panel,/field=ryger/);assert.match(panel,/field=drikker/);assert.match(panel,/field=pakkeromdagen/);
  assert.doesNotMatch(panel,/Smoking status ryger|Alcohol use drikker|SP_Social_Hx\.ryger|class="track"|verified pack-years/);
});

test('selected temporal evidence links retain the source for annual and date-field rows',()=>{
  const nodes={'temporal-source-filter':{value:'SP Ø & part/1'},'temporal-year-evidence':{},'temporal-date-evidence':{}};
  const {ctx,run}=runtime({document:{getElementById:id=>nodes[id]},reviewTemporal:{years:[]},setHtml(){},renderSourceYearCounts:()=>''});
  fn('renderTemporalCoverage',ctx);run('renderTemporalCoverage()');
  for(const [id,table] of [['temporal-year-evidence','atlas_temporal_coverage_years'],['temporal-date-evidence','atlas_temporal_coverage']]){
    const href=new URL(nodes[id].href || '', 'https://atlas.test/');
    assert.equal(href.searchParams.get('source'),'SP Ø & part/1');assert.equal(href.searchParams.get('table'),table);
  }
});
