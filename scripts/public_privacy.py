"""Final public-export disclosure guard. Counts describe source rows, not people."""
import copy
import csv
import math
import os
import re
from pathlib import Path
from registry_summary_privacy import sanitize_registry_summaries, audit_registry_summaries

VERSION = '2026-10-11-public-privacy-1'
STATS = {'min', 'max', 'mean', 'median', 'p25', 'p75', 'sd', 'q25', 'q75', 'iqr'}
DATES = {'min_date','max_date','raw_min_date','raw_max_date','display_min_date','display_max_date','date_min','date_max','date_range','display_min_year','display_max_year','as_of_date','lag_days'}
VALUES = {'value','label','top_value','mode','sample','samples','example','examples','snippet','raw_value','category','category_value','breakdown_value','display_value','raw_code','raw_descriptor','statistic_value'}
REFERENCE = {'npu_display_dictionary','clinical_display_dictionary'}
PROTECTED = re.compile(r'(^id$|(^|_)id($|_)|id$|^dw_ek_|identifier|uuid|guid|accession|requisition|record|recnum|contact|cpr|pnr|patient|person|name|address|email|phone|report|text|comment|postcode|municip|organisation|organization|location|drug|medication)',re.I)

def number(value):
    if value is None or isinstance(value,bool): return None
    try:
        n=float(value)
        return n if math.isfinite(n) else None
    except (ValueError,TypeError): return None

def threshold(value):
    n=number(value)
    return max(5, math.ceil(n)) if n is not None else 5

def measurement_policy(root=None):
    root=Path(root) if root else Path(__file__).resolve().parents[1]
    with (root/'config/public-measurement-policy.csv').open(encoding='utf-8-sig',newline='') as f:
        return {(r['table_name'],r['column_name']) for r in csv.DictReader(f)}

def sanitize_public_payload(payload, min_cell_count=5, project_root=None):
    archived=[threshold(r.get('value')) for r in payload.get('run_summary',[]) if isinstance(r,dict) and r.get('metric')=='min_cell_count']
    k=max(threshold(min_cell_count),threshold(payload.get('privacy_metadata',{}).get('minimum_cell_count')),threshold(os.environ.get('DALYCARE_MIN_CELL_COUNT','5')),*archived)
    registry_k=k
    approved=measurement_policy(project_root)
    # Canonical profile provenance is required for panel copies missing min/distinct.
    profiles={(str(r.get('table_name','')),str(r.get('column_name',''))):r for r in payload.get('column_profile_rows',[]) if isinstance(r,dict)}
    year_paths = {('panels','atlas_temporal_coverage_years'), ('review_temporal_coverage','years')}
    has_ranges = any(isinstance(r,dict) and r.get('coverage_basis') == 'source_date_range'
                     for rows in (payload.get('panels',{}).get('atlas_temporal_coverage_years',[]), payload.get('review_temporal_coverage',{}).get('years',[])) for r in rows)
    def walk(obj, path=()):
        if path and path[-1]=='registry_field_summaries':
            return sanitize_registry_summaries(obj,project_root,registry_k)
        if isinstance(obj,list):
            if path in year_paths:
                normalized=[]; seen=set()
                for row in obj:
                    if isinstance(row,dict) and row.get('coverage_basis') == 'source_date_range':
                        identity=tuple(row.get(key) for key in ('table_name','date_column','coverage_basis'))
                        if identity in seen: continue
                        seen.add(identity)
                        row={key:row.get(key) for key in ('table_name','domain','subdomain','atlas_role','date_column','coverage_basis') if key in row}
                        row.update(year=None,n_rows=None,pct_rows=None,date_privacy_status='withheld_derived_source_range')
                    normalized.append(row)
                obj=normalized
            structural_panel_path=(path in {('panel_groups',),('review_overview','panel_groups')} or bool(path and path[-1]=='panels' and path[0].startswith('review_')))
            if structural_panel_path and all(isinstance(x,dict) and set(x)=={'group','panel_name','title','n_rows'} for x in obj):
                out=copy.deepcopy(obj)
                if has_ranges:
                    for row in out:
                        if row.get('panel_name') == 'atlas_temporal_coverage_years': row['n_rows']=None
                return out  # Inventory sizes must not restore inferred range length.
            out=[walk(x,path) for x in obj]
            if any(isinstance(x,dict) and any(number(x.get(key)) is not None and 0<number(x.get(key))<k for key in ('n','n_rows','n_observed','n_patients','count','frequency','choropleth_value','damyda_n','matched_rows','matched_patients')) for x in obj):
                for row in out:
                    if isinstance(row,dict):
                        for key in row:
                            if key in {'n','n_rows','n_observed','n_patients','count','frequency','choropleth_value','damyda_n','matched_rows','matched_patients','pct'} or key.startswith('pct_'): row[key]=None
                        row['count_privacy_status']='withheld_residual_small_distribution'
            return out
        if not isinstance(obj,dict):
            if isinstance(obj,str) and path and path[-1] in {'message','note','story','date_qc','description'}:
                return re.sub(r'\b\d{4}-\d{2}-\d{2}\b','[clinical date withheld]',obj)
            return copy.deepcopy(obj)
        if has_ranges and path == ('review_temporal_coverage','summary') and 'n_year_rows' in obj:
            obj=dict(obj,n_year_rows=None)
        r={key:(copy.deepcopy(v) if key in REFERENCE else walk(v,path+(key,))) for key,v in obj.items()}
        for key in DATES & r.keys(): r[key]=None
        if DATES & r.keys(): r['date_privacy_status']='withheld_exact_clinical_bounds'
        field=str(r.get('column_name',r.get('source_column',r.get('date_column',r.get('raw_column','')))) or '')
        table=str(r.get('table_name',r.get('registry','')) or '')
        profile=('profile_kind' in r or 'column_name' in r and 'n_available' in r)
        if any(number(obj.get(key)) is not None and 0<number(obj.get(key))<k for key in ('n_available','n_missing')):
            for key in {'n_available','n_missing','pct_available','pct_missing'} & r.keys(): r[key]=None
            r['availability_privacy_status']='withheld_small_complementary_cells'
        provenance=profiles.get((table,field),{})
        if provenance.get('availability_privacy_status')=='withheld_small_complementary_cells' or any(number(provenance.get(key)) is not None and 0<number(provenance.get(key))<k for key in ('n_available','n_missing')):
            for key in {'n_available','n_missing','pct_available','pct_missing'} & r.keys(): r[key]=None
            r['availability_privacy_status']='withheld_small_complementary_cells'
        protected=bool(field and PROTECTED.search(field)) or str(r.get('is_sensitive','')).lower()=='true' or str(r.get('profile_kind',''))=='sensitive'
        if profile or STATS & r.keys():
            original=profiles.get((table,field),obj)
            support=number(original.get('n_available'))
            missing=number(original.get('n_missing'))
            if (support is not None and 0<support<k) or (missing is not None and 0<missing<k):
                for key in {'n_available','n_missing','pct_available','pct_missing'} & r.keys(): r[key]=None
                r['availability_privacy_status']='withheld_small_complementary_cells'
            reason=None
            distinct=number(original.get('n_distinct_capped'))
            if protected: reason='protected_field'
            elif (table,field) not in approved: reason='needs_validation_unreviewed_field'
            elif r.get('availability_privacy_status')=='withheld_small_complementary_cells': reason='withheld_small_complementary_cells'
            elif support is None: reason='withheld_unknown_support'
            elif support<k: reason='withheld_insufficient_support' if support else 'unavailable_zero_support'
            elif distinct is None: reason='needs_validation_unknown_distinctness'
            elif distinct<=1: reason='withheld_constant_profile'
            elif distinct>=support*0.9: reason='withheld_near_unique_profile'
            elif number(original.get('min')) is None and original.get('numeric_privacy_status')!='eligible_stored_summary': reason='needs_validation_missing_range_evidence'
            elif number(original.get('min')) is not None and number(original.get('min'))<0: reason='needs_validation_negative_sentinel'
            if r.get('numeric_privacy_status') and r['numeric_privacy_status']!='eligible_stored_summary': reason=r['numeric_privacy_status']
            # Exact legacy summaries have no verified unit/group/person evidence.
            for key in STATS & r.keys(): r[key]=None
            r['numeric_privacy_status']=reason or 'needs_verified_grouped_evidence'
            r['summary_scope']='stored_source_row_profile'
            r['summary_method']='supplied_mean_and_quantiles; quantiles_may_use_bounded_stream_sample'
            if protected:
                r['is_sensitive']=True
                r['value_privacy_status']='protected_field'
                for key in VALUES & r.keys(): r[key]=None
            if protected or support is None or support<k or r.get('availability_privacy_status')=='withheld_small_complementary_cells':
                if 'n_distinct_capped' in r: r['n_distinct_capped']=None
        if protected:
            for key in VALUES & r.keys(): r[key]=None
            r['value_privacy_status']='protected_field'
        # Arbitrary observed categories fail closed: no exact categorical policy yet.
        observed=bool(VALUES & r.keys()) and (any(key in r for key in ('n','n_observed','n_patients','n_rows','frequency','count','pct_rows')) or any('top_value' in x or 'value_map' in x or x=='panel_distribution_rows' for x in path))
        code_usage=('code_column' in r and any(key in r for key in ('n','n_rows','n_observed')))
        if observed or code_usage:
            # Named reference metrics/aggregate structural summaries are not categories.
            structural_schemas={'npu_dictionary_summary':{'metric','label','value'},'npu_dictionary_vectors':{'consensus_vector','n_dictionary_codes','systems'},'panel_kpi_rows':{'panel_id','kpi_id','unit','count_scope'},'registry_clinical_summary':{'table_name','registry','n_cols'},'situation_report_summary':{'metric_id','definition_basis','definition_status'},'atlas_spatial_region_coverage':{'region_code','coverage_status','basis'},'atlas_dk_choropleth_regions':{'region_code','svg_path','choropleth_basis'}}
            safe_structural=any(x in path and keys.issubset(r) for x,keys in structural_schemas.items()) and not field
            structural_section=('panel_distribution_rows' in path and r.get('distribution_type')=='clinical_section' and r.get('value_class')=='section' and all(r.get(key) in (None,'') for key in ('n','pct','statistic','statistic_value','raw_column','raw_descriptor','raw_code','raw_value')))
            if not structural_section and any(r.get(key) not in (None,'') for key in ('display_value','raw_code','raw_value','raw_descriptor','statistic_value')): safe_structural=False
            if not (safe_structural or structural_section):
                for key in (VALUES|{'code','npu_code','lab_code','n','n_rows','n_observed','n_patients','frequency','count','pct_rows','pct_patients','pct'}) & r.keys(): r[key]=None
                r['value_privacy_status']='withheld_unvalidated_distribution'
        # Positive small aggregate cells and their percentages cannot remain anywhere.
        count_keys=[key for key in r if key in {'n','n_rows','n_observed','n_patients','matched_rows','matched_patients','n_cohort','damyda_n','choropleth_value'}]
        if any(number(r[key]) is not None and 0<number(r[key])<k for key in count_keys):
            for key in count_keys+[key for key in r if key.startswith('pct_') or key=='pct']: r[key]=None
            r['count_privacy_status']='withheld_small_cells'
        return r
    result=walk(payload)
    result['privacy_metadata']={'policy_version':VERSION,'minimum_cell_count':k,'count_basis':'legacy summaries: source_rows; published registry_field_summaries: distinct people per exact field','categorical_policy':'legacy distributions withheld; registry_field_summaries require complete-field distinct-person validation','summary_scope':'stored_source_row_profile'}
    return result

def audit_public_payload(payload,project_root=None,min_cell_count=5):
    """Independent structural audit; returns only paths, never patient-derived values."""
    errors=[]
    k=effective_threshold(payload,min_cell_count=min_cell_count)
    suppressed={(str(r.get('table_name','')),str(r.get('column_name',''))) for r in payload.get('column_profile_rows',[]) if r.get('availability_privacy_status')=='withheld_small_complementary_cells'}
    def visit(obj,path):
        if path and path[-1]=='registry_field_summaries':
            errors.extend('.'.join(path[:-1]+(reason,)) for reason in audit_registry_summaries(obj,project_root,k))
            return
        if isinstance(obj,list):
            for i,x in enumerate(obj): visit(x,path+(str(i),))
        elif isinstance(obj,dict):
            field=str(obj.get('column_name',obj.get('source_column',obj.get('date_column',''))) or '')
            table=str(obj.get('table_name',obj.get('registry','')) or '')
            if (table,field) in suppressed:
                for key in {'n_available','n_missing','pct_available','pct_missing'} & obj.keys():
                    if obj[key] not in (None,''): errors.append('.'.join(path+(key,)))
            structural_section=(obj.get('distribution_type')=='clinical_section' and obj.get('value_class')=='section' and all(obj.get(key) in (None,'') for key in ('n','pct','statistic','statistic_value','raw_column','raw_descriptor','raw_code','raw_value')))
            for key in {'raw_value','raw_code','raw_descriptor','statistic_value','display_value'} & obj.keys():
                if obj[key] not in (None,'') and not (key=='display_value' and structural_section): errors.append('.'.join(path+(key,)))
            if obj.get('value_privacy_status') in {'protected_field','withheld_unvalidated_distribution'}:
                for key in VALUES & obj.keys():
                    if obj[key] not in (None,''): errors.append('.'.join(path+(key,)))
            for key,v in obj.items():
                if key in REFERENCE: continue
                if key in DATES and v not in (None,''): errors.append('.'.join(path+(key,)))
                if key in STATS and v not in (None,''): errors.append('.'.join(path+(key,)))
                if key in {'min','max'} and v not in (None,''): errors.append('.'.join(path+(key,)))
                visit(v,path+(key,))
    visit(payload,())
    return sorted(set(errors))


def effective_threshold(payload=None, context=None, min_cell_count=5):
    requested = [min_cell_count, os.environ.get('DALYCARE_MIN_CELL_COUNT', '5')]
    values = []
    if payload is not None:
        values.extend(row.get('value') for row in payload.get('run_summary',[]) if isinstance(row,dict) and row.get('metric')=='min_cell_count')
    for obj in (payload, context):
        if obj is not None:
            metadata = obj.get('privacy_metadata', {}) if obj is payload else obj
            if 'minimum_cell_count' in metadata:
                values.append(metadata['minimum_cell_count'])
    thresholds = [5]
    for value,integer in [(v,False) for v in requested]+[(v,True) for v in values]:
        n = number(value)
        if n is None or n < 1 or n > 9007199254740991 or (integer and n != int(n)):
            raise ValueError('Invalid explicit privacy threshold')
        thresholds.append(math.ceil(n))
    return max(thresholds)
