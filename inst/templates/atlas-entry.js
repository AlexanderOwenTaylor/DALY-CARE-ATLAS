(function (window,document) {
  'use strict';
  const routes={
    overview:['overview-summary','overview-briefing','overview-coverage','overview-temporal','overview-spatial','overview-qa'],
    variables:['variables-concepts','variables-lineage','variables-distributions','variables-panels'],
    situation:['situation-headlines','situation-breakdowns','situation-freshness','situation-definitions'],
    quickstart:['quickstart-recipes','quickstart-rstudio','quickstart-terminal','quickstart-preflight'],
    dictionary:['dictionary-lineage','dictionary-values','dictionary-codes','dictionary-panels'],
    'clinical-feasibility':['mcl-triangle-feasibility'], registries:['reg-overview','reg-damyda','reg-lyfo','reg-cll','reg-inventory'],
    clinical:['clinical-diagnoses','clinical-admissions','clinical-imaging','clinical-microbiology','clinical-pathology','clinical-vitals','clinical-notes','clinical-social'],
    treatment:[], laboratory:['lab-npu','lab-detective','lab-imaging','lab-microbiology','lab-pathology','lab-isotype','lab-biobank','lab-sources'],
    ehr:['ehr-sp','ehr-sds','ehr-views'], infrastructure:['infra-actions','infra-catalog','infra-columns','infra-resolution','infra-memory','infra-panels','infra-qa']
  };
  function destination(hash) {
    const [fragment,query='']=String(hash||'').replace(/^#/,'').split('?');
    if (!fragment) return null;
    const [tab,sub,...rest]=fragment.split('/');
    if (rest.length || !Object.prototype.hasOwnProperty.call(routes,tab) || (sub && !routes[tab].includes(sub))) return 'DALYCARE_atlas.html?route=unknown';
    if (tab==='infrastructure' && sub==='infra-panels') {
      const params=new URLSearchParams(query), out=new URLSearchParams();
      const q=params.has('g')?params.get('g'):params.get('q');
      if(q) out.set('q',q);
      if(params.get('group')) out.set('group',params.get('group')); // Library validates against its catalogue.
      return 'DALYCARE_outputs.html'+(out.size?'?'+out:'');
    }
    return 'DALYCARE_clinical.html'+hash;
  }
  window.DALYCARE_ROUTES={destination};
  if (!/DALYCARE_atlas\.html$/i.test(window.location.pathname||'')) return;
  const target=destination(window.location.hash);
  if(target) {window.location.replace(target);return;}
  const status=document.getElementById('entry-status');
  if(!status) return;
  const entry=window.DALYCARE_ENTRY;
  if(!entry || entry.schema_version!==1 || !entry.build_id) {status.textContent='Run details could not be loaded. Keep all atlas files together and reopen Home.';status.setAttribute('role','alert');if(document.documentElement)document.documentElement.dataset.atlasReady='entry-error';}
  else {
    const provenance=entry.provenance==='csv_outputs'?'From CSV outputs':entry.provenance==='legacy_payload'?'From an earlier atlas export':'Aggregate atlas export';
    status.textContent=provenance+' · Run '+(entry.run_id||'not supplied');
    if(document.documentElement)document.documentElement.dataset.atlasReady='entry';
  }
  if(new URLSearchParams(window.location.search).get('route')==='unknown') status.textContent+=' · That saved link is not recognized. Choose a question below.';
  document.querySelectorAll('[data-clinical-link]').forEach(link=>link.addEventListener('click',()=>{status.textContent='Opening Clinical explorer… Larger exports can take a moment to load.';}));
})(window,document);
