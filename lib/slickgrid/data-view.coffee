{View, $}                           = require 'space-pen'
DataTable                           = require './dt/datatable'
Data                                = require './dt/data'

class HoffDataView extends View
    @content: (data) ->
        @div style: 'width: 100%; height:100%;', ->

    initialize: (data) ->
        @dt = new DataTable @

        @setData(data)

    setData: (data) ->
        if (data.rows.length > 0)
            columns = Object.keys(data.rows[0]).map (x) ->
                {
                    label: x,
                    width: 60
                }
            rows = data.rows.map (x) ->
                return Object.values(x)

            y = { columns: columns, rows: rows }
            console.log('y', y)
            @dt.setData(y);

module.exports = HoffDataView
