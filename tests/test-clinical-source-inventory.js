const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const html=fs.readFileSync(path.join(__dirname,'../inst/templates/DALYCARE_atlas.html'),'utf8').replace(/\r/g,'');
const fixture=require('./fixtures/clinical-source-membership.json');
const copy=value=>JSON.parse(JSON.stringify(value));
function fn(name,ctx){
  const start=html.indexOf(`      function ${name}(`),end=html.indexOf('\n      function ',start+1);
  assert.ok(start>=0,`Missing function: ${name}`);
  vm.runInContext(html.slice(start,end<0?undefined:end),ctx);
}
function runtime(extra={}){
  const ctx=vm.createContext({URLSearchParams,payload:{},catalogRows:[],columnRows:[],reviewClinical:{},reviewModuleReadiness:[],reviewOverview:{},panelDistributionRows:[],panelRawFieldRows:[],clinicalConceptRows:[],domainPanelRows:[],panelKpiRows:[],sourceDisplayName:value=>value,clinicalDisplayEntry:()=>null,semanticOverlayDisplayForRow:()=>null,semanticOverlaySourceForDisplay:value=>value,...extra});
  const start=html.indexOf('      function text('),end=html.indexOf('      function metric(',start);
  vm.runInContext(html.slice(start,end),ctx);
  for(const name of ['finiteSummary','browseFieldsLink','sourceEvidenceLinks','observedRowsWithheld','scanScopeNote'])fn(name,ctx);
  const helpers=html.split('/* DOMAIN_SOURCE_EVIDENCE_START */')[1]?.split('/* DOMAIN_SOURCE_EVIDENCE_END */')[0];
  assert.ok(helpers,'Domain source helpers must be executable');vm.runInContext(helpers,ctx);
  return {ctx,run:code=>vm.runInContext(code,ctx)};
}
function fixtureRuntime(name,extra={}){
  const sample=copy(fixture.selector_cases.find(item=>item.name===name));
  assert.ok(sample,`Missing shared fixture: ${name}`);
  return runtime({payload:{clinical_source_inventory:sample.expected},catalogRows:Array.isArray(sample.input.catalog_rows)?sample.input.catalog_rows:[],columnRows:sample.input.column_profile_rows,...extra});
}
function names(run,panel){return Array.from(run(`domainSourceInventory(domainSourceSpecs('${panel}')).map(item=>item.source)`));}

// Dropping metadata authority, applying a stem matcher, normalizing identities, or
// deduplicating aliases by field profiles must each fail these literal cases.
for(const sample of fixture.selector_cases){
  test(`shared supplied memberships retain exact client identities: ${sample.name}`,()=>{
    const {run}=fixtureRuntime(sample.name);
    for(const panel of fixture.covered_panel_ids){
      assert.deepEqual(names(run,panel),sample.expected.rows.filter(row=>row.panel_id===panel).map(row=>row.source_key),panel);
    }
  });
}

test('both aliases keep their own counts, exact routes, and unequal field profiles',()=>{
  const {run}=fixtureRuntime('both_alias_identities_with_unequal_profiles');
  const cards=run("renderDomainSourceCards(domainSourceSpecs('clinical_biobank'))");
  assert.equal((cards.match(/data-domain-source=/g)||[]).length,2);
  assert.match(cards,/70 full-source records/);assert.match(cards,/7 full-source records/);
  const split=cards.split('<article ').slice(1);
  const unprofiled=split.find(card=>card.includes('data-domain-source="BIOBANK_SAMPLES"'));
  assert.match(unprofiled,/0 published field profiles/);assert.doesNotMatch(unprofiled,/data-source-fields=|field=Type/);
  assert.match(unprofiled,/view=timeplace&amp;source=BIOBANK_SAMPLES/);
  assert.match(cards,/data-source-fields="LAB_BIOBANK_SAMPLES"/);
  assert.match(cards,/field=Type/);assert.match(cards,/validate their relationship/i);
});

test('presentation fields follow membership IDs while aliases retain the original Unicode key',()=>{
  const {ctx,run}=fixtureRuntime('exact_case_and_unicode_without_normalization',{columnRows:[{table_name:'SP_BilleddiagnostiskeUndersøgelser_Del1',column_name:'bld_kode',n_available:2}]});
  ctx.imagingPanelDistributionRows=()=>[];
  const cards=run("renderDomainSourceOverview('clinical_imaging')");
  const links=[...cards.matchAll(/href="([^"]+)"/g)].map(match=>new URL(match[1].replace(/&amp;/g,'&'),'https://atlas.test/'));
  assert.ok(links.some(link=>link.searchParams.get('source')==='SP_BilleddiagnostiskeUndersøgelser_Del1'&&link.searchParams.get('field')==='bld_kode'));
  assert.ok(links.some(link=>link.searchParams.get('source')==='SP_BilleddiagnostiskeUndersøgelser_Del1'&&link.searchParams.get('view')==='timeplace'));
  assert.doesNotMatch(cards,/source=SP_BilleddiagnostikeUndersoegelser_Del1/);
});

test('duplicate catalog counts remain inspectable without choosing or summing a count',()=>{
  const {run}=fixtureRuntime('duplicate_identity_and_conflicting_lineage');
  const cards=run("renderDomainSourceCards(domainSourceSpecs('clinical_biobank'))");
  assert.equal((cards.match(/data-domain-source=/g)||[]).length,1);
  assert.match(cards,/ambiguous/i);assert.match(cards,/Original catalog evidence/);
  assert.match(cards,/7 source records/);assert.match(cards,/70 source records/);
  assert.doesNotMatch(cards,/7 full-source records|70 full-source records|77 full-source records/);
  const lineage=run("renderDomainSourceCards(domainSourceSpecs('clinical_social_history'))");
  assert.match(lineage,/conflicting/i);assert.match(lineage,/view=timeplace&amp;source=SP_SocialHX/);
});

test('duplicate actual catalog evidence stays ambiguous even if supplied metadata claims unique',()=>{
  const sample=copy(fixture.selector_cases.find(item=>item.name==='duplicate_identity_and_conflicting_lineage'));
  sample.expected.rows[0].catalog_identity_state='unique';sample.expected.rows[0].load_status='ok';sample.expected.rows[0].load_state='loaded';
  const {run}=runtime({payload:{clinical_source_inventory:sample.expected},catalogRows:sample.input.catalog_rows});
  const cards=run("renderDomainSourceCards(domainSourceSpecs('clinical_biobank'))");
  assert.match(cards,/ambiguous/i);assert.doesNotMatch(cards,/7 full-source records|70 full-source records/);
  assert.equal(run("clinicalSourceReadinessRows().find(row=>row.panel_id==='clinical_biobank').loaded_count"),0);
});

test('missing, malformed and unsupported present metadata blocks fallback with a visible limitation',()=>{
  const base=copy(fixture.selector_cases[0].expected);
  const values=[null,[],{}, {...base,schema_version:2},{...base,rows:{}},{...base,rows:[{panel_id:'diagnosis_atlas',source_key:'SDS_diagnoser'}]},JSON.parse('{"schema_version":1,"__proto__":{}}'),{...base,rows:[{...base.rows[0],source_key:'constructor'}]}, {...base,rows:[{...base.rows[0],n_rows:123}]}];
  for(const inventory of values){
    const {run}=runtime({payload:{clinical_source_inventory:inventory},catalogRows:[{table_name:'SDS_diagnoser',n_rows:123}]});
    assert.deepEqual(names(run,'diagnosis_atlas'),[]);
    const panel=run("renderDomainSourceOverview('diagnosis_atlas')");
    assert.match(panel,/source.inventory limitation/i);assert.match(panel,/Browse data sources/);
    assert.doesNotMatch(panel,/data-domain-source=|123 full-source records/);
  }
});

test('inherited metadata cannot become source authority and does not crash',()=>{
  const base=copy(fixture.selector_cases[0].expected);
  for(const inventory of [Object.create(base),{...base,rows:[Object.create(base.rows[0])]}]){
    const {run}=runtime({payload:{clinical_source_inventory:inventory},catalogRows:[{table_name:'SDS_diagnoser'}]});
    assert.deepEqual(names(run,'diagnosis_atlas'),[]);
    assert.match(run("renderDomainSourceOverview('diagnosis_atlas')"),/source.inventory limitation/i);
  }
});

test('duplicate supplied memberships and conflicting source families cannot assert inventory authority',()=>{
  const base=copy(fixture.selector_cases[0].expected),row=base.rows[0];
  const values=[{...base,rows:[row,row]},{...base,rows:[row,{...row,panel_id:'clinical_adt',membership_id:'unrelated_family'}]},{...base,rows:[{...row,panel_id:'molecular'}]},{...base,rows:[{...row,load_state:'not_loaded'}]},{...base,diagnostics:[{code:'unreviewed_diagnostic',source_key:null,membership_id:null}]}];
  for(const inventory of values){
    const {run}=runtime({payload:{clinical_source_inventory:inventory},catalogRows:[{table_name:'SDS_diagnoser',n_rows:123}]});
    assert.deepEqual(names(run,'diagnosis_atlas'),[]);
    assert.match(run("renderDomainSourceOverview('diagnosis_atlas')"),/source.inventory limitation/i);
  }
});

test('catalog joins never borrow another alias count, fields, or coverage when exact evidence is missing',()=>{
  const sample=copy(fixture.selector_cases.find(item=>item.name==='both_alias_identities_with_unequal_profiles'));
  const {run}=runtime({payload:{clinical_source_inventory:sample.expected},catalogRows:sample.input.catalog_rows.filter(row=>row.table_name!=='BIOBANK_SAMPLES'),columnRows:sample.input.column_profile_rows});
  const cards=run("renderDomainSourceCards(domainSourceSpecs('clinical_biobank'))");
  const missing=cards.split('<article ').find(card=>card.includes('data-domain-source="BIOBANK_SAMPLES"'));
  assert.match(missing,/record count not supplied/);assert.match(missing,/Catalog evidence is not supplied/);
  assert.match(missing,/0 published field profiles/);assert.doesNotMatch(missing,/7 full-source records|field=Type|data-source-fields=/);
  assert.match(missing,/view=timeplace&amp;source=BIOBANK_SAMPLES/);
});

test('supported empty metadata is authoritative and does not resurrect local catalog memberships',()=>{
  const {run}=fixtureRuntime('empty_present_inventory',{catalogRows:[{table_name:'SDS_diagnoser',n_rows:40}]});
  assert.deepEqual(names(run,'diagnosis_atlas'),[]);
  const cards=run("renderDomainSourceOverview('diagnosis_atlas')");
  assert.match(cards,/supplied inventory/i);assert.doesNotMatch(cards,/data-domain-source=|40 full-source records/);
});

test('limited and unavailable inventories preserve uncertainty without claiming upstream absence',()=>{
  for(const name of ['limited_inventory','missing_inventory','malformed_inventory']){
    const {run}=fixtureRuntime(name);
    const panel=run("renderDomainSourceOverview('reg_cll')");
    assert.match(panel,name==='limited_inventory'?/may be incomplete|limited supplied inventory/i:/source.inventory limitation/i);
    assert.doesNotMatch(panel,/not mapped|absent upstream|complete DALY-CARE inventory/i);
    const rows=copy(run('clinicalSourceReadinessRows()'));
    assert.equal(rows.find(row=>row.panel_id==='reg_cll').source_count,name==='limited_inventory'?1:null);
  }
});

test('absent inventory property retains older-export exact fallback and original readiness',()=>{
  const supplied=[{module:'Diagnoses and tumors',source_count:4,n_rows:9999}];
  const {ctx,run}=runtime({catalogRows:[{table_name:'SDS_diagnoser',n_rows:40}],reviewModuleReadiness:supplied});
  ctx.rowsForTable=rows=>JSON.stringify(rows);
  assert.deepEqual(names(run,'diagnosis_atlas'),['SDS_diagnoser']);
  assert.match(run("renderDomainSourceOverview('diagnosis_atlas')"),/40 full-source records/);
  assert.equal(run('renderClinicalModuleReadiness()'),JSON.stringify(supplied));
});

test('covered readiness uses exact source state while uncovered and historical evidence stay unchanged',()=>{
  const supplied=[{module:'Diagnoses and tumors',status:'panel_ready',source_count:99,n_rows:9999},{module:'CLL registry',source_count:9,n_rows:8888},{module:'Medicine and ATC',status:'panel_ready',source_count:8,n_rows:7777},{module:'Molecular, pathology, and biobank readiness',status:'source_ready',source_count:5,n_rows:6666}];
  const {ctx,run}=fixtureRuntime('stem_collisions_and_exact_registry',{reviewModuleReadiness:supplied});
  const before=JSON.stringify({catalog:ctx.catalogRows,profiles:ctx.columnRows,readiness:supplied,inventory:ctx.payload.clinical_source_inventory});
  ctx.rowsForTable=rows=>JSON.stringify(rows);
  const rows=copy(run('clinicalSourceReadinessRows()'));
  const diagnosis=rows.find(row=>row.panel_id==='diagnosis_atlas'),cll=rows.find(row=>row.panel_id==='reg_cll');
  assert.equal(diagnosis.source_count,2);assert.equal(diagnosis.loaded_count,2);
  assert.equal(cll.source_count,1);assert.equal(cll.loaded_count,1);
  assert.equal(diagnosis.n_rows,null);assert.equal(diagnosis.n_columns,null);assert.equal(diagnosis.date_min,'');
  assert.ok(rows.every(row=>row.status!=='panel_ready'));
  const display=run('renderClinicalModuleReadiness()');
  assert.match(display,/Historical supplied readiness metadata/i);assert.match(display,/9999/);
  assert.match(display,/Medicine and ATC/);assert.match(display,/7777/);
  assert.match(display,/Molecular, pathology, and biobank readiness/);assert.match(display,/outside the reviewed source inventory/i);
  assert.equal(JSON.stringify({catalog:ctx.catalogRows,profiles:ctx.columnRows,readiness:supplied,inventory:ctx.payload.clinical_source_inventory}),before);
});

test('load spelling, profile presence, supplied zero and missing counts remain separate readiness facts',()=>{
  const {run}=fixtureRuntime('current_load_states_zero_null_and_legacy_absence');
  const rows=copy(run('clinicalSourceReadinessRows()'));
  const imaging=rows.find(row=>row.panel_id==='clinical_imaging'),vitals=rows.find(row=>row.panel_id==='clinical_vitals'),social=rows.find(row=>row.panel_id==='clinical_social_history');
  assert.equal(imaging.loaded_count,1);assert.equal(imaging.field_profiled_source_count,0);
  assert.equal(vitals.loaded_count,0);assert.equal(vitals.not_loaded_count,1);
  assert.equal(social.unknown_load_count,1);
  assert.match(run("renderDomainSourceCards(domainSourceSpecs('clinical_imaging'))"),/0 full-source records/);
  assert.match(run("renderDomainSourceCards(domainSourceSpecs('clinical_vitals'))"),/record count not supplied/);
});

test('source membership does not create distributions and existing registry-only imaging eligibility survives',()=>{
  const row={panel_id:'reg_damyda',source_name:'RKKP_DaMyDa',raw_column:'Reg_Knogleundersoegelser_ct',raw_value:'Yes',n:50,distribution_type:'categorical',clinical_concept_id:'myeloma_ct_modality'};
  const {ctx,run}=fixtureRuntime('overlapping_views_and_full_procedure_context',{panelDistributionRows:[row,{...row,raw_value:'withheld',n:1,value_privacy_status:'withheld_unvalidated_distribution'}]});
  fn('normalizeClinicalKey',ctx);
  const start=html.indexOf('      const imagingLayerSpecs ='),end=html.indexOf('      const microbiologyLayerSpecs =',start);
  vm.runInContext(html.slice(start,end),ctx);
  assert.deepEqual(Array.from(run("domainPublishedDistributions('clinical_imaging').map(row=>row.raw_value)")),['Yes']);
  assert.equal(run("domainPublishedDistributions('diagnosis_atlas').length"),0);
  assert.match(run("domainSummaryStatus('diagnosis_atlas')"),/not supplied/);
  assert.ok(copy(run('clinicalSourceReadinessRows()')).every(row=>row.status!=='panel_ready'));
});

test('curated covered panels replace historical pooled source KPIs while retaining dedicated clinical KPIs',()=>{
  const kpis=[{panel_id:'diagnosis_atlas',kpi_id:'mapped_sources',label:'Mapped sources',value:99},{panel_id:'diagnosis_atlas',kpi_id:'source_rows',label:'Source rows',value:9999},{panel_id:'diagnosis_atlas',kpi_id:'diagnosis_events',label:'Published diagnosis events',value:125}];
  const {ctx,run}=fixtureRuntime('stem_collisions_and_exact_registry',{panelKpiRows:kpis,domainPanelRows:[{panel_id:'diagnosis_atlas',panel_title:'Diagnoses'}],panelDistributionRows:[{panel_id:'diagnosis_atlas',distribution_type:'categorical',raw_value:'Confirmed',n:50}]});
  ctx.renderScopeChip=()=>'';ctx.renderInterpretationLead=()=>'';ctx.renderTrustBadgeRow=()=>'';ctx.renderDistributionRows=()=>'';ctx.renderCollapsedRawLineage=()=>'';ctx.rowsForTable=rows=>JSON.stringify(rows);
  for(const name of ['scopeLabel','toneColor','renderBadge','renderKpiStrip','renderSectionCard','renderDomainPanel'])fn(name,ctx);
  const before=JSON.stringify(kpis),panel=run("renderDomainPanel('diagnosis_atlas')");
  const current=panel.split('Historical supplied source KPIs')[0];
  assert.match(current,/Current source identities/);assert.match(current,/>2<\/b>/);
  assert.match(current,/Source records \(not additive\)/);assert.match(current,/Not summed/);
  assert.match(current,/Published diagnosis events/);assert.match(current,/>125<\/b>/);
  assert.doesNotMatch(current,/>99<\/b>|>9,999<\/b>|Mapped sources|Source rows<\/span>/);
  assert.match(panel,/Historical supplied source KPIs/);assert.match(panel,/9999/);
  assert.equal(JSON.stringify(kpis),before);
});

test('source KPI authority changes only covered panels and cannot use malformed inventory',()=>{
  const kpis=[{panel_id:'treatment',kpi_id:'source_rows',label:'Treatment source rows',value:777},{panel_id:'clinical_vitals',kpi_id:'source_rows',label:'Source rows',value:9999}];
  const {ctx,run}=runtime({payload:{clinical_source_inventory:{schema_version:2}},panelKpiRows:kpis});
  ctx.rowsForTable=rows=>JSON.stringify(rows);
  for(const name of ['toneColor','renderKpiStrip'])fn(name,ctx);
  const covered=run("renderDomainKpis('clinical_vitals')"),current=covered.split('Original supplied source KPIs')[0];
  assert.match(current,/Current source identities/);assert.match(current,/not available/);
  assert.doesNotMatch(current,/9,999/);assert.match(covered,/9999/);
  const outside=run("renderDomainKpis('treatment')");
  assert.match(outside,/777/);assert.match(outside,/Treatment source rows/);assert.doesNotMatch(outside,/Not summed|Current source identities/);
});

test('current source KPI tiles cannot displace dedicated clinical KPIs at the existing display cap',()=>{
  const kpis=Array.from({length:12},(_,index)=>({panel_id:'diagnosis_atlas',kpi_id:`clinical_${index + 1}`,label:`Clinical measure ${index + 1}`,value:index + 100}));
  const {ctx,run}=fixtureRuntime('stem_collisions_and_exact_registry',{panelKpiRows:kpis});
  ctx.rowsForTable=rows=>JSON.stringify(rows);
  for(const name of ['toneColor','renderKpiStrip'])fn(name,ctx);
  const display=run("renderDomainKpis('diagnosis_atlas')");
  assert.match(display,/Clinical measure 11/);assert.match(display,/Clinical measure 12/);
  assert.match(display,/>110<\/b>/);assert.match(display,/>111<\/b>/);
});

test('registry routes expose exact metadata sources with companions excluded and malformed limits visible',()=>{
  const {run}=fixtureRuntime('stem_collisions_and_exact_registry');
  const sources=run("renderRegistrySourceInventory('reg_cll')");
  assert.match(sources,/Current registry source identities/);assert.match(sources,/view=timeplace&amp;source=RKKP_CLL/);
  assert.doesNotMatch(sources,/CLL_TREAT|CLLPANEL_WIDE/);
  const malformed=runtime({payload:{clinical_source_inventory:{}}}).run("renderRegistrySourceInventory('reg_cll')");
  assert.match(malformed,/source.inventory limitation/i);assert.doesNotMatch(malformed,/<details/);
  assert.equal(runtime().run("renderRegistrySourceInventory('reg_cll')"),'');
});

function readinessPresentation(runtime){
  const {ctx,run}=runtime;
  const start=html.indexOf('      const clinicalTopicDefinitions ='),end=html.indexOf('      const clinicalTopicRows =',start);
  assert.ok(start>=0&&end>start);vm.runInContext(html.slice(start,end),ctx);
  ctx.rowsForTable=rows=>`<table><tbody><tr><td>${JSON.stringify(rows)}</td></tr></tbody></table>`;
  const before=JSON.stringify({payload:ctx.payload,catalog:ctx.catalogRows,profiles:ctx.columnRows,readiness:ctx.reviewModuleReadiness});
  const rendered=run('renderClinicalModuleReadiness()');
  const primary=rendered.match(/<section[^>]*data-current-readiness[^>]*>([\s\S]*?)<\/section>/)?.[1];
  assert.ok(primary,'Reviewed readiness needs a compact primary region independent of technical metadata');
  assert.equal(JSON.stringify({payload:ctx.payload,catalog:ctx.catalogRows,profiles:ctx.columnRows,readiness:ctx.reviewModuleReadiness}),before);
  return {rendered,primary};
}
function readinessCard(primary,panel){
  const card=[...primary.matchAll(/<article[^>]*data-readiness-topic="([^"]+)"[^>]*>([\s\S]*?)<\/article>/g)].find(match=>match[1]===panel)?.[2];
  assert.ok(card,`Missing topic readiness card: ${panel}`);return card;
}
function readinessFact(card,fact){
  const value=card.match(new RegExp(`<div[^>]*data-readiness-fact="${fact}"[^>]*>[\\s\\S]*?<dd>([\\s\\S]*?)<\\/dd>`))?.[1];
  assert.ok(value!==undefined,`Missing readiness fact: ${fact}`);
  return value.replace(/<[^>]+>/g,' ').replace(/\s+/g,' ').trim();
}

test('reviewed readiness renders twelve human-readable topic cards with one scope note and collapsed machine metadata',()=>{
  const historical=[{module:'Diagnoses and tumors',status:'panel_ready',n_rows:9999,source_count:99}];
  const {rendered,primary}=readinessPresentation(fixtureRuntime('stem_collisions_and_exact_registry',{reviewModuleReadiness:historical}));
  assert.equal((primary.match(/data-readiness-topic=/g)||[]).length,12);
  assert.equal((primary.match(/data-readiness-scope/g)||[]).length,1);
  assert.doesNotMatch(primary,/<table|<th|<td/);
  const text=primary.replace(/<[^>]+>/g,' ');
  assert.doesNotMatch(text,/source_ready|panel_ready|source_status_unknown|imported_snapshot|diagnosis_atlas|clinical_adt|date_min|date_max|n_rows|n_columns|not additive; source state/);
  assert.match(text,/Source records, fields and dates are not additive/);
  assert.match(text,/do not establish eligible clinical summaries/);
  assert.match(readinessCard(primary,'diagnosis_atlas'),/<h5>Diagnoses<\/h5>/);
  assert.match(readinessCard(primary,'clinical_adt'),/<h5>Admissions and hospital contacts<\/h5>/);
  const technical=rendered.match(/<details[^>]*data-readiness-technical[^>]*>([\s\S]*?)<\/details>/);
  assert.ok(technical,'Full derived readiness stays accessible behind a technical disclosure');
  assert.doesNotMatch(technical[0].split('>')[0],/\bopen\b/);
  assert.match(technical[1],/"status":"source_ready"/);assert.match(technical[1],/"n_rows":null/);
  assert.match(technical[1],/"n_columns":null/);assert.match(technical[1],/"date_min":""/);assert.match(technical[1],/"date_max":""/);
  assert.match(technical[1],/"evidence_origin":"imported_snapshot"/);assert.match(technical[1],/"inventory_scope":"present"/);
  assert.match(rendered,/Historical supplied readiness metadata/);assert.match(rendered,/9999/);
});

test('readiness topic actions use established clinical and registry destinations',()=>{
  const {primary}=readinessPresentation(fixtureRuntime('stem_collisions_and_exact_registry'));
  for(const [panel,tab,sub] of [['diagnosis_atlas','clinical','clinical-diagnoses'],['clinical_adt','clinical','clinical-admissions'],['clinical_notes','clinical','clinical-notes'],['clinical_microbiology','laboratory','lab-microbiology'],['clinical_imaging','laboratory','lab-imaging'],['clinical_pathology','laboratory','lab-pathology'],['clinical_biobank','laboratory','lab-biobank'],['clinical_vitals','clinical','clinical-vitals'],['clinical_social_history','clinical','clinical-social'],['reg_damyda','registries','reg-damyda'],['reg_lyfo','registries','reg-lyfo'],['reg_cll','registries','reg-cll']]){
    const card=readinessCard(primary,panel);
    assert.match(card,new RegExp(`data-jump-tab="${tab}"`));assert.match(card,new RegExp(`data-jump-sub="${sub}"`));
    assert.ok(html.includes(`id="${sub}"`),`Route must name an existing pane: ${sub}`);
  }
});

test('compact readiness keeps distinct identity, load and profile facts without converting null to zero',()=>{
  const cases=[
    ['both_alias_identities_with_unequal_profiles','clinical_biobank','2','2 loaded 0 not loaded or not tested 0 unknown','1 source identity'],
    ['duplicate_identity_and_conflicting_lineage','clinical_biobank','1','0 loaded 0 not loaded or not tested 1 unknown','0 source identities'],
    ['current_load_states_zero_null_and_legacy_absence','clinical_vitals','1','0 loaded 1 not loaded or not tested 0 unknown','0 source identities'],
    ['current_load_states_zero_null_and_legacy_absence','clinical_social_history','1','0 loaded 0 not loaded or not tested 1 unknown','0 source identities'],
    ['empty_present_inventory','diagnosis_atlas','0','0 loaded 0 not loaded or not tested 0 unknown','0 source identities'],
    ['missing_inventory','diagnosis_atlas','Not established','Not established','Not established'],
    ['limited_inventory','reg_cll','1','1 loaded 0 not loaded or not tested 0 unknown','0 source identities']
  ];
  for(const [sample,panel,identities,load,profiles] of cases){
    const {primary}=readinessPresentation(fixtureRuntime(sample));
    const card=readinessCard(primary,panel);
    assert.equal(readinessFact(card,'identities'),identities,sample);
    assert.equal(readinessFact(card,'load'),load,sample);
    assert.equal(readinessFact(card,'profiles'),profiles,sample);
    if(sample==='missing_inventory')assert.match(primary,/Source-inventory limitation/);
    if(sample==='limited_inventory')assert.match(primary,/may be incomplete/);
  }
  const {primary}=readinessPresentation(runtime({payload:{clinical_source_inventory:{schema_version:2}}}));
  assert.equal(readinessFact(readinessCard(primary,'diagnosis_atlas'),'identities'),'Not established');
  assert.match(primary,/Source-inventory limitation/);assert.doesNotMatch(primary,/\b0 loaded\b/);
});
