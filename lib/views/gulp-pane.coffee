{DockPaneView, Toolbar} = require 'atom-bottom-dock'
TableView = require './hoff-table-view'
{Emitter, CompositeDisposable} = require 'atom'
OutputView = require './output-view'
ControlsView = require './controls-view'
FileFinderUtil = require '../file-finder-util'
{$} = require 'space-pen'

class GulpPaneView extends DockPaneView
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'display:flex;', =>
            @subview 'toolbar', new Toolbar()
            #@subview 'outputView', new OutputView()

    renderResults: (resultsets) ->
        resultset = resultsets[0]
        if not resultset.complete
            return
        options =
            enableCellNavigation: false
            enableColumnReorder: true
            multiColumnSort: true
            forceFitColumns: true
        @table = new TableView options, resultset.rows, resultset.columns
        @empty()
        @append @table
        console.log 'RENDER', resultsets

    createRow: ->
        row =
            name: 'Jeff'
            city: 'Stockholm'
        return row
    initialize: ->
        super()
        @fileFinderUtil = new FileFinderUtil()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()
        @controlsView = new ControlsView()

        columns = [
            {id: "name", minWidth: 300, name: "Name", field: "name" }
            {id: "city", name: "City", field: "city", sortable: true }
        ]
        options =
            enableCellNavigation: false
            enableColumnReorder: true
            multiColumnSort: true
            forceFitColumns: false
            syncColumnCellResize: true
            fullWidthRows: true

        @table = new TableView options, data, columns
        data = [{name: "Jeff", city: "asdasd"}]
        @table.deleteAllRows()
        @append @table

        @table.addRows data

        @table.onDidClickGridItem (row) =>
            console.log 'onDidClickGridItem', row

        #@table.onDidFinishAttaching =>
# @render messages: @linter.getMessages(

        #@outputView.show()

        @toolbar.addLeftTile item: @controlsView, priority: 0

        @subscriptions.add @controlsView.onDidClickRefresh @refresh
        @subscriptions.add @controlsView.onDidClickStop @stop
        @subscriptions.add @controlsView.onDidClickClear @clear


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
