{View, $}                           = require 'space-pen'
DataTable                           = require './dt/datatable'
Data                                = require './dt/data'

class HoffDataView extends View
    @content: (data) ->
        @div style: 'width: 100%; height:100%;', ->

    initialize: (data) ->
        @dt = new DataTable @

        @setData(data)

    resize: () =>
        console.log('dt resize');
        if @dt
            @dt.invalidate()

    setData: (data) ->
        typeFormat = {
            default: {
                formatStyle: (val) ->
                    if (val == null)
                        return { color: 'darkorange'  }
                formatValue: (val) ->
                    if (val == null)
                        return '(null)'
                    else
                        return val
            }
            boolean: { # boolean
                formatStyle: (val) ->
                    if (val == null)
                        return { color: 'darkorange'  }
                    if (val == true)
                        return { color: 'green' }
                    else if (val == false)
                        return { color: 'red' }
                formatValue: (val) ->
                    if (val == null)
                        return '(null)'
                    else
                        return val
            }
        }
        typeCodeMap = {
            16      : 'boolean',
            20      : 'number',
            23      : 'number',
            25      : 'text',
            1043    : 'text',
            1184    : 'timestamp',
            1700    : 'number'
        }

        columns = data.columns.map (x) ->
            len = x.name.length * 4
            {
                field: x.field,
                label: x.name,
                width: Math.max(len, 20),
                formatStyle: (typeFormat[typeCodeMap[x.type_code] || 'default'] || typeFormat['default']).formatStyle,
                formatValue: (typeFormat[typeCodeMap[x.type_code] || 'default'] || typeFormat['default']).formatValue
            }
        rows = data.rows.map (x) ->
            return columns.map (n) ->
                return x[n.field]

        y = { columns: columns, rows: rows }
        @dt.setData(y);

module.exports = HoffDataView
