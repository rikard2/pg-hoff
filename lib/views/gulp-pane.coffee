{DockPaneView, TableView, Toolbar} = require 'atom-bottom-dock'
TableView = require './hoff-table-view'
{Emitter, CompositeDisposable} = require 'atom'
OutputView = require './output-view'
ControlsView = require './controls-view'
FileFinderUtil = require '../file-finder-util'
{$} = require 'space-pen'
window.jQuery = require 'jquery'

class GulpPaneView extends DockPaneView
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important;', =>
            #@subview 'toolbar', new Toolbar()
            #@subview 'outputView', new OutputView()

    renderResults: (resultsets) ->
        resultset = resultsets[0]
        if not resultset.complete
            return
        options =
            enableCellNavigation: false
            enableColumnReorder: true
            multiColumnSort: false
            forceFitColumns: false
            fullWidthRows: false
        for c in resultset.columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            #max = 0
            #for d in resultset.rows
            #    if d[c["field"]] != null && d[c["field"]].length > max
            #        max = d[c["field"]].length
            #c["maxWidth"] = max * 8
            #c["minWidth"] = 30

        @table = new TableView options, resultset.rows, resultset.columns
        #@table = new TableView resultset.rows, resultset.columns

        @empty()
        @append @table
        console.log 'RENDER', resultsets


    initialize: ->
        super()
        @fileFinderUtil = new FileFinderUtil()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()
        @controlsView = new ControlsView()
        columns = [
          {id: "regex", name: "Regex", field: "regex", sortable: true }
          {id: "mesage", name: "Message", field: "message", sortable: true }
          {id: "path", name: "Path", field: "path", sortable: true }
          {id: "line", name: "Line", field: "line", sortable: true }
        ]
        @table = new TableView [], columns
        data = [{name: "Jeff", city: "asdasd"}]
        @table.deleteAllRows()
        @append @table

        @table.addRows data

        @table.onDidClickGridItem (row) =>
            console.log 'onDidClickGridItem', row

        #@table.onDidFinishAttaching =>
# @render messages: @linter.getMessages(

        #@outputView.show()

        #@toolbar.addLeftTile item: @controlsView, priority: 0

        @subscriptions.add @controlsView.onDidClickRefresh @refresh
        @subscriptions.add @controlsView.onDidClickStop @stop
        @subscriptions.add @controlsView.onDidClickClear @clear

    resize: ->
        @table.resize(true)

    refresh: =>
        @outputView.refresh()

    stop: =>
        @outputView.stop()

    clear: =>
        @outputView.clear()

    destroy: ->
        @outputView.destroy()
        @subscriptions.dispose()
        @remove()

module.exports = GulpPaneView
