/* global apex $ */
window.mho = window.mho || {}
;(function (namespace) {
  function IGUpdate (options) {
    this.ig$ = options.ig$
    this.grid = options.grid
    this.model = this.grid.model
    this.da = options.da
    this.type = options.type
    this.ajaxIdentifier = options.ajaxIdentifier
    this.itemsToSubmit = options.itemsToSubmit
    this.staticValue = options.staticValue
    this.jsColumns = options.jsColumns
    this.jsExpression = options.jsExpression
    this.dialogReturnItem = options.dialogReturnItem
    this.recordSelection = options.recordSelection
    this.columnConfig = this.ig$.interactiveGrid('option', 'config.columns')
    this.affectedColumns = options.affectedColumns

    /*
      The data object will have this structure

      An array of records:
      [column1, column2, column3, ..]

      Each column is an object:
      {
        name
        value
        dataType (db datatype)
        formatMask (to cast the column to its original dataType, only for SQL and PLSQL)
        isReadOnly (readonly columns can't be updated)
        isAffected (column is part of the affectedColumns)
      }

    */

    // There are multiple ways to get the value
    this.updateMethods = {
      static: this.updateWithStaticValue,
      js: this.updateWithJavaScriptExpressionValues,
      sql: this.ajaxCallback,
      plsql: this.ajaxCallback,
      function: this.ajaxCallback,
      dialog: this.updateWithDialogReturnItems
    }

    this.setRecords()
    this.data = this.getCurrentData()
    // this.filterJsColumns()
  }

  IGUpdate.prototype.filterJsColumns = function () {
    let self = this
    this.jsColumns = this.jsColumns.filter(function (columnName) {
      let column = self.columnConfig.filter(function (column) {
        return column.name === columnName
      })[0]
      return (column)
    })
  }

  IGUpdate.prototype.setRecords = function () {
    let self = this
    // There are multiple ways to get the correct records
    let recordSelections = {
      selected: function () {
        return self.ig$.interactiveGrid('getSelectedRecords')
      },
      all: function (ig$) {
        let records = []
        self.model.forEach(function (record) {
          records.push(record)
        })
        return records
      }
    }
    this.records = recordSelections[this.recordSelection].apply(this)
  }

  IGUpdate.prototype.getValues = function () {
    return this.updateMethods[this.type].apply(this)
  }

  IGUpdate.prototype.setValues = function () {
    let self = this
    let focus = true

    function valToString (val) {
      let stringVal
      if (typeof val === 'number') {
        stringVal = val.toString()
      } else if (val === null) {
        stringVal = ''
      } else {
        stringVal = val
      }
      return stringVal
    }

    // Set the record values for each record in the updated data object
    self.records.forEach(function (record, idx) {
      // Easier to update via columnItems, but only one row can be active and editing must be turned on
      self.ig$.interactiveGrid('setSelectedRecords', record, focus)
      // Slightly faster to not focus for the rest of the records
      focus = false
      self.grid.setEditMode(true)
      self.data[idx].forEach(function (column) {
        if (column.isAffected) {
          // if the value is an array, make sure each value is a string
          if (Array.isArray(column.value)) {
            column.value = column.value.map(valToString)
          }
          // Set columnItem value
          apex.item(column.staticId).setValue(column.value)
        }
      })
    })
    
    // Reset the selected rows and turn editing off
    self.ig$.interactiveGrid('setSelectedRecords', self.records)
    self.grid.setEditMode(false)

    // For async callbacks, we need to resume the action
    apex.da.resume(self.da.resumeCallback, false)
  }

  IGUpdate.prototype.getCurrentData = function () {
    let self = this
    let value
    return this.records.map(function (record) {
      return self.columnConfig.map(function (column) {
        value = self.model.getValue(record, column.name)
        // We don't need to have the value as object, just as string
        if (value && value.v) {
          if (Array.isArray(value.v)) {
            value = value.v.join(':')
          }
          value = value.v
        }
        value = value || ''
        return {
          name: column.name,
          value: value,
          dataType: column.dataType,
          formatMask: column.appearance.formatMask,
          isReadOnly: column.isReadOnly,
          isAffected: (self.affectedColumns.indexOf(column.name) > -1),
          staticId: column.staticId
        }
      })
    })
  }

  IGUpdate.prototype.ajaxCallback = function () {
    let self = this
    let deferred = $.Deferred()
    apex.server.plugin(this.ajaxIdentifier, {
      x01: this.type,
      p_clob_01: JSON.stringify(this.data),
      pageItems: this.itemsToSubmit
    }, {
      loadingIndicator: this.ig$,
      loadingIndicatorPosition: 'centered'
    })
      .then(function (data) {
        self.data = data
        deferred.resolve()
      })

    return deferred.promise()
  }

  IGUpdate.prototype.updateWithStaticValue = function () {
    // For setting a static value we only need the current data and update it
    let self = this
    let deferred = $.Deferred()

    this.data = this.data.map(function (record) {
      return record.map(function (column) {
        if (column.isAffected) {
          column.value = self.staticValue
        }
        return column
      })
    })

    // Return recordData in promise
    deferred.resolve()
    return deferred.promise()
  }

  IGUpdate.prototype.updateWithJavaScriptExpressionValues = function () {
    let self = this
    let deferred = $.Deferred()
    let columnValues = []
    let value

    this.data = this.data.map(function (record) {
      columnValues = []

      // Get current value per column
      columnValues = self.jsColumns.map(function (columnName) {
        let column = record.filter(function (column) {
          return column.name === columnName
        })[0]
        return (column) ? column.value : ''
      })

      // Change value for each column
      return record.map(function (column) {
        if (column.isAffected) {
          value = self.jsExpression.apply(null, columnValues)
          // if value is an array
          column.value = value
        }
        return column
      })
    })

    // Return promise
    deferred.resolve()
    return deferred.promise()
  }

  IGUpdate.prototype.updateWithDialogReturnItems = function () {
    console.log(this.da.data)

    // Get dialog return item value
    this.staticValue = this.da.data[this.dialogReturnItem]
    return this.updateWithStaticValue()
  }

  /**
   * Region widgets may not exist on page load.
   * So we will create a promise and return the widget element on creation
   *
   * @param {string} regionId
   * @returns jQuery selector of widget
   */
  function _getWidget (regionId) {
    let region = apex.region(regionId)
    let ig$ = region.widget()
    let deferred = $.Deferred()

    if (ig$.length > 0) {
      deferred.resolve(ig$)
    } else {
      region.element.on('interactivegridcreate', function () {
        deferred.resolve(region.widget())
      })
    }

    return deferred.promise()
  }

  /**
   * On page load, select row based on pk page item
   *
   * Only works for single row selection because Page Items can have only one value
   *
   * @param {any} options input from APEX plugin
   *  da:     dynamic action
   *  pkItem: Primary key column names (position must be same as primary key column order for surrogate PKs)
   */
  function setValue (options) {
    let promise = _getWidget($(options.da.triggeringElement).attr('id'))
    promise.done(function (ig$) {
      options.ig$ = ig$
      let gridView = ig$.interactiveGrid('getViews').grid

      // Can't set values if the gridView is not present
      if (!gridView) {
        return
      }

      // Get records and columns for this update
      let affectedColumns = options.affectedColumns.split(',')
      let jsColumns = options.jsColumns.split(',')

      // Create a new instance of the object to update the grid
      let update = new IGUpdate({
        ig$: ig$,
        grid: gridView,
        da: options.da,
        type: options.type,
        ajaxIdentifier: options.ajaxIdentifier,
        itemsToSubmit: options.itemsToSubmit,
        staticValue: options.staticValue,
        jsColumns: jsColumns,
        jsExpression: options.jsExpression,
        dialogReturnItem: options.dialogReturnItem,
        recordSelection: options.recordSelection,
        affectedColumns: affectedColumns
      })

      // Get the new values and update the grid
      update.getValues()
        .then(function () {
          update.setValues()
        })
    })
  }

  // Add functions to namespace
  namespace.IGSetColumnValues = {
    setValue: setValue
  }
})(window.mho)
