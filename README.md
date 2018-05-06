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
