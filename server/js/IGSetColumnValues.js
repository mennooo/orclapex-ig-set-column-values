/* global apex $ */
window.mho = window.mho || {}
;(function (namespace) {
  function IGUpdate (options) {
    this.ig$ = options.ig$
    this.grid = options.grid
    this.model = this.grid.model
    this.da = options.options
    this.type = options.type
    this.ajaxIdentifier = options.ajaxIdentifier
    this.itemsToSubmit = options.itemsToSubmit
    this.staticValue = options.staticValue
    this.jsExpression = options.jsExpression
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
      function: this.ajaxCallback
      // dialog: _getDialogValues
    }

    this.setRecords()
    this.data = this.getCurrentData()
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
    // Set the record values for each record in the updated data object
    self.records.forEach(function (record, idx) {
      self.data[idx].forEach(function (column) {
        if (column.isAffected) {
          self.model.setValue(record, column.name, column.value)
        }
      })
    })
  }

  IGUpdate.prototype.getCurrentData = function () {
    let self = this
    return this.records.map(function (record) {
      return self.columnConfig.map(function (column) {
        return {
          name: column.name,
          value: self.model.getValue(record, column.name),
          dataType: column.dataType,
          formatMask: column.appearance.formatMask,
          isReadOnly: column.isReadOnly,
          isAffected: (self.affectedColumns.indexOf(column.name) > -1)
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

  /**
   * Get the JavaScript Expression value
   *
   * @param {any} options
   * @returns A resolved promise with the value
   */
  IGUpdate.prototype.updateWithJavaScriptExpressionValues = function () {
    let self = this
    let deferred = $.Deferred()
    let context = {}

    this.data = this.data.map(function (record) {
      // Add columns as object in context
      context = {}
      record.forEach(function (column) {
        context[column.name] = column.value
      })
      // Change value for each column
      return record.map(function (column) {
        if (column.isAffected) {
          column.value = self.jsExpression.call(context)
        }
        return column
      })
    })

    // Return promise
    deferred.resolve()
    return deferred.promise()
  }

  // IGUpdate.prototype.updateWithSQLValues = function () {
  //   this.ajaxCallback()
  // }

  /**
   * Get the PL/SQL expression values
   *
   * @param {any} options
   * @param {any} records
   * @returns A resolved promise with the value
   */
  function _getPLSQLExpressionValues (options, records) {
    return _ajaxCallback(options.ajaxIdentifier, options.type, options.pageItemsToSubmit, options.ig$, records)
  }

  /**
   * Get the PL/SQL function values
   *
   * @param {any} options
   * @param {any} records
   * @returns A resolved promise with the value
   */
  function _getPLSQLFunctionValues (options, records) {
    return _ajaxCallback(options.ajaxIdentifier, options.type, options.pageItemsToSubmit, options.ig$, records)
  }

  /**
   * Get the Dialog Return value
   *
   * @param {any} options
   * @param {any} records
   * @returns A resolved promise with the value
   */
  function _getDialogValues (options, records) {
    options.staticValue = options.da
    return _getStaticValue(options, records)
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

      // Create a new instance of the object to update the grid
      let update = new IGUpdate({
        ig$: ig$,
        grid: gridView,
        da: options.da,
        type: options.type,
        ajaxIdentifier: options.ajaxIdentifier,
        itemsToSubmit: options.itemsToSubmit,
        staticValue: options.staticValue,
        jsExpression: options.jsExpression,
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
