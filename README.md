# orclapex-ig-set-column-values
An Oracle APEX Plug-in to set column values just like the native `Set Value` Dynamic Action. No JavaScript is required anymore.

You can set values using a:
* Static Value
* JavaScript Expression
* SQL Statement
* PL/SQL Function Body
* Dialog Return Item
* PL/SQL Expression

Examples for each of the above is given in the help section of the plugin.

## Adding the dynamic action on your page

**The triggering element has to be the Interactive Grid**
The reason is that only in this scenario, you can choose the columns by name as the `Affected Elements`.

The event could be triggered by a (toolbar) button, dialog close event or any other event on the Interactive Grid.

It works very well with the **Extend Interactive Grid Toolbar Plugin** by Marko Goricki.  
https://github.com/mgoricki/apex-plugin-extend-ig-toolbar

## Settings

Some of these settings are conditional and shown only in certain scenarios. See the help text in the plugin for examples.

### Set Type
How do you want to set the value?
* Static Value (default)
* JavaScript Expression
* SQL Statement
* PL/SQL Function Body
* Dialog Return Item
* PL/SQL Expression

### Static Value
A varchar2 value.

### JavaScript Expression
The expression should result in a `number`, `string` or `array` (for multivalue columns).
Each column name can be used as a `string` object.

**No implicit conversion is being done**  
Every value is a `string`. Implicit conversion is impossible due to possible format masks and locale settings.

### SQL Statement
A SQL statement that returns between 1 and 100 columns. In cause of multiple columns, multiple affected elements must be specified.
If multiple rows are returned, the values will be concatenated by a colon. This is useful for multivalue grid columns.

### PL/SQL Expression
The expression should result in datatype that can be converted implicitly to a `VARCHAR2` or `CLOB`.

### PL/SQL Function Body
The function body should return a datatype that can be converted implicitly to a `VARCHAR2` or `CLOB`.

### Dialog Return Item
A **Page Item Value** return by a modal dialog. The dialog close event must be triggered on the Interative Grid.

### Items to Submit
Add Page Items to Submit if you want to use them in the SQL statement, PL/SQL expression or PL/SQL Function Body.  
Interative Grid Columns should be specified in the **Columns to use as bind variable** setting.

### Escape Special Characters
Escapes the values returned by a SQL Statement, PL/SQL Expression or PL/SQL Function Body.

### Records
* Selected Records (default)
* All Records

You can set this to **All Records** if you don't want the users to check all records manually first.

### Columns to use as bind variable
Interactive Grid Column Values can be used as bind variables, like Page Items. Each of the column names specified here must be present in the SQL Statement, PL/SQL Expression or PL/SQL Function Body.

## Why this plugin

On of the first things I tried with the editable Interative Grid is to the the value trough a dynamic action. It was not possible without some JavaScript code like below.

```javascript
var grid = apex.region("EMPLOYEES").widget().interactiveGrid('getViews','grid');
var model = grid.model;
var record = grid.getSelectedRecords();
record.forEach(function(object, index){
  rec = record[index];
  model.setValue(rec, 'TEST', '1')
});
```

This plugin lets you update the values declaratively.
