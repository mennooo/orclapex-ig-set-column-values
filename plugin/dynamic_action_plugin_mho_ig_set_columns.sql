prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- ORACLE Application Express (APEX) export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_180100 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_api.import_begin (
 p_version_yyyy_mm_dd=>'2018.04.04'
,p_release=>'18.1.0.00.43'
,p_default_workspace_id=>10390063953384733491
,p_default_application_id=>115922
,p_default_owner=>'CITIEST'
);
end;
/
prompt --application/shared_components/plugins/dynamic_action/mho_ig_set_columns
begin
wwv_flow_api.create_plugin(
 p_id=>wwv_flow_api.id(120337869700178430659)
,p_plugin_type=>'DYNAMIC ACTION'
,p_name=>'MHO.IG_SET_COLUMNS'
,p_display_name=>'IG - Set column value'
,p_category=>'EXECUTE'
,p_supported_ui_types=>'DESKTOP'
,p_javascript_file_urls=>'#PLUGIN_FILES#IGSetColumnValues#MIN#.js'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'type column_t is record (',
'  name         varchar2(4000)',
', value        clob',
', data_type    varchar2(30)',
', format_mask  varchar2(4000)',
', is_readonly  boolean',
', is_affected  boolean',
', static_id    varchar2(4000)',
');',
'',
'type columns_t is table of column_t index by pls_integer;',
'',
'type record_t is record (',
'  column_binds apex_plugin_util.t_bind_list',
', column_list  columns_t',
');',
'',
'type record_tt is table of record_t index by pls_integer;',
'',
'type column_values_tt is table of clob index by varchar2(4000);',
'',
'g_records record_tt;',
'',
'function get_region_columns (',
' p_region_id number',
') return varchar2',
'is',
'',
'  l_columns varchar2(32000);',
'',
'begin',
'',
'  select listagg(name, '','') within group (order by display_sequence) cols',
'    into l_columns',
'    from apex_appl_page_ig_columns',
'   where region_id = p_region_id;',
'   ',
'  return l_columns;',
'',
'end get_region_columns;',
'',
'function get_affected_columns (',
' p_action_id number',
') return varchar2',
'is',
'',
'  l_columns varchar2(32000);',
'',
'begin',
'',
'  select affected_elements into l_columns',
'    from apex_application_page_da_acts',
'   where action_id = p_action_id;',
'   ',
'  return l_columns;',
'',
'end get_affected_columns;',
'',
'procedure json_to_records (',
'  p_values         apex_json.t_values',
', p_column_binds   apex_t_varchar2',
') is',
'',
'  l_column       column_t;',
'  l_record       record_t;',
'  l_column_bind  apex_plugin_util.t_bind;',
'  l_column_binds apex_plugin_util.t_bind_list;',
'  ',
'  l_bind_idx      number;',
'  l_value_count   number;',
'',
'begin',
'',
'  g_records.delete;',
'',
'  for rec_idx in 1..apex_json.get_count(p_path=>''.'', p_values=> p_values) loop',
'  ',
'    l_column_binds.delete;',
'    ',
'    for col_idx in 1..apex_json.get_count(p_path=>''[%d]'', p0 => rec_idx, p_values=> p_values) loop',
'',
'      l_column.name := apex_json.get_varchar2(p_path=>''[%d][%d].name'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column.data_type := apex_json.get_varchar2(p_path=>''[%d][%d].dataType'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column.format_mask := apex_json.get_varchar2(p_path=>''[%d][%d].formatMask'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column.is_readonly := apex_json.get_boolean(p_path=>''[%d][%d].isReadOnly'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column.is_affected := apex_json.get_boolean(p_path=>''[%d][%d].isAffected'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column.static_id := apex_json.get_varchar2(p_path=>''[%d][%d].staticId'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'      l_column_bind.name := l_column.name;',
'      begin',
'        l_column.value := apex_json.get_varchar2(p_path=>''[%d][%d].value'', p0 => rec_idx, p1 => col_idx, p_values=> p_values);',
'          apex_debug.message(''Bind value for '' || l_column.name || '' is '' || l_column.value);',
'      exception',
'        when value_error then',
'          apex_debug.message(''No value for '' || l_column.name);',
'          l_column.value := '''';',
'      end;',
'      ',
'      l_record.column_list(col_idx) := l_column;',
'      ',
'      -- Add the column value as bind variable if needed',
'      l_bind_idx := p_column_binds.first();',
'      while l_bind_idx is not null loop',
'        if p_column_binds(l_bind_idx) = l_column.name then',
'          l_column_bind.value := l_column.value;',
'          apex_debug.message(''Adding bind variable for '' || l_column.name || '' with value '' || l_column_bind.value);',
'          l_record.column_binds(l_record.column_binds.count + 1) := l_column_bind;',
'        end if;',
'        l_bind_idx := p_column_binds.next(l_bind_idx);',
'      end loop;',
'      ',
'    end loop;',
'    ',
'    g_records(rec_idx) := l_record;',
'  ',
'  end loop;',
'',
'end json_to_records;',
'',
'procedure print_json(',
'  p_values             apex_json.t_values',
', p_type               varchar2',
', p_sql_statement      varchar2',
', p_function_body      varchar2',
', p_plsql_expression   varchar2',
', p_escape_chars       varchar2',
', p_columns            apex_t_varchar2',
') is',
'',
'  l_value clob;',
'  l_is_affected boolean;',
'  l_column column_t;',
'  l_column_value_list apex_plugin_util.t_column_value_list2;',
'  l_column_values column_values_tt;',
'  l_column_idx number;',
'',
'begin',
'',
'  apex_json.open_array; -- array of rows',
'',
'  for rec_idx in 1..g_records.count loop',
'  ',
'    -- For select statements, we only need to execute it once per row',
'    if p_type = ''sql'' then',
'    ',
'      l_column_value_list :=',
'          apex_plugin_util.get_data2 (',
'              p_sql_statement    => p_sql_statement,',
'              p_min_columns      => 1,',
'              p_max_columns      => 100,',
'              p_component_name   => '''', -- Only for regions and items, this is a DA plugin',
'              p_bind_list        => g_records(rec_idx).column_binds',
'          );',
'',
'      -- Get the value per column',
'      for col_idx in 1..l_column_value_list.count loop',
'      ',
'        l_column_values.delete(p_columns(col_idx));',
'        ',
'        apex_debug.message(''Getting value for '' || p_columns(col_idx));',
'',
'        for val_idx in 1..l_column_value_list(col_idx).value_list.count loop',
'',
'          -- Make sure CLOB values can be retrieved (I see no need for other datatypes like BLOB because it''s strange in an IG?)',
'          if l_column_value_list(col_idx).data_type = apex_plugin_util.c_data_type_clob then',
'',
'            l_value := l_column_value_list(col_idx).value_list(val_idx).clob_value;',
'',
'          else',
'',
'            l_value := apex_plugin_util.get_value_as_varchar2 (',
'              p_data_type => l_column_value_list(col_idx).data_type',
'            , p_value => l_column_value_list(col_idx).value_list(val_idx)',
'            );',
'',
'          end if;',
'',
'          -- Concatenate values for all rows into one big clob value',
'          if l_column_values.exists(p_columns(col_idx)) then',
'            l_column_values(p_columns(col_idx)) := l_column_values(p_columns(col_idx)) || '':'' || l_value;',
'          else',
'            l_column_values(p_columns(col_idx)) := l_value;',
'          end if;',
'        ',
'          apex_debug.message(''value '' || l_value);',
'',
'        end loop;',
'',
'      end loop;',
'    ',
'    end if;',
'    ',
'    apex_json.open_array; -- array of columns',
'    ',
'    for col_idx in 1..g_records(rec_idx).column_list.count loop',
'      ',
'      apex_json.open_object; -- column',
'      ',
'      l_column := g_records(rec_idx).column_list(col_idx);',
'      ',
'      apex_json.write(''name'', l_column.name);',
'      apex_json.write(''dataType'', l_column.data_type);',
'      apex_json.write(''isReadOnly'', l_column.is_readonly);',
'      apex_json.write(''isAffected'', l_column.is_affected);',
'      apex_json.write(''staticId'', l_column.static_id);',
'      ',
'      l_value := l_column.value;',
'',
'      -- Only update values of affected columns',
'      if l_column.is_affected then',
'',
'        case p_type',
'',
'          when ''plsql'' then ',
'            l_value := apex_plugin_util.get_plsql_expression_result (',
'              p_plsql_expression => p_plsql_expression',
'            , p_bind_list => g_records(rec_idx).column_binds',
'            );',
'',
'          when ''function'' then ',
'            l_value := apex_plugin_util.get_plsql_function_result (',
'              p_plsql_function => p_function_body',
'            , p_bind_list => g_records(rec_idx).column_binds',
'            );',
'',
'          when ''sql'' then ',
'            l_value := l_column_values(l_column.name);',
'',
'        end case;      ',
'',
'      end if;',
'      ',
'      if p_escape_chars = ''Y'' then',
'      ',
'        -- escaping cannot deal with CLOBs so substring it',
'        l_value := apex_escape.html(dbms_lob.substr(l_value, 32767));',
'      ',
'      end if;',
'',
'      apex_json.write(''value'', l_value, true);',
'      ',
'      apex_json.close_object;',
'      ',
'    end loop;',
'    ',
'    apex_json.close_array;',
'  ',
'  end loop;',
'    ',
'  apex_json.close_array;',
'',
'end print_json;',
'',
'function render(',
'  p_dynamic_action in apex_plugin.t_dynamic_action',
', p_plugin         in apex_plugin.t_plugin) return apex_plugin.t_dynamic_action_render_result',
'is',
'  l_js            varchar2(4000);',
'  l_result        apex_plugin.t_dynamic_action_render_result;',
'  l_region_id     varchar2(100);',
'  l_js_columns    varchar2(32000);',
'begin',
'  ',
'  if p_dynamic_action.attribute_01 = ''js'' then',
'    l_js_columns := get_region_columns(p_dynamic_action.triggering_region_id);',
'  end if;',
'',
'  l_js := ''function () {',
'    mho.IGSetColumnValues.setValue({',
'      da: this,',
'      ajaxIdentifier: "#AJAX_IDENTIFIER#",',
'      type: "#TYPE#",',
'      staticValue: "#STATIC_VALUE#",',
'      jsColumns: "#JS_COLUMNS#",',
'      jsExpression: function (#JS_COLUMNS#) { return #JS_EXPRESSION# },',
'      dialogReturnItem: "#DIALOG_RETURN_ITEM#",',
'      itemsToSubmit: "#ITEMS_TO_SUBMIT#",',
'      recordSelection: "#RECORD_SELECTION#",',
'      affectedColumns: "#AFFECTED_COLUMNS#"',
'    })',
'  }'';',
'  ',
'  l_js := replace(l_js,''#AJAX_IDENTIFIER#'',apex_plugin.get_ajax_identifier);',
'  l_js := replace(l_js,''#TYPE#'',p_dynamic_action.attribute_01);',
'  l_js := replace(l_js,''#STATIC_VALUE#'',p_dynamic_action.attribute_04);',
'  l_js := replace(l_js,''#JS_COLUMNS#'',l_js_columns);',
'  l_js := replace(l_js,''#JS_EXPRESSION#'',p_dynamic_action.attribute_02);',
'  l_js := replace(l_js,''#DIALOG_RETURN_ITEM#'',p_dynamic_action.attribute_07);',
'  l_js := replace(l_js,''#ITEMS_TO_SUBMIT#'',apex_plugin_util.page_item_names_to_jquery(p_dynamic_action.attribute_08));',
'  l_js := replace(l_js,''#RECORD_SELECTION#'',p_dynamic_action.attribute_10);',
'  l_js := replace(l_js,''#AFFECTED_COLUMNS#'',get_affected_columns(p_dynamic_action.id));',
'',
'  l_result.javascript_function := l_js;',
'',
'  return l_result;',
'',
'end render;',
'',
'------------------------------------------------------------------------------',
'-- function ajax',
'------------------------------------------------------------------------------',
'function ajax (',
'  p_dynamic_action in apex_plugin.t_dynamic_action',
', p_plugin         in apex_plugin.t_plugin',
') return apex_plugin.t_dynamic_action_ajax_result',
'is',
'',
'  l_clob   clob;',
'  l_values apex_json.t_values;',
'  l_result apex_plugin.t_dynamic_action_ajax_result;',
'',
'begin',
'',
'  apex_json.parse(p_values=> l_values, p_source => apex_application.g_clob_01);',
'  ',
'  json_to_records(',
'    p_values       => l_values',
'  , p_column_binds => apex_string.split(p_dynamic_action.attribute_11, '','')',
'  );',
'  ',
'  print_json(',
'    p_values             => l_values',
'  , p_type               => apex_application.g_x01',
'  , p_sql_statement      => p_dynamic_action.attribute_05',
'  , p_function_body      => p_dynamic_action.attribute_06',
'  , p_plsql_expression   => p_dynamic_action.attribute_03',
'  , p_escape_chars       => p_dynamic_action.attribute_09',
'  , p_columns            => apex_string.split(get_affected_columns(p_dynamic_action.id), '','')',
'  );',
'',
'  return l_result;',
'',
'end ajax;'))
,p_api_version=>2
,p_render_function=>'render'
,p_ajax_function=>'ajax'
,p_standard_attributes=>'ITEM:REQUIRED:WAIT_FOR_RESULT'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
,p_about_url=>'www.menn.ooo'
,p_files_version=>155
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60169655498554410596)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Set Type'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'js'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
,p_help_text=>'<p>Select how to derive the value(s) to set.</p>'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60170495051440198325)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>10
,p_display_value=>'Static Assignment'
,p_return_value=>'static'
,p_help_text=>'Set a single static value.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60169980144137415392)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>20
,p_display_value=>'JavaScript Expression'
,p_return_value=>'js'
,p_help_text=>'Set one or more values, derived or calculated from JavaScript.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60173465036837382110)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>30
,p_display_value=>'SQL Statement'
,p_return_value=>'sql'
,p_help_text=>'Set one or more values, based on the result of a SQL query.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60173682260685384691)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>40
,p_display_value=>'PL/SQL Function Body'
,p_return_value=>'function'
,p_help_text=>'Set a single value, based on the result of a PL/SQL function body.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60173865315131388472)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>50
,p_display_value=>'Dialog Return Item'
,p_return_value=>'dialog'
,p_help_text=>'Set a single value, based on the return item of a dialog. Note: This type only works if the dynamic action fires for the <strong>Dialog Closed</strong> event.'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60169989944405417459)
,p_plugin_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_display_sequence=>60
,p_display_value=>'PL/SQL Expression'
,p_return_value=>'plsql'
,p_help_text=>'Set a single value, based on the result of a PL/SQL expression.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60170640007146209961)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'JavaScript Expression'
,p_attribute_type=>'JAVASCRIPT'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'js'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Basic expressions',
'<pre>ENAME.toUpperCase()</pre>',
'<br/>',
'Calculations (increase salary based on page item)',
'<pre>Number(SAL) + (Number(SAL) * (Number(apex.item(''P12_SAL_RAISE_PERC'').getValue())/100))</pre>',
'<br/>',
'For multiselect items (shuttle, checkbox)',
'<pre>[''foo'', ''bar'']</pre>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Enter a JavaScript expression used to set the value. This expression can either result in a single value, or an array of values (where the item being set supports multiple values, for example a Shuttle).',
'<p>',
'You can use the column names in the expression. The column names are <strong>case sensitive</strong> and must be in capitals.',
'</p>',
'<p>',
'<i>Note: every column value is a string in JavaScript and conversion to other datatypes can be tricky due to format masks. If you want to do calculations, do the conversion manually.</i>',
'</p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(2132883148554231356)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'PL/SQL Expression'
,p_attribute_type=>'PLSQL EXPRESSION'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'plsql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>:SAL +  ((:SAL / 100) * :P12_SAL_RAISE_PERC);<pre>',
'<p>In this example, enter <code>P1_SAL_RAISE_PERC</code> in <strong>Page Items to Submit</strong> and <code>SAL</code> in <strong>Columns to use as bind variable</strong>.</p>',
'<pre>''1:2''</pre>',
'<p>This example is useful for multivalue columns.</p>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Enter a PL/SQL expression used to set the value.',
'',
'You can reference page or application items, providing you include them in <strong>Page Items to Submit</strong>.',
'',
'Use the column names as bind variables too.'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60171019895048444242)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Value'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'static'
,p_examples=>'10'
,p_help_text=>'Enter a static value.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60176180725817475993)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'SQL Statement'
,p_attribute_type=>'SQL'
,p_is_required=>true
,p_sql_min_column_count=>1
,p_sql_max_column_count=>100
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'sql'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre><em>',
'select loc,',
'       dname',
'  from dept ',
' where deptno = :P1_DEPTNO',
'</em></pre><em>',
'<p>In this example, enter <code>P1_DEPTNO</code> in <strong>Page Items to Submit</strong>. You should also select two <em>Affected Elements</em>, for the <code>loc</code> and <code>dname</code> columns respectively, for example LOC and DNAME.</p>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<p>Enter a SQL statement that returns between 1 and 100 columns. The columns you select with the SQL statement needs to correspond, by position, to the Page Items you select in <strong>Affected Elements</strong>.</p>',
'<p>You can reference page or application items using bind syntax, providing you include them in <strong>Page Items to Submit</strong></p>',
'<p><em>Note: If the SQL statement returns only a single row, this is set as the values. If it returns multiple row, the value set is a comma separated string of all the rows, for each value.</em></p>'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60177218701278723969)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'PL/SQL Function Body'
,p_attribute_type=>'PLSQL FUNCTION BODY'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'function'
,p_examples=>wwv_flow_string.join(wwv_flow_t_varchar2(
'<pre>return :SAL +  ((:SAL / 100) * :P12_SAL_RAISE_PERC);',
'</pre>',
'<p>In this example, enter <code>P1_SAL_RAISE_PERC</code> in <strong>Page Items to Submit</strong> and <code>SAL</code> in <strong>Columns to use as bind variable</strong>.</p>'))
,p_help_text=>wwv_flow_string.join(wwv_flow_t_varchar2(
'Enter a PL/SQL function body used to set the value.',
'',
'You can reference page or application items, providing you do include them in <strong>Page Items to Submit</strong>.'))
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60177274277482732208)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>7
,p_display_sequence=>70
,p_prompt=>'Dialog Return Item'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>true
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'EQUALS'
,p_depending_on_expression=>'dialog'
,p_help_text=>'Enter the name of a page item returned by the dialog used to set the value.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60178402218572753318)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>8
,p_display_sequence=>80
,p_prompt=>'Items to Submit'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'plsql,sql,function'
,p_help_text=>'Enter page or application items to submit when executing this action. For multiple items, separate each item name with a comma. You can type in the name or pick from the list of available items. If you pick from the list and there is already text ent'
||'ered then a comma is placed at the end of the existing text, followed by the item name returned from the list.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60178413004502535938)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>9
,p_display_sequence=>90
,p_prompt=>'Escape Special Characters'
,p_attribute_type=>'CHECKBOX'
,p_is_required=>false
,p_default_value=>'Y'
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'plsql,sql,function'
,p_help_text=>'Specify whether HTML special characters are escaped. Oracle strongly recommends setting this attribute to <strong>Yes</strong>, to prevent Cross-Site Scripting (XSS) attacks.'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60201488903001844860)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>10
,p_display_sequence=>100
,p_prompt=>'Records'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'selected'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60201492406267846961)
,p_plugin_attribute_id=>wwv_flow_api.id(60201488903001844860)
,p_display_sequence=>10
,p_display_value=>'Selected records'
,p_return_value=>'selected'
,p_help_text=>'Only update the selected records'
);
wwv_flow_api.create_plugin_attr_value(
 p_id=>wwv_flow_api.id(60201494890696848543)
,p_plugin_attribute_id=>wwv_flow_api.id(60201488903001844860)
,p_display_sequence=>20
,p_display_value=>'All records'
,p_return_value=>'all'
,p_help_text=>'Update all records'
);
wwv_flow_api.create_plugin_attribute(
 p_id=>wwv_flow_api.id(60477646311164975071)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>11
,p_display_sequence=>75
,p_prompt=>'Columns to use as bind variable'
,p_attribute_type=>'PAGE ITEMS'
,p_is_required=>false
,p_is_translatable=>false
,p_depending_on_attribute_id=>wwv_flow_api.id(60169655498554410596)
,p_depending_on_has_to_exist=>true
,p_depending_on_condition_type=>'IN_LIST'
,p_depending_on_expression=>'plsql,sql,function'
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '2F2A20676C6F62616C20617065782024202A2F0D0A77696E646F772E6D686F203D2077696E646F772E6D686F207C7C207B7D0D0A3B2866756E6374696F6E20286E616D65737061636529207B0D0A202066756E6374696F6E20494755706461746520286F';
wwv_flow_api.g_varchar2_table(2) := '7074696F6E7329207B0D0A20202020746869732E696724203D206F7074696F6E732E6967240D0A20202020746869732E67726964203D206F7074696F6E732E677269640D0A20202020746869732E6D6F64656C203D20746869732E677269642E6D6F6465';
wwv_flow_api.g_varchar2_table(3) := '6C0D0A20202020746869732E6461203D206F7074696F6E732E64610D0A20202020746869732E74797065203D206F7074696F6E732E747970650D0A20202020746869732E616A61784964656E746966696572203D206F7074696F6E732E616A6178496465';
wwv_flow_api.g_varchar2_table(4) := '6E7469666965720D0A20202020746869732E6974656D73546F5375626D6974203D206F7074696F6E732E6974656D73546F5375626D69740D0A20202020746869732E73746174696356616C7565203D206F7074696F6E732E73746174696356616C75650D';
wwv_flow_api.g_varchar2_table(5) := '0A20202020746869732E6A73436F6C756D6E73203D206F7074696F6E732E6A73436F6C756D6E730D0A20202020746869732E6A7345787072657373696F6E203D206F7074696F6E732E6A7345787072657373696F6E0D0A20202020746869732E6469616C';
wwv_flow_api.g_varchar2_table(6) := '6F6752657475726E4974656D203D206F7074696F6E732E6469616C6F6752657475726E4974656D0D0A20202020746869732E7265636F726453656C656374696F6E203D206F7074696F6E732E7265636F726453656C656374696F6E0D0A20202020746869';
wwv_flow_api.g_varchar2_table(7) := '732E636F6C756D6E436F6E666967203D20746869732E6967242E696E7465726163746976654772696428276F7074696F6E272C2027636F6E6669672E636F6C756D6E7327290D0A20202020746869732E6166666563746564436F6C756D6E73203D206F70';
wwv_flow_api.g_varchar2_table(8) := '74696F6E732E6166666563746564436F6C756D6E730D0A0D0A202020202F2A0D0A2020202020205468652064617461206F626A6563742077696C6C20686176652074686973207374727563747572650D0A0D0A202020202020416E206172726179206F66';
wwv_flow_api.g_varchar2_table(9) := '207265636F7264733A0D0A2020202020205B636F6C756D6E312C20636F6C756D6E322C20636F6C756D6E332C202E2E5D0D0A0D0A2020202020204561636820636F6C756D6E20697320616E206F626A6563743A0D0A2020202020207B0D0A202020202020';
wwv_flow_api.g_varchar2_table(10) := '20206E616D650D0A202020202020202076616C75650D0A2020202020202020646174615479706520286462206461746174797065290D0A2020202020202020666F726D61744D61736B2028746F20636173742074686520636F6C756D6E20746F20697473';
wwv_flow_api.g_varchar2_table(11) := '206F726967696E616C2064617461547970652C206F6E6C7920666F722053514C20616E6420504C53514C290D0A20202020202020206973526561644F6E6C792028726561646F6E6C7920636F6C756D6E732063616E27742062652075706461746564290D';
wwv_flow_api.g_varchar2_table(12) := '0A2020202020202020697341666665637465642028636F6C756D6E2069732070617274206F6620746865206166666563746564436F6C756D6E73290D0A2020202020207D0D0A0D0A202020202A2F0D0A0D0A202020202F2F20546865726520617265206D';
wwv_flow_api.g_varchar2_table(13) := '756C7469706C65207761797320746F20676574207468652076616C75650D0A20202020746869732E7570646174654D6574686F6473203D207B0D0A2020202020207374617469633A20746869732E7570646174655769746853746174696356616C75652C';
wwv_flow_api.g_varchar2_table(14) := '0D0A2020202020206A733A20746869732E757064617465576974684A61766153637269707445787072657373696F6E56616C7565732C0D0A20202020202073716C3A20746869732E616A617843616C6C6261636B2C0D0A202020202020706C73716C3A20';
wwv_flow_api.g_varchar2_table(15) := '746869732E616A617843616C6C6261636B2C0D0A20202020202066756E6374696F6E3A20746869732E616A617843616C6C6261636B2C0D0A2020202020206469616C6F673A20746869732E757064617465576974684469616C6F6752657475726E497465';
wwv_flow_api.g_varchar2_table(16) := '6D730D0A202020207D0D0A0D0A20202020746869732E7365745265636F72647328290D0A20202020746869732E64617461203D20746869732E67657443757272656E744461746128290D0A202020202F2F20746869732E66696C7465724A73436F6C756D';
wwv_flow_api.g_varchar2_table(17) := '6E7328290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E66696C7465724A73436F6C756D6E73203D2066756E6374696F6E202829207B0D0A202020206C65742073656C66203D20746869730D0A20202020746869732E6A7343';
wwv_flow_api.g_varchar2_table(18) := '6F6C756D6E73203D20746869732E6A73436F6C756D6E732E66696C7465722866756E6374696F6E2028636F6C756D6E4E616D6529207B0D0A2020202020206C657420636F6C756D6E203D2073656C662E636F6C756D6E436F6E6669672E66696C74657228';
wwv_flow_api.g_varchar2_table(19) := '66756E6374696F6E2028636F6C756D6E29207B0D0A202020202020202072657475726E20636F6C756D6E2E6E616D65203D3D3D20636F6C756D6E4E616D650D0A2020202020207D295B305D0D0A20202020202072657475726E2028636F6C756D6E290D0A';
wwv_flow_api.g_varchar2_table(20) := '202020207D290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E7365745265636F726473203D2066756E6374696F6E202829207B0D0A202020206C65742073656C66203D20746869730D0A202020202F2F205468657265206172';
wwv_flow_api.g_varchar2_table(21) := '65206D756C7469706C65207761797320746F206765742074686520636F7272656374207265636F7264730D0A202020206C6574207265636F726453656C656374696F6E73203D207B0D0A20202020202073656C65637465643A2066756E6374696F6E2028';
wwv_flow_api.g_varchar2_table(22) := '29207B0D0A202020202020202072657475726E2073656C662E6967242E696E74657261637469766547726964282767657453656C65637465645265636F72647327290D0A2020202020207D2C0D0A202020202020616C6C3A2066756E6374696F6E202869';
wwv_flow_api.g_varchar2_table(23) := '672429207B0D0A20202020202020206C6574207265636F726473203D205B5D0D0A202020202020202073656C662E6D6F64656C2E666F72456163682866756E6374696F6E20287265636F726429207B0D0A202020202020202020207265636F7264732E70';
wwv_flow_api.g_varchar2_table(24) := '757368287265636F7264290D0A20202020202020207D290D0A202020202020202072657475726E207265636F7264730D0A2020202020207D0D0A202020207D0D0A20202020746869732E7265636F726473203D207265636F726453656C656374696F6E73';
wwv_flow_api.g_varchar2_table(25) := '5B746869732E7265636F726453656C656374696F6E5D2E6170706C792874686973290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E67657456616C756573203D2066756E6374696F6E202829207B0D0A202020207265747572';
wwv_flow_api.g_varchar2_table(26) := '6E20746869732E7570646174654D6574686F64735B746869732E747970655D2E6170706C792874686973290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E73657456616C756573203D2066756E6374696F6E202829207B0D0A';
wwv_flow_api.g_varchar2_table(27) := '202020206C65742073656C66203D20746869730D0A202020206C657420666F637573203D20747275650D0A0D0A2020202066756E6374696F6E2076616C546F537472696E67202876616C29207B0D0A2020202020206C657420737472696E6756616C0D0A';
wwv_flow_api.g_varchar2_table(28) := '20202020202069662028747970656F662076616C203D3D3D20276E756D6265722729207B0D0A2020202020202020737472696E6756616C203D2076616C2E746F537472696E6728290D0A2020202020207D20656C7365206966202876616C203D3D3D206E';
wwv_flow_api.g_varchar2_table(29) := '756C6C29207B0D0A2020202020202020737472696E6756616C203D2027270D0A2020202020207D20656C7365207B0D0A2020202020202020737472696E6756616C203D2076616C0D0A2020202020207D0D0A20202020202072657475726E20737472696E';
wwv_flow_api.g_varchar2_table(30) := '6756616C0D0A202020207D0D0A0D0A202020202F2F2053657420746865207265636F72642076616C75657320666F722065616368207265636F726420696E2074686520757064617465642064617461206F626A6563740D0A2020202073656C662E726563';
wwv_flow_api.g_varchar2_table(31) := '6F7264732E666F72456163682866756E6374696F6E20287265636F72642C2069647829207B0D0A2020202020202F2F2045617369657220746F207570646174652076696120636F6C756D6E4974656D732C20627574206F6E6C79206F6E6520726F772063';
wwv_flow_api.g_varchar2_table(32) := '616E2062652061637469766520616E642065646974696E67206D757374206265207475726E6564206F6E0D0A20202020202073656C662E6967242E696E74657261637469766547726964282773657453656C65637465645265636F726473272C20726563';
wwv_flow_api.g_varchar2_table(33) := '6F72642C20666F637573290D0A2020202020202F2F20536C696768746C792066617374657220746F206E6F7420666F63757320666F72207468652072657374206F6620746865207265636F7264730D0A202020202020666F637573203D2066616C73650D';
wwv_flow_api.g_varchar2_table(34) := '0A20202020202073656C662E677269642E736574456469744D6F64652874727565290D0A20202020202073656C662E646174615B6964785D2E666F72456163682866756E6374696F6E2028636F6C756D6E29207B0D0A202020202020202069662028636F';
wwv_flow_api.g_varchar2_table(35) := '6C756D6E2E6973416666656374656429207B0D0A202020202020202020202F2F206966207468652076616C756520697320616E2061727261792C206D616B65207375726520656163682076616C7565206973206120737472696E670D0A20202020202020';
wwv_flow_api.g_varchar2_table(36) := '2020206966202841727261792E6973417272617928636F6C756D6E2E76616C75652929207B0D0A202020202020202020202020636F6C756D6E2E76616C7565203D20636F6C756D6E2E76616C75652E6D61702876616C546F537472696E67290D0A202020';
wwv_flow_api.g_varchar2_table(37) := '202020202020207D0D0A202020202020202020202F2F2053657420636F6C756D6E4974656D2076616C75650D0A20202020202020202020617065782E6974656D28636F6C756D6E2E7374617469634964292E73657456616C756528636F6C756D6E2E7661';
wwv_flow_api.g_varchar2_table(38) := '6C7565290D0A20202020202020207D0D0A2020202020207D290D0A202020207D290D0A202020200D0A202020202F2F205265736574207468652073656C656374656420726F777320616E64207475726E2065646974696E67206F66660D0A202020207365';
wwv_flow_api.g_varchar2_table(39) := '6C662E6967242E696E74657261637469766547726964282773657453656C65637465645265636F726473272C2073656C662E7265636F726473290D0A2020202073656C662E677269642E736574456469744D6F64652866616C7365290D0A0D0A20202020';
wwv_flow_api.g_varchar2_table(40) := '2F2F20466F72206173796E632063616C6C6261636B732C207765206E65656420746F20726573756D652074686520616374696F6E0D0A20202020617065782E64612E726573756D652873656C662E64612E726573756D6543616C6C6261636B2C2066616C';
wwv_flow_api.g_varchar2_table(41) := '7365290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E67657443757272656E7444617461203D2066756E6374696F6E202829207B0D0A202020206C65742073656C66203D20746869730D0A202020206C65742076616C75650D';
wwv_flow_api.g_varchar2_table(42) := '0A2020202072657475726E20746869732E7265636F7264732E6D61702866756E6374696F6E20287265636F726429207B0D0A20202020202072657475726E2073656C662E636F6C756D6E436F6E6669672E6D61702866756E6374696F6E2028636F6C756D';
wwv_flow_api.g_varchar2_table(43) := '6E29207B0D0A202020202020202076616C7565203D2073656C662E6D6F64656C2E67657456616C7565287265636F72642C20636F6C756D6E2E6E616D65290D0A20202020202020202F2F20576520646F6E2774206E65656420746F206861766520746865';
wwv_flow_api.g_varchar2_table(44) := '2076616C7565206173206F626A6563742C206A75737420617320737472696E670D0A20202020202020206966202876616C75652026262076616C75652E7629207B0D0A202020202020202020206966202841727261792E697341727261792876616C7565';
wwv_flow_api.g_varchar2_table(45) := '2E762929207B0D0A20202020202020202020202076616C7565203D2076616C75652E762E6A6F696E28273A27290D0A202020202020202020207D0D0A2020202020202020202076616C7565203D2076616C75652E760D0A20202020202020207D0D0A2020';
wwv_flow_api.g_varchar2_table(46) := '20202020202076616C7565203D2076616C7565207C7C2027270D0A202020202020202072657475726E207B0D0A202020202020202020206E616D653A20636F6C756D6E2E6E616D652C0D0A2020202020202020202076616C75653A2076616C75652C0D0A';
wwv_flow_api.g_varchar2_table(47) := '2020202020202020202064617461547970653A20636F6C756D6E2E64617461547970652C0D0A20202020202020202020666F726D61744D61736B3A20636F6C756D6E2E617070656172616E63652E666F726D61744D61736B2C0D0A202020202020202020';
wwv_flow_api.g_varchar2_table(48) := '206973526561644F6E6C793A20636F6C756D6E2E6973526561644F6E6C792C0D0A20202020202020202020697341666665637465643A202873656C662E6166666563746564436F6C756D6E732E696E6465784F6628636F6C756D6E2E6E616D6529203E20';
wwv_flow_api.g_varchar2_table(49) := '2D31292C0D0A2020202020202020202073746174696349643A20636F6C756D6E2E73746174696349640D0A20202020202020207D0D0A2020202020207D290D0A202020207D290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E';
wwv_flow_api.g_varchar2_table(50) := '616A617843616C6C6261636B203D2066756E6374696F6E202829207B0D0A202020206C65742073656C66203D20746869730D0A202020206C6574206465666572726564203D20242E446566657272656428290D0A20202020617065782E7365727665722E';
wwv_flow_api.g_varchar2_table(51) := '706C7567696E28746869732E616A61784964656E7469666965722C207B0D0A2020202020207830313A20746869732E747970652C0D0A202020202020705F636C6F625F30313A204A534F4E2E737472696E6769667928746869732E64617461292C0D0A20';
wwv_flow_api.g_varchar2_table(52) := '2020202020706167654974656D733A20746869732E6974656D73546F5375626D69740D0A202020207D2C207B0D0A2020202020206C6F6164696E67496E64696361746F723A20746869732E6967242C0D0A2020202020206C6F6164696E67496E64696361';
wwv_flow_api.g_varchar2_table(53) := '746F72506F736974696F6E3A202763656E7465726564270D0A202020207D290D0A2020202020202E7468656E2866756E6374696F6E20286461746129207B0D0A202020202020202073656C662E64617461203D20646174610D0A20202020202020206465';
wwv_flow_api.g_varchar2_table(54) := '6665727265642E7265736F6C766528290D0A2020202020207D290D0A0D0A2020202072657475726E2064656665727265642E70726F6D69736528290D0A20207D0D0A0D0A202049475570646174652E70726F746F747970652E7570646174655769746853';
wwv_flow_api.g_varchar2_table(55) := '746174696356616C7565203D2066756E6374696F6E202829207B0D0A202020202F2F20466F722073657474696E672061207374617469632076616C7565207765206F6E6C79206E656564207468652063757272656E74206461746120616E642075706461';
wwv_flow_api.g_varchar2_table(56) := '74652069740D0A202020206C65742073656C66203D20746869730D0A202020206C6574206465666572726564203D20242E446566657272656428290D0A0D0A20202020746869732E64617461203D20746869732E646174612E6D61702866756E6374696F';
wwv_flow_api.g_varchar2_table(57) := '6E20287265636F726429207B0D0A20202020202072657475726E207265636F72642E6D61702866756E6374696F6E2028636F6C756D6E29207B0D0A202020202020202069662028636F6C756D6E2E6973416666656374656429207B0D0A20202020202020';
wwv_flow_api.g_varchar2_table(58) := '202020636F6C756D6E2E76616C7565203D2073656C662E73746174696356616C75650D0A20202020202020207D0D0A202020202020202072657475726E20636F6C756D6E0D0A2020202020207D290D0A202020207D290D0A0D0A202020202F2F20526574';
wwv_flow_api.g_varchar2_table(59) := '75726E207265636F72644461746120696E2070726F6D6973650D0A2020202064656665727265642E7265736F6C766528290D0A2020202072657475726E2064656665727265642E70726F6D69736528290D0A20207D0D0A0D0A202049475570646174652E';
wwv_flow_api.g_varchar2_table(60) := '70726F746F747970652E757064617465576974684A61766153637269707445787072657373696F6E56616C756573203D2066756E6374696F6E202829207B0D0A202020206C65742073656C66203D20746869730D0A202020206C65742064656665727265';
wwv_flow_api.g_varchar2_table(61) := '64203D20242E446566657272656428290D0A202020206C657420636F6C756D6E56616C756573203D205B5D0D0A202020206C65742076616C75650D0A0D0A20202020746869732E64617461203D20746869732E646174612E6D61702866756E6374696F6E';
wwv_flow_api.g_varchar2_table(62) := '20287265636F726429207B0D0A202020202020636F6C756D6E56616C756573203D205B5D0D0A0D0A2020202020202F2F204765742063757272656E742076616C75652070657220636F6C756D6E0D0A202020202020636F6C756D6E56616C756573203D20';
wwv_flow_api.g_varchar2_table(63) := '73656C662E6A73436F6C756D6E732E6D61702866756E6374696F6E2028636F6C756D6E4E616D6529207B0D0A20202020202020206C657420636F6C756D6E203D207265636F72642E66696C7465722866756E6374696F6E2028636F6C756D6E29207B0D0A';
wwv_flow_api.g_varchar2_table(64) := '2020202020202020202072657475726E20636F6C756D6E2E6E616D65203D3D3D20636F6C756D6E4E616D650D0A20202020202020207D295B305D0D0A202020202020202072657475726E2028636F6C756D6E29203F20636F6C756D6E2E76616C7565203A';
wwv_flow_api.g_varchar2_table(65) := '2027270D0A2020202020207D290D0A0D0A2020202020202F2F204368616E67652076616C756520666F72206561636820636F6C756D6E0D0A20202020202072657475726E207265636F72642E6D61702866756E6374696F6E2028636F6C756D6E29207B0D';
wwv_flow_api.g_varchar2_table(66) := '0A202020202020202069662028636F6C756D6E2E6973416666656374656429207B0D0A2020202020202020202076616C7565203D2073656C662E6A7345787072657373696F6E2E6170706C79286E756C6C2C20636F6C756D6E56616C756573290D0A2020';
wwv_flow_api.g_varchar2_table(67) := '20202020202020202F2F2069662076616C756520697320616E2061727261790D0A20202020202020202020636F6C756D6E2E76616C7565203D2076616C75650D0A20202020202020207D0D0A202020202020202072657475726E20636F6C756D6E0D0A20';
wwv_flow_api.g_varchar2_table(68) := '20202020207D290D0A202020207D290D0A0D0A202020202F2F2052657475726E2070726F6D6973650D0A2020202064656665727265642E7265736F6C766528290D0A2020202072657475726E2064656665727265642E70726F6D69736528290D0A20207D';
wwv_flow_api.g_varchar2_table(69) := '0D0A0D0A202049475570646174652E70726F746F747970652E757064617465576974684469616C6F6752657475726E4974656D73203D2066756E6374696F6E202829207B0D0A20202020636F6E736F6C652E6C6F6728746869732E64612E64617461290D';
wwv_flow_api.g_varchar2_table(70) := '0A0D0A202020202F2F20476574206469616C6F672072657475726E206974656D2076616C75650D0A20202020746869732E73746174696356616C7565203D20746869732E64612E646174615B746869732E6469616C6F6752657475726E4974656D5D0D0A';
wwv_flow_api.g_varchar2_table(71) := '2020202072657475726E20746869732E7570646174655769746853746174696356616C756528290D0A20207D0D0A0D0A20202F2A2A0D0A2020202A20526567696F6E2077696467657473206D6179206E6F74206578697374206F6E2070616765206C6F61';
wwv_flow_api.g_varchar2_table(72) := '642E0D0A2020202A20536F2077652077696C6C2063726561746520612070726F6D69736520616E642072657475726E207468652077696467657420656C656D656E74206F6E206372656174696F6E0D0A2020202A0D0A2020202A2040706172616D207B73';
wwv_flow_api.g_varchar2_table(73) := '7472696E677D20726567696F6E49640D0A2020202A204072657475726E73206A51756572792073656C6563746F72206F66207769646765740D0A2020202A2F0D0A202066756E6374696F6E205F6765745769646765742028726567696F6E496429207B0D';
wwv_flow_api.g_varchar2_table(74) := '0A202020206C657420726567696F6E203D20617065782E726567696F6E28726567696F6E4964290D0A202020206C6574206465666572726564203D20242E446566657272656428290D0A202020206966202821726567696F6E29207B0D0A202020202020';
wwv_flow_api.g_varchar2_table(75) := '64656665727265642E72656A656374284572726F7228274E6F20696E746572616374697665206772696420726567696F6E2077617320666F756E642E204D616B652073757265207468652074726967676572696E6720656C656D656E7420697320616E20';
wwv_flow_api.g_varchar2_table(76) := '496E74657261637469766520477269642729290D0A202020207D20656C7365207B0D0A2020202020206C657420696724203D20726567696F6E2E77696467657428290D0A20200D0A202020202020696620286967242E6C656E677468203E203029207B0D';
wwv_flow_api.g_varchar2_table(77) := '0A202020202020202064656665727265642E7265736F6C766528696724290D0A2020202020207D20656C7365207B0D0A2020202020202020726567696F6E2E656C656D656E742E6F6E2827696E74657261637469766567726964637265617465272C2066';
wwv_flow_api.g_varchar2_table(78) := '756E6374696F6E202829207B0D0A2020202020202020202064656665727265642E7265736F6C766528726567696F6E2E7769646765742829290D0A20202020202020207D290D0A2020202020207D0D0A202020207D0D0A0D0A2020202072657475726E20';
wwv_flow_api.g_varchar2_table(79) := '64656665727265642E70726F6D69736528290D0A20207D0D0A0D0A20202F2A2A0D0A2020202A204F6E2070616765206C6F61642C2073656C65637420726F77206261736564206F6E20706B2070616765206974656D0D0A2020202A0D0A2020202A204F6E';
wwv_flow_api.g_varchar2_table(80) := '6C7920776F726B7320666F722073696E676C6520726F772073656C656374696F6E20626563617573652050616765204974656D732063616E2068617665206F6E6C79206F6E652076616C75650D0A2020202A0D0A2020202A2040706172616D207B616E79';
wwv_flow_api.g_varchar2_table(81) := '7D206F7074696F6E7320696E7075742066726F6D204150455820706C7567696E0D0A2020202A202064613A202020202064796E616D696320616374696F6E0D0A2020202A2020706B4974656D3A205072696D617279206B657920636F6C756D6E206E616D';
wwv_flow_api.g_varchar2_table(82) := '65732028706F736974696F6E206D7573742062652073616D65206173207072696D617279206B657920636F6C756D6E206F7264657220666F7220737572726F6761746520504B73290D0A2020202A2F0D0A202066756E6374696F6E2073657456616C7565';
wwv_flow_api.g_varchar2_table(83) := '20286F7074696F6E7329207B0D0A202020206C65742070726F6D697365203D205F6765745769646765742824286F7074696F6E732E64612E74726967676572696E67456C656D656E74292E61747472282769642729290D0A2020202070726F6D6973652E';
wwv_flow_api.g_varchar2_table(84) := '646F6E652866756E6374696F6E202869672429207B0D0A2020202020206F7074696F6E732E696724203D206967240D0A2020202020206C6574206772696456696577203D206967242E696E74657261637469766547726964282767657456696577732729';
wwv_flow_api.g_varchar2_table(85) := '2E677269640D0A0D0A2020202020202F2F2043616E2774207365742076616C75657320696620746865206772696456696577206973206E6F742070726573656E740D0A2020202020206966202821677269645669657729207B0D0A202020202020202072';
wwv_flow_api.g_varchar2_table(86) := '657475726E0D0A2020202020207D0D0A0D0A2020202020202F2F20476574207265636F72647320616E6420636F6C756D6E7320666F722074686973207570646174650D0A2020202020206C6574206166666563746564436F6C756D6E73203D206F707469';
wwv_flow_api.g_varchar2_table(87) := '6F6E732E6166666563746564436F6C756D6E732E73706C697428272C27290D0A2020202020206C6574206A73436F6C756D6E73203D206F7074696F6E732E6A73436F6C756D6E732E73706C697428272C27290D0A0D0A2020202020202F2F204372656174';
wwv_flow_api.g_varchar2_table(88) := '652061206E657720696E7374616E6365206F6620746865206F626A65637420746F207570646174652074686520677269640D0A2020202020206C657420757064617465203D206E6577204947557064617465287B0D0A20202020202020206967243A2069';
wwv_flow_api.g_varchar2_table(89) := '67242C0D0A2020202020202020677269643A2067726964566965772C0D0A202020202020202064613A206F7074696F6E732E64612C0D0A2020202020202020747970653A206F7074696F6E732E747970652C0D0A2020202020202020616A61784964656E';
wwv_flow_api.g_varchar2_table(90) := '7469666965723A206F7074696F6E732E616A61784964656E7469666965722C0D0A20202020202020206974656D73546F5375626D69743A206F7074696F6E732E6974656D73546F5375626D69742C0D0A202020202020202073746174696356616C75653A';
wwv_flow_api.g_varchar2_table(91) := '206F7074696F6E732E73746174696356616C75652C0D0A20202020202020206A73436F6C756D6E733A206A73436F6C756D6E732C0D0A20202020202020206A7345787072657373696F6E3A206F7074696F6E732E6A7345787072657373696F6E2C0D0A20';
wwv_flow_api.g_varchar2_table(92) := '202020202020206469616C6F6752657475726E4974656D3A206F7074696F6E732E6469616C6F6752657475726E4974656D2C0D0A20202020202020207265636F726453656C656374696F6E3A206F7074696F6E732E7265636F726453656C656374696F6E';
wwv_flow_api.g_varchar2_table(93) := '2C0D0A20202020202020206166666563746564436F6C756D6E733A206166666563746564436F6C756D6E730D0A2020202020207D290D0A0D0A2020202020202F2F2047657420746865206E65772076616C75657320616E64207570646174652074686520';
wwv_flow_api.g_varchar2_table(94) := '677269640D0A2020202020207570646174652E67657456616C75657328290D0A20202020202020202E7468656E2866756E6374696F6E202829207B0D0A202020202020202020207570646174652E73657456616C75657328290D0A20202020202020207D';
wwv_flow_api.g_varchar2_table(95) := '290D0A202020207D290D0A0D0A2020202070726F6D6973652E6661696C2866756E6374696F6E202865727229207B0D0A2020202020207468726F77206572720D0A202020207D290D0A20207D0D0A0D0A20202F2F204164642066756E6374696F6E732074';
wwv_flow_api.g_varchar2_table(96) := '6F206E616D6573706163650D0A20206E616D6573706163652E4947536574436F6C756D6E56616C756573203D207B0D0A2020202073657456616C75653A2073657456616C75650D0A20207D0D0A7D292877696E646F772E6D686F290D0A';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(60201956712306856003)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_file_name=>'IGSetColumnValues.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.g_varchar2_table := wwv_flow_api.empty_varchar2_table;
wwv_flow_api.g_varchar2_table(1) := '77696E646F772E6D686F3D77696E646F772E6D686F7C7C7B7D2C66756E6374696F6E286E616D657370616365297B66756E6374696F6E204947557064617465286F7074696F6E73297B746869732E6967243D6F7074696F6E732E6967242C746869732E67';
wwv_flow_api.g_varchar2_table(2) := '7269643D6F7074696F6E732E677269642C746869732E6D6F64656C3D746869732E677269642E6D6F64656C2C746869732E64613D6F7074696F6E732E64612C746869732E747970653D6F7074696F6E732E747970652C746869732E616A61784964656E74';
wwv_flow_api.g_varchar2_table(3) := '69666965723D6F7074696F6E732E616A61784964656E7469666965722C746869732E6974656D73546F5375626D69743D6F7074696F6E732E6974656D73546F5375626D69742C746869732E73746174696356616C75653D6F7074696F6E732E7374617469';
wwv_flow_api.g_varchar2_table(4) := '6356616C75652C746869732E6A73436F6C756D6E733D6F7074696F6E732E6A73436F6C756D6E732C746869732E6A7345787072657373696F6E3D6F7074696F6E732E6A7345787072657373696F6E2C746869732E6469616C6F6752657475726E4974656D';
wwv_flow_api.g_varchar2_table(5) := '3D6F7074696F6E732E6469616C6F6752657475726E4974656D2C746869732E7265636F726453656C656374696F6E3D6F7074696F6E732E7265636F726453656C656374696F6E2C746869732E636F6C756D6E436F6E6669673D746869732E6967242E696E';
wwv_flow_api.g_varchar2_table(6) := '7465726163746976654772696428226F7074696F6E222C22636F6E6669672E636F6C756D6E7322292C746869732E6166666563746564436F6C756D6E733D6F7074696F6E732E6166666563746564436F6C756D6E732C746869732E7570646174654D6574';
wwv_flow_api.g_varchar2_table(7) := '686F64733D7B7374617469633A746869732E7570646174655769746853746174696356616C75652C6A733A746869732E757064617465576974684A61766153637269707445787072657373696F6E56616C7565732C73716C3A746869732E616A61784361';
wwv_flow_api.g_varchar2_table(8) := '6C6C6261636B2C706C73716C3A746869732E616A617843616C6C6261636B2C66756E6374696F6E3A746869732E616A617843616C6C6261636B2C6469616C6F673A746869732E757064617465576974684469616C6F6752657475726E4974656D737D2C74';
wwv_flow_api.g_varchar2_table(9) := '6869732E7365745265636F72647328292C746869732E646174613D746869732E67657443757272656E744461746128297D66756E6374696F6E205F67657457696467657428726567696F6E4964297B6C657420726567696F6E3D617065782E726567696F';
wwv_flow_api.g_varchar2_table(10) := '6E28726567696F6E4964292C64656665727265643D242E446566657272656428293B696628726567696F6E297B6C6574206967243D726567696F6E2E77696467657428293B6967242E6C656E6774683E303F64656665727265642E7265736F6C76652869';
wwv_flow_api.g_varchar2_table(11) := '6724293A726567696F6E2E656C656D656E742E6F6E2822696E74657261637469766567726964637265617465222C66756E6374696F6E28297B64656665727265642E7265736F6C766528726567696F6E2E7769646765742829297D297D656C7365206465';
wwv_flow_api.g_varchar2_table(12) := '6665727265642E72656A656374284572726F7228224E6F20696E746572616374697665206772696420726567696F6E2077617320666F756E642E204D616B652073757265207468652074726967676572696E6720656C656D656E7420697320616E20496E';
wwv_flow_api.g_varchar2_table(13) := '74657261637469766520477269642229293B72657475726E2064656665727265642E70726F6D69736528297D66756E6374696F6E2073657456616C7565286F7074696F6E73297B6C65742070726F6D6973653D5F6765745769646765742824286F707469';
wwv_flow_api.g_varchar2_table(14) := '6F6E732E64612E74726967676572696E67456C656D656E74292E61747472282269642229293B70726F6D6973652E646F6E652866756E6374696F6E28696724297B6F7074696F6E732E6967243D6967243B6C65742067726964566965773D6967242E696E';
wwv_flow_api.g_varchar2_table(15) := '746572616374697665477269642822676574566965777322292E677269643B6966282167726964566965772972657475726E3B6C6574206166666563746564436F6C756D6E733D6F7074696F6E732E6166666563746564436F6C756D6E732E73706C6974';
wwv_flow_api.g_varchar2_table(16) := '28222C22292C6A73436F6C756D6E733D6F7074696F6E732E6A73436F6C756D6E732E73706C697428222C22292C7570646174653D6E6577204947557064617465287B6967243A6967242C677269643A67726964566965772C64613A6F7074696F6E732E64';
wwv_flow_api.g_varchar2_table(17) := '612C747970653A6F7074696F6E732E747970652C616A61784964656E7469666965723A6F7074696F6E732E616A61784964656E7469666965722C6974656D73546F5375626D69743A6F7074696F6E732E6974656D73546F5375626D69742C737461746963';
wwv_flow_api.g_varchar2_table(18) := '56616C75653A6F7074696F6E732E73746174696356616C75652C6A73436F6C756D6E733A6A73436F6C756D6E732C6A7345787072657373696F6E3A6F7074696F6E732E6A7345787072657373696F6E2C6469616C6F6752657475726E4974656D3A6F7074';
wwv_flow_api.g_varchar2_table(19) := '696F6E732E6469616C6F6752657475726E4974656D2C7265636F726453656C656374696F6E3A6F7074696F6E732E7265636F726453656C656374696F6E2C6166666563746564436F6C756D6E733A6166666563746564436F6C756D6E737D293B75706461';
wwv_flow_api.g_varchar2_table(20) := '74652E67657456616C75657328292E7468656E2866756E6374696F6E28297B7570646174652E73657456616C75657328297D297D292C70726F6D6973652E6661696C2866756E6374696F6E28657272297B7468726F77206572727D297D49475570646174';
wwv_flow_api.g_varchar2_table(21) := '652E70726F746F747970652E66696C7465724A73436F6C756D6E733D66756E6374696F6E28297B6C65742073656C663D746869733B746869732E6A73436F6C756D6E733D746869732E6A73436F6C756D6E732E66696C7465722866756E6374696F6E2863';
wwv_flow_api.g_varchar2_table(22) := '6F6C756D6E4E616D65297B6C657420636F6C756D6E3B72657475726E2073656C662E636F6C756D6E436F6E6669672E66696C7465722866756E6374696F6E28636F6C756D6E297B72657475726E20636F6C756D6E2E6E616D653D3D3D636F6C756D6E4E61';
wwv_flow_api.g_varchar2_table(23) := '6D657D295B305D7D297D2C49475570646174652E70726F746F747970652E7365745265636F7264733D66756E6374696F6E28297B6C65742073656C663D746869732C7265636F726453656C656374696F6E733D7B73656C65637465643A66756E6374696F';
wwv_flow_api.g_varchar2_table(24) := '6E28297B72657475726E2073656C662E6967242E696E74657261637469766547726964282267657453656C65637465645265636F72647322297D2C616C6C3A66756E6374696F6E28696724297B6C6574207265636F7264733D5B5D3B72657475726E2073';
wwv_flow_api.g_varchar2_table(25) := '656C662E6D6F64656C2E666F72456163682866756E6374696F6E287265636F7264297B7265636F7264732E70757368287265636F7264297D292C7265636F7264737D7D3B746869732E7265636F7264733D7265636F726453656C656374696F6E735B7468';
wwv_flow_api.g_varchar2_table(26) := '69732E7265636F726453656C656374696F6E5D2E6170706C792874686973297D2C49475570646174652E70726F746F747970652E67657456616C7565733D66756E6374696F6E28297B72657475726E20746869732E7570646174654D6574686F64735B74';
wwv_flow_api.g_varchar2_table(27) := '6869732E747970655D2E6170706C792874686973297D2C49475570646174652E70726F746F747970652E73657456616C7565733D66756E6374696F6E28297B6C65742073656C663D746869732C666F6375733D21303B66756E6374696F6E2076616C546F';
wwv_flow_api.g_varchar2_table(28) := '537472696E672876616C297B6C657420737472696E6756616C3B72657475726E20737472696E6756616C3D226E756D626572223D3D747970656F662076616C3F76616C2E746F537472696E6728293A6E756C6C3D3D3D76616C3F22223A76616C7D73656C';
wwv_flow_api.g_varchar2_table(29) := '662E7265636F7264732E666F72456163682866756E6374696F6E287265636F72642C696478297B73656C662E6967242E696E74657261637469766547726964282273657453656C65637465645265636F726473222C7265636F72642C666F637573292C66';
wwv_flow_api.g_varchar2_table(30) := '6F6375733D21312C73656C662E677269642E736574456469744D6F6465282130292C73656C662E646174615B6964785D2E666F72456163682866756E6374696F6E28636F6C756D6E297B636F6C756D6E2E6973416666656374656426262841727261792E';
wwv_flow_api.g_varchar2_table(31) := '6973417272617928636F6C756D6E2E76616C756529262628636F6C756D6E2E76616C75653D636F6C756D6E2E76616C75652E6D61702876616C546F537472696E6729292C617065782E6974656D28636F6C756D6E2E7374617469634964292E7365745661';
wwv_flow_api.g_varchar2_table(32) := '6C756528636F6C756D6E2E76616C756529297D297D292C73656C662E6967242E696E74657261637469766547726964282273657453656C65637465645265636F726473222C73656C662E7265636F726473292C73656C662E677269642E73657445646974';
wwv_flow_api.g_varchar2_table(33) := '4D6F6465282131292C617065782E64612E726573756D652873656C662E64612E726573756D6543616C6C6261636B2C2131297D2C49475570646174652E70726F746F747970652E67657443757272656E74446174613D66756E6374696F6E28297B6C6574';
wwv_flow_api.g_varchar2_table(34) := '2073656C663D746869732C76616C75653B72657475726E20746869732E7265636F7264732E6D61702866756E6374696F6E287265636F7264297B72657475726E2073656C662E636F6C756D6E436F6E6669672E6D61702866756E6374696F6E28636F6C75';
wwv_flow_api.g_varchar2_table(35) := '6D6E297B72657475726E2876616C75653D73656C662E6D6F64656C2E67657456616C7565287265636F72642C636F6C756D6E2E6E616D652929262676616C75652E7626262841727261792E697341727261792876616C75652E762926262876616C75653D';
wwv_flow_api.g_varchar2_table(36) := '76616C75652E762E6A6F696E28223A2229292C76616C75653D76616C75652E76292C76616C75653D76616C75657C7C22222C7B6E616D653A636F6C756D6E2E6E616D652C76616C75653A76616C75652C64617461547970653A636F6C756D6E2E64617461';
wwv_flow_api.g_varchar2_table(37) := '547970652C666F726D61744D61736B3A636F6C756D6E2E617070656172616E63652E666F726D61744D61736B2C6973526561644F6E6C793A636F6C756D6E2E6973526561644F6E6C792C697341666665637465643A73656C662E6166666563746564436F';
wwv_flow_api.g_varchar2_table(38) := '6C756D6E732E696E6465784F6628636F6C756D6E2E6E616D65293E2D312C73746174696349643A636F6C756D6E2E73746174696349647D7D297D297D2C49475570646174652E70726F746F747970652E616A617843616C6C6261636B3D66756E6374696F';
wwv_flow_api.g_varchar2_table(39) := '6E28297B6C65742073656C663D746869732C64656665727265643D242E446566657272656428293B72657475726E20617065782E7365727665722E706C7567696E28746869732E616A61784964656E7469666965722C7B7830313A746869732E74797065';
wwv_flow_api.g_varchar2_table(40) := '2C705F636C6F625F30313A4A534F4E2E737472696E6769667928746869732E64617461292C706167654974656D733A746869732E6974656D73546F5375626D69747D2C7B6C6F6164696E67496E64696361746F723A746869732E6967242C6C6F6164696E';
wwv_flow_api.g_varchar2_table(41) := '67496E64696361746F72506F736974696F6E3A2263656E7465726564227D292E7468656E2866756E6374696F6E2864617461297B73656C662E646174613D646174612C64656665727265642E7265736F6C766528297D292C64656665727265642E70726F';
wwv_flow_api.g_varchar2_table(42) := '6D69736528297D2C49475570646174652E70726F746F747970652E7570646174655769746853746174696356616C75653D66756E6374696F6E28297B6C65742073656C663D746869732C64656665727265643D242E446566657272656428293B72657475';
wwv_flow_api.g_varchar2_table(43) := '726E20746869732E646174613D746869732E646174612E6D61702866756E6374696F6E287265636F7264297B72657475726E207265636F72642E6D61702866756E6374696F6E28636F6C756D6E297B72657475726E20636F6C756D6E2E69734166666563';
wwv_flow_api.g_varchar2_table(44) := '746564262628636F6C756D6E2E76616C75653D73656C662E73746174696356616C7565292C636F6C756D6E7D297D292C64656665727265642E7265736F6C766528292C64656665727265642E70726F6D69736528297D2C49475570646174652E70726F74';
wwv_flow_api.g_varchar2_table(45) := '6F747970652E757064617465576974684A61766153637269707445787072657373696F6E56616C7565733D66756E6374696F6E28297B6C65742073656C663D746869732C64656665727265643D242E446566657272656428292C636F6C756D6E56616C75';
wwv_flow_api.g_varchar2_table(46) := '65733D5B5D2C76616C75653B72657475726E20746869732E646174613D746869732E646174612E6D61702866756E6374696F6E287265636F7264297B72657475726E20636F6C756D6E56616C7565733D5B5D2C636F6C756D6E56616C7565733D73656C66';
wwv_flow_api.g_varchar2_table(47) := '2E6A73436F6C756D6E732E6D61702866756E6374696F6E28636F6C756D6E4E616D65297B6C657420636F6C756D6E3D7265636F72642E66696C7465722866756E6374696F6E28636F6C756D6E297B72657475726E20636F6C756D6E2E6E616D653D3D3D63';
wwv_flow_api.g_varchar2_table(48) := '6F6C756D6E4E616D657D295B305D3B72657475726E20636F6C756D6E3F636F6C756D6E2E76616C75653A22227D292C7265636F72642E6D61702866756E6374696F6E28636F6C756D6E297B72657475726E20636F6C756D6E2E6973416666656374656426';
wwv_flow_api.g_varchar2_table(49) := '262876616C75653D73656C662E6A7345787072657373696F6E2E6170706C79286E756C6C2C636F6C756D6E56616C756573292C636F6C756D6E2E76616C75653D76616C7565292C636F6C756D6E7D297D292C64656665727265642E7265736F6C76652829';
wwv_flow_api.g_varchar2_table(50) := '2C64656665727265642E70726F6D69736528297D2C49475570646174652E70726F746F747970652E757064617465576974684469616C6F6752657475726E4974656D733D66756E6374696F6E28297B72657475726E20636F6E736F6C652E6C6F67287468';
wwv_flow_api.g_varchar2_table(51) := '69732E64612E64617461292C746869732E73746174696356616C75653D746869732E64612E646174615B746869732E6469616C6F6752657475726E4974656D5D2C746869732E7570646174655769746853746174696356616C756528297D2C6E616D6573';
wwv_flow_api.g_varchar2_table(52) := '706163652E4947536574436F6C756D6E56616C7565733D7B73657456616C75653A73657456616C75657D7D2877696E646F772E6D686F293B';
null;
end;
/
begin
wwv_flow_api.create_plugin_file(
 p_id=>wwv_flow_api.id(60201957059908856004)
,p_plugin_id=>wwv_flow_api.id(120337869700178430659)
,p_file_name=>'IGSetColumnValues.min.js'
,p_mime_type=>'text/javascript'
,p_file_charset=>'utf-8'
,p_file_content=>wwv_flow_api.varchar2_to_blob(wwv_flow_api.g_varchar2_table)
);
end;
/
begin
wwv_flow_api.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false), p_is_component_import => true);
commit;
end;
/
set verify on feedback on define on
prompt  ...done
