{View, $} = require 'space-pen'
window.jQuery = $
SlickGrid = require 'bd-slickgrid/grid'
WinningSelectionModel = require './winning-selectionmodel'
{Emitter, Disposable} = require 'atom'

class HoffTableView extends View
    @content: (options, data, columns, height, selectionmodel) ->
        # console.log 'width: 100% !important;height:'.concat(height, ';overflow: auto !important;')
        @div style: 'width: 100% !important;height:'.concat(height, ';overflow: auto !important;'), ->

    initialize: (@options, @data, @columns, height, selectionModel) ->
        @emitter = new Emitter()
        @columnpick = false
        @startColumn = {}
        @selectedColumns = []
        @selectionModel = selectionModel
        resizeTimeout = null
        $(window).resize =>
            clearTimeout(resizeTimeout)
            resizeTimeout = setTimeout(@resize, 100)

    resize: (heightOnly) =>
        @grid.resizeCanvas()
        @grid.autosizeColumns() #unless heightOnly
        @grid.resizeCanvas()

    addRows: (newData) ->
        return unless @grid
        @data = @data.concat newData
        @sortData()
        @grid.setData @data
        @grid.invalidateAllRows()
        @grid.autosizeColumns()
        @grid.render()

    deleteAllRows: ->
        return unless @grid
        @data = []
        @grid.setData @data
        @grid.invalidateAllRows()
        @grid.render()

    sortData: () =>
        cols = @grid.getSortColumns()

        return unless cols.length

        @data.sort (dataRow1, dataRow2) ->
            for i in [0..cols.length-1]
                field = cols[i].columnId
                sign = if cols[i].sortAsc then 1 else -1
                value1 = dataRow1[field]
                value2 = dataRow2[field]
                result = (if value1 == value2 then 0 else if value1 > value2 then 1 else -1) * sign
                if result != 0
                    return result
            0

    attached: ->
        @data = @data ? []
        @columns = @columns ? []

        @grid = new SlickGrid @, @data, @columns, @options
        if @selectionModel
            @selectionModel = new @selectionModel @grid
        else
            @selectionModel = new WinningSelectionModel @grid
        console.log @selectionModel
        @grid.setSelectionModel(@selectionModel)
        @resize()
        setTimeout( () =>
            @resize()
        , 50)
        setTimeout( () =>
            @resize()
        , 100)
        setTimeout( () =>
            @resize()
        , 250)
        setTimeout( () =>
            @resize()
        , 500)
        setTimeout( () =>
            @resize()
        , 1000)
        setTimeout( () =>
            @resize()
        , 3000)
        @grid.onColumnsReordered.subscribe (e, args) =>
                @columns = @grid.getColumns()

        @grid.onSort.subscribe (e, args) =>
            @sortData()
            @grid.invalidate()
            @grid.render()

    onDidFinishAttaching: (callback) =>
        @grid.autosizeColumns()
        @emitter.on 'table:attach:finished', callback



module.exports = HoffTableView
