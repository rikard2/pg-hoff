{Emitter, CompositeDisposable}      = require 'atom'
{$, View}                           = require 'space-pen'
parseInterval                       = require 'postgres-interval'
window.jQuery                       = require 'jquery'
PgHoffServerRequest                 = require '../server-request'
TableView                           = require '../slickgrid/table-view'
RowSelectionModel                   = require '../slickgrid/selection-models/row-selection-model'

class HistoryPaneItem extends View
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    reset: () ->
        @empty()

    render: (resultset) ->
        options =
            enableCellNavigation: false
            enableColumnReorder: true
            multiColumnSort: false
            forceFitColumns: false
            fullWidthRows: false
            rowHeight:30
            headerRowHeight: 30
            asyncPostRenderDelay: 500
            syncColumnCellResize: true
            multiSelect:true
        columns = [
            {
                id      : "timestamp",
                name    : "Timestamp",
                field   : "timestamp"
            },
            {
                id      : "alias",
                name    : "alias",
                field   : "alias"
            },
            {
                id      : "runtime_seconds",
                name    : "runtime_seconds",
                field   : "runtime_seconds"
            },
            {
                id      : "query",
                name    : "query",
                field   : "query"
            }
        ]

        for c in columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            c["width"] = 200
            max = 0
            for d in resultset
                if d[c["field"]] != null && d[c["field"]]?.toString().length > max
                    max = d[c["field"]].toString().length
            c["width"] = Math.min((Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))), 450)

        @table = new TableView options, resultset, columns , '100%', RowSelectionModel

        @append @table

    initialize: ->
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()

    refresh: =>
        @table.resize()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = HistoryPaneItem
