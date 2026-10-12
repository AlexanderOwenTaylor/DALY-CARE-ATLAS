/* Historical reference vocabulary, never observed descriptor values or patient examples.
 * Semantic mappings: R/semantic_dictionary.R vital_descriptor_definition().
 * The pooled SP reading profile must never become a per-measurement summary.
 */
(function(window){
  'use strict';
  const definitions=[
    {id:'pulse',title:'Pulse / heart rate',unit:'beats/min',aliases:['pulse','heart rate','puls'],descriptors:['Puls'],meaning:'',reference:'8867-4'},
    {id:'oxygen-saturation',title:'SpO₂ — oxygen saturation',unit:'%',aliases:['SpO2','SpO₂','SpO2 %','oxygen saturation','saturation','iltmætning','iltmaetning'],descriptors:['SpO2','Saturation'],meaning:'Peripheral oxygen saturation; verify the measurement method.',reference:'59408-5'},
    {id:'respiratory-rate',title:'Respiratory rate',unit:'breaths/min',aliases:['respiratory rate','respiration','resp','resp frekvens','respirationsfrekvens'],descriptors:['Resp','Resp.frekvens'],meaning:'',reference:'9279-1'},
    {id:'blood-pressure',title:'Blood pressure',unit:'mmHg',aliases:['BP','blood pressure','systolic','diastolic','blodtryk','BT systolisk','BT diastolisk','BT'],descriptors:['BT (Diastolisk)','BT (Systolisk)'],meaning:'Diastolic is the lower pressure; systolic is the upper pressure. Keep the two measurements separate.',reference:'8480-6',secondReference:'8462-4'},
    {id:'temperature',title:'Temperature',unit:'°C',aliases:['temperature','body temperature','temp','temperatur','kropstemperatur'],descriptors:['Temp.','Temperatur'],meaning:'Body temperature; verify measurement site and method.',reference:'8310-5'},
    {id:'oxygen-flow',title:'Oxygen flow',unit:'L/min',aliases:['oxygen flow','oxygen flow rate','ilt','ilt l min'],descriptors:['Ilt (l/min.)'],meaning:'Inferred oxygen-flow mapping; verify the source coding.',reference:'3151-8'},
    {id:'weight',title:'Weight',unit:'kg',aliases:['weight','body weight','vægt','vaegt','vagt'],descriptors:['Vægt'],meaning:'',reference:'29463-7'},
    {id:'height',title:'Height',unit:'cm',aliases:['height','body height','højde','hojde'],descriptors:['Højde'],meaning:'',reference:'8302-2'},
    {id:'bmi',title:'BMI',unit:'',aliases:['BMI','body mass index'],descriptors:[],meaning:'Stored BMI is a dedicated field. Deriving BMI from weight and height requires compatible units and a defined pairing of observations.'},
    {id:'ews',title:'Early warning score',unit:'',aliases:['EWS','early warning score','EWS total'],descriptors:['EWS total'],meaning:'Inferred Early Warning Score total; verify the scoring definition.'},
    {id:'consciousness',title:'Consciousness level',unit:'',aliases:['consciousness','consciousness level','bevidsthed','bevidsthedsniveau'],descriptors:['Bevidsthedsniveau'],meaning:'Categorical observation; the coding and allowed categories require verification.'},
    {id:'position',title:'Position',unit:'',aliases:['position','positioning','lejring'],descriptors:['Lejring'],meaning:'Positioning descriptor; its coding and interpretation require verification.'},
    {id:'i-ews-project',title:'I-EWS project score',unit:'',aliases:['I-EWS score','I-EWS score projekt','project score'],descriptors:['I-EWS score (projekt)'],meaning:'Project-specific score; its definition and comparability are unverified.'},
    {id:'i-ews-retired',title:'Retired I-EWS modifier',unit:'',aliases:['I-EWS modifier','I-EWS modifikator'],descriptors:['Udgået - I-EWS modifikator'],meaning:'Historical retired descriptor; its definition and current availability are unverified.'},
    {id:'rover-retired',title:'Retired Rover EWS action',unit:'',aliases:['Rover','EWS action','EWS handling'],descriptors:['Udgået - Rover, EWS-handling'],meaning:'Historical retired workflow descriptor; its definition and current availability are unverified.'}
  ];
  const dedicated=[
    {id:'weight',source:'SP_PatientInfo',field:'weight_in_kg'},
    {id:'height',source:'SP_PatientInfo',field:'height_in_cm'},
    {id:'bmi',source:'SP_PatientInfo',field:'bmi'},
    {id:'weight',source:'RKKP_DaMyDa',field:'Reg_Vaegt'},
    {id:'height',source:'RKKP_DaMyDa',field:'Reg_Hoejde'}
  ];
  const schema=[['displayname','Measurement name'],['numericvalue','Numeric reading'],['recorded_time','Recording time'],['meas_value','Stored value'],['meas_value_clean','Cleaned value field'],['val_type_c','Value-type code']];
  const key=value=>String(value==null?'':value).normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/æ/g,'ae').replace(/ø/g,'o').replace(/[^a-z0-9]+/g,' ').trim();
  const escape=value=>String(value==null?'':value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function search(query){
    const q=key(query);if(!q)return [];
    if(['vital signs','vitals','measurements'].includes(q))return definitions;
    if(['anthropometrics','anthropometry'].includes(q)||q.split(' ').length===3&&['height','weight','bmi'].every(word=>q.split(' ').includes(word)))return definitions.filter(row=>['weight','height','bmi'].includes(row.id));
    const unitAliases={pulse:['pulse bpm','heart rate bpm','pulse beats min'],'blood-pressure':['blood pressure mmhg','bp mmhg'],'respiratory-rate':['respiratory rate breaths min','respiration breaths min'],weight:['weight kg'],height:['height cm'],temperature:['temperature c','temperature degrees c'], 'oxygen-flow':['oxygen flow l min']};
    const names=row=>[row.title,...row.aliases,...row.descriptors,...dedicated.filter(field=>field.id===row.id).flatMap(field=>[field.field,field.source+'.'+field.field])];
    const exact=definitions.filter(row=>names(row).concat(unitAliases[row.id]||[]).some(alias=>key(alias)===q));
    if(exact.length)return exact;
    return definitions.filter(row=>names(row).some(alias=>q.split(' ').every(word=>key(alias).split(' ').includes(word))));
  }
  function fieldLink(source,field,label,found){
    if(!found.row)return (label?escape(label)+' · ':'')+'<code>'+escape(source+'.'+field)+'</code>';
    return '<a href="DALYCARE_outputs.html?'+escape(new URLSearchParams({view:'fields',table:'column_profiles',source,field}).toString())+'">'+(label?escape(label)+' · ':'')+'<code>'+escape(source+'.'+field)+'</code> →</a>';
  }
  function lookup(profiles,source,field){
    const matches=(Array.isArray(profiles)?profiles:[]).filter(row=>row&&row.table_name===source&&row.column_name===field);
    return matches.length===1?{row:matches[0]}:{message:matches.length?'Ambiguous profile: multiple exact matches.':'Profile not supplied; current field availability unverified.'};
  }
  function scalar(value){
    if(typeof value==='string'){if(!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i.test(value.trim()))return null;value=Number(value);}
    return typeof value==='number'&&Number.isFinite(value)?value:null;
  }
  const number=value=>value!==0&&Math.abs(value)<0.001?String(value):value.toLocaleString('en-GB',{maximumFractionDigits:3});
  const blank=value=>value==null||(typeof value==='string'&&!value.trim());
  const publicRow=row=>row.is_sensitive==null||row.is_sensitive===false||row.is_sensitive==='FALSE';
  const availabilityAllowed=row=>publicRow(row)&&blank(row.availability_privacy_status);
  function profileMetadata(found){
    if(!found.row)return '<span class="vital-guide-small">'+found.message+'</span>';
    const row=found.row;
    const storage=typeof row.column_type==='string'&&row.column_type.trim()?row.column_type:typeof row.column_class==='string'&&row.column_class.trim()?row.column_class:null;
    return '<span class="vital-guide-small">'+(storage?'Stored as: '+escape(storage):'Field profile supplied; storage type not supplied')+'</span>';
  }
  function summary(found){
    if(!found.row)return '';
    const row=found.row,parts=[];
    const count=scalar(row.n_available),total=scalar(row.n_rows);
    if(availabilityAllowed(row)&&count!==null&&total!==null&&Number.isSafeInteger(count)&&Number.isSafeInteger(total)&&count>=0&&total>=count)parts.push(number(count)+' of '+number(total)+' source records with a value');
    else parts.push('Availability not published');
    if(publicRow(row)&&availabilityAllowed(row)&&row.numeric_privacy_status==='eligible_stored_summary'){
      const median=scalar(row.median),p25=scalar(row.p25),p75=scalar(row.p75);
      parts.push('Median: '+(median===null?'Not supplied':number(median)));
      parts.push('Middle 50%: '+(p25===null||p75===null||p25>p75?'Not supplied':number(p25)+'–'+number(p75)));
      const mean=scalar(row.mean);if(mean!==null)parts.push('Mean: '+number(mean));
    }else parts.push(row.numeric_privacy_status==='needs_validation_negative_sentinel'?'Numeric summary withheld: invalid stored values need review':'Numeric summary not published');
    return '<div class="vital-guide-statistics">'+parts.map(part=>'<span>'+escape(part)+'</span>').join('')+'</div>';
  }
  function measurement(row,profiles){
    const fields=dedicated.filter(field=>field.id===row.id);
    return '<article class="vital-guide-row" id="vital-'+row.id+'"><div class="vital-guide-definition"><h4>'+escape(row.title)+'</h4>'+(row.meaning?'<p>'+escape(row.meaning)+'</p>':'')+(row.unit?'<span class="vital-guide-unit">Reference unit: '+escape(row.unit)+'</span>':'')+(row.reference?'<span class="vital-guide-small">Unit reference: <a href="https://loinc.org/'+row.reference+'/">LOINC '+row.reference+'</a>'+(row.secondReference?' · <a href="https://loinc.org/'+row.secondReference+'/">LOINC '+row.secondReference+'</a>':'')+'</span>':'')+'</div><div class="vital-guide-evidence">'+(row.descriptors.length?'<p class="vital-guide-small">Historical displayname labels · current presence unverified</p><div class="vital-guide-descriptors">'+row.descriptors.map(name=>'<code>'+escape(name)+'</code>').join(' ')+'</div>':'<span class="vital-guide-small">Dedicated stored field</span>')+fields.map(field=>{const found=lookup(profiles,field.source,field.field);return '<div class="vital-guide-dedicated"><span class="vital-guide-small">'+(field.source==='SP_PatientInfo'?'Patient information (SP)':'Myeloma registry')+'</span>'+fieldLink(field.source,field.field,null,found)+profileMetadata(found)+summary(found)+'</div>';}).join('')+'</div></article>';
  }
  function body(query,options){
    const profiles=options.profiles,rows=key(query)?search(query):definitions;
    const hasDescriptors=rows.some(row=>row.descriptors.length),hasDedicated=rows.some(row=>dedicated.some(field=>field.id===row.id));
    const eventSummaryNote=options.eventSummariesAvailable===true?'Separately published per-measurement SP summaries appear below; this directory does not summarize pooled numericvalue.':'No measurement-specific counts, medians or IQRs are supplied to this directory; numericvalue pools measurement types.';
    const schemaFields=fields=>fields.map(([field,label])=>{const found=lookup(profiles,'SP_VitaleVaerdier',field);return '<div>'+fieldLink('SP_VitaleVaerdier',field,label,found)+profileMetadata(found)+'</div>';}).join('');
    const secondaryIds=['ews','i-ews-project','i-ews-retired','rover-retired'];
    const mainRows=rows.filter(row=>!secondaryIds.includes(row.id)),secondaryRows=rows.filter(row=>secondaryIds.includes(row.id));
    const directory=mainRows.map(row=>measurement(row,profiles)).join('')+(secondaryRows.length?'<h4 class="vital-guide-group-heading">Scores and retired reference labels</h4>'+secondaryRows.map(row=>measurement(row,profiles)).join(''):'');
    return '<h3>Measurement directory</h3>'+
      '<form data-vital-search class="vital-guide-search"><label>Find a measurement<input data-vital-query name="measurement" type="search" value="'+escape(query)+'" placeholder="Pulse, respiration, weight, BMI…"></label><button type="submit">Find measurement</button><button type="button" data-vital-reset>Show all measurements</button></form>'+
      (hasDescriptors?'<div class="vital-guide-schema"><strong>Vital signs (SP) · SP_VitaleVaerdier</strong><p>One row is an observation. Different measurements share the reading column; there is not one column per measurement.</p><div class="vital-guide-links">'+schemaFields(schema.slice(0,3))+'</div><details class="vital-guide-other-fields"><summary>Other value columns</summary><div class="vital-guide-links">'+schemaFields(schema.slice(3))+'</div></details></div>':'')+
      (hasDescriptors?'<p class="vital-guide-small">Historical names: V33 atlas (DALYCARE_atlas_AOT_V33.html); current descriptor availability is unverified, and this is not an exhaustive current inventory. Reference units only; stored units are unverified. '+eventSummaryNote+'</p>':'')+
      '<h4 class="vital-guide-vocabulary">Measurements and source fields</h4><div class="vital-guide-directory">'+(rows.length?directory:'<p role="status">No measurements match this search.</p>')+'</div>'+
      (hasDedicated?'<p class="vital-guide-small">Source-specific summaries are not harmonized across sources. They describe stored source records, not unique people; published quartiles may use a bounded sample. Source fields alone do not establish a per-measurement date or baseline window. BMI is stored; deriving BMI requires paired weight and height observations.</p>':'');
  }
  const contexts=new Map();let nextContext=0;
  function render(query,options={}){
    const context=String(++nextContext);contexts.set(context,options);if(contexts.size>80)contexts.delete(contexts.keys().next().value);
    return '<section class="vital-guide" data-vital-directory="'+context+'" aria-label="Vital signs and anthropometric measurement directory">'+body(query==null?'':String(query),options)+'</section>';
  }
  function refine(root,query){
    const options=contexts.get(root.getAttribute('data-vital-directory'))||{};
    root.innerHTML=body(query,options);
    const input=root.querySelector('[data-vital-query]');if(input){input.focus();if(input.setSelectionRange)input.setSelectionRange(query.length,query.length);}
    if(typeof options.onQueryChange==='function')options.onQueryChange(query);
  }
  if(typeof document!=='undefined'&&document.addEventListener){
    document.addEventListener('submit',event=>{
      const form=event.target.closest&&event.target.closest('[data-vital-search]');if(!form)return;
      const root=form.closest('[data-vital-directory]');if(!root)return;
      event.preventDefault();refine(root,form.querySelector('[data-vital-query]').value);
    });
    document.addEventListener('click',event=>{
      const reset=event.target.closest&&event.target.closest('[data-vital-reset]');if(!reset)return;
      const root=reset.closest('[data-vital-directory]');if(!root)return;
      event.preventDefault();refine(root,'');
    });
  }
  window.DALYCARE_VITALS=Object.freeze({search,render});
})(window);
