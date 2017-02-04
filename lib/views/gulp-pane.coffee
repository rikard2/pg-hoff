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
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>
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
            rowHeight:20
            headerRowHeight: 20
            multiSelect:true
            cellFlashingCssClass: "flashcell"

        for c in resultset.columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            c["width"] = 200
            max = 0
            for d in resultset.rows
                #console.log 'hej->', c["field"], d[c["field"]].length, max
                if d[c["field"]] != null && d[c["field"]].toString().length > max
                    max = d[c["field"]].toString().length
                    #console.log 'hej->', c["field"], d[c["field"]].length, max
            c["width"] = Math.min((Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))), 250)



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
