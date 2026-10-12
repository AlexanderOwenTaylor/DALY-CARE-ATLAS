/* Curated reference terminology, not observed patient values or a dataset inventory.
 * Descriptor keys correspond to vital_descriptor_definition() in R/semantic_dictionary.R.
 * Unit references: LOINC 8480-6, 8462-4, 59408-5 and 8310-5.
 * Never derive per-measurement statistics from the pooled numericvalue profile.
 */
(function(window){
  'use strict';
  const definitions=[
    {id:'blood-pressure',title:'Blood pressure',unit:'mmHg',aliases:['BP','blood pressure','systolic','diastolic','blodtryk','BT systolisk','BT diastolisk','BT'],
      meaning:'Systolic is the upper pressure; diastolic is the lower pressure. Analyse these as two separate measurements.',
      terms:'BT systolisk → systolic blood pressure; BT diastolisk → diastolic blood pressure.',
      references:[['Systolic blood pressure','8480-6'],['Diastolic blood pressure','8462-4']]},
    {id:'oxygen-saturation',title:'SpO₂ — oxygen saturation',unit:'%',aliases:['SpO2','SpO₂','oxygen saturation','saturation','iltmætning','iltmaetning','oxygen saturation by pulse oximetry'],
      meaning:'Peripheral oxygen saturation, usually measured with a pulse oximeter. SpO₂ is not the same measurement as oxygen pressure in a blood gas.',
      terms:'SpO2 or saturation → oxygen saturation. The measurement method must be checked in the source.',
      references:[['Oxygen saturation by pulse oximetry','59408-5']]},
    {id:'temperature',title:'Temperature',unit:'°C',aliases:['temperature','body temperature','temp','temperatur','kropstemperatur'],
      meaning:'Body temperature. Check the measurement site and method before combining readings.',
      terms:'Temp → body temperature.',references:[['Body temperature','8310-5']]}
  ];
  const key=value=>String(value||'').normalize('NFKD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/æ/g,'ae').replace(/ø/g,'o').replace(/[^a-z0-9]+/g,' ').trim();
  const escape=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  function search(query){
    const q=key(query);if(!q)return [];
    return definitions.filter(row=>row.aliases.some(alias=>key(alias)===q)||q.split(' ').every(word=>key([...row.aliases,row.unit].join(' ')).split(' ').includes(word)));
  }
  function fieldLink(field,label){return '<a href="DALYCARE_outputs.html?'+escape(new URLSearchParams({view:'fields',table:'column_profiles',source:'SP_VitaleVaerdier',field}).toString())+'">'+label+' <code>'+field+'</code> →</a>';}
  function render(query){
    const selected=new Set(search(query).map(row=>row.id));
    return '<section class="vital-guide" aria-label="Vital sign measurement guide"><h3>Find a vital sign</h3><p>Where to look: <strong>Vital signs (SP)</strong> · <code>SP_VitaleVaerdier</code></p><div class="vital-guide-grid">'+definitions.map(row=>
      '<details id="vital-'+row.id+'"'+(selected.has(row.id)?' open':'')+'><summary><span class="vital-guide-title">'+row.title+'</span><span class="vital-guide-unit">Usual unit: '+row.unit+'</span><span class="vital-guide-prompt">Meaning and reference names</span></summary><div class="vital-guide-explanation"><p>'+row.meaning+'</p><p><strong>Atlas terminology:</strong> '+row.terms+'</p><p class="vital-guide-small">These are reference mappings, not a list of values observed in this export.</p><p class="vital-guide-small">Unit reference: '+row.references.map(([label,code])=>'<a href="https://loinc.org/'+code+'/">'+label+'</a>').join(' · ')+'</p></div></details>'
    ).join('')+'</div><p class="vital-guide-small">These are usual units, not verified stored units for DALY-CARE. Confirm the stored unit before analysing values.</p><div class="vital-guide-summary"><strong>Dataset summaries</strong><p>No measurement-specific counts, medians or IQRs are available in this guide. The published field profiles combine vital-sign types; their totals cannot be used as counts for blood pressure, SpO₂ or temperature.</p></div><details class="vital-guide-fields"><summary>Where are the names, values and dates stored?</summary><p>A vital sign is identified by its measurement name, with its reading and recording time stored in separate columns.</p><div class="vital-guide-links">'+fieldLink('displayname','Measurement name')+fieldLink('numericvalue','Numeric reading')+fieldLink('recorded_time','Recording time')+'</div><p class="vital-guide-small">These links open privacy-protected field summaries, not individual records. Measurement names may be withheld; that does not mean the measurements are absent.</p></details></section>';
  }
  window.DALYCARE_VITALS=Object.freeze({search,render});
})(window);
