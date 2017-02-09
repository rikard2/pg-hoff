{DockPaneView, TableView, Toolbar} = require 'atom-bottom-dock'
TableView = require './hoff-table-view'
{Emitter, CompositeDisposable} = require 'atom'
OutputView = require './output-view'
ControlsView = require './controls-view'
FileFinderUtil = require '../file-finder-util'
{$} = require 'space-pen'
parseInterval = require 'postgres-interval'
window.jQuery = require 'jquery'
PgHoffServerRequest         = require '../pg-hoff-server-request'


class HistoryPaneView extends DockPaneView
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>
            #@subview 'toolbar', new Toolbar()
            #@subview 'outputView', new OutputView()

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
            c["width"] = Math.min((Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))), 250)
            height = '100%'

        @table = new TableView options, resultset, columns , height

        @append @table

    initialize: ->
        super()
        @fileFinderUtil = new FileFinderUtil()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()
        @controlsView = new ControlsView()

        @subscriptions.add @controlsView.onDidClickRefresh @refresh
        @subscriptions.add @controlsView.onDidClickStop @stop
        @subscriptions.add @controlsView.onDidClickClear @clear

    refresh: =>
        @table.resize()
    stop: =>
        @outputView.stop()

    clear: =>
        @outputView.clear()

    destroy: ->
        #@outputView.destroy()
        @subscriptions.dispose()
        @remove()

module.exports = HistoryPaneView
