{View, $}                           = require 'space-pen'
window.jQuery                       = $
SlickGrid                           = require '../../extlib/bd-slickgrid/grid'
WinningSelectionModel               = require './selection-models/winning-selectionmodel'
TransposeSlickData                  = require './transpose'
{Emitter, Disposable}               = require 'atom'
JSONModal                           = require '../modals/json-modal'

class HoffTableView extends View
    @content: (options, data, columns, height, selectionmodel) ->
        @div style: 'width: 100% !important;height:'.concat(height, ';overflow: auto !important;'), ->

    initialize: (@options, @data, @columns, height, selectionModel) ->
        @emitter = new Emitter()
        if @options.transpose
            transpose = new TransposeSlickData @columns, @data
            @columns = transpose.columns
            @data = transpose.rows
        else if @options.rowNumberColumn
            if @data.length <= 9
                rowNumberWidth = 15
            else if @data.length <= 99
                rowNumberWidth = 25
            else if @data.length <= 999
                rowNumberWidth = 35
            rowNumberColumn =
                defaultSortAsc:true
                field:"rownr"
                headerCssClass:'row-number'
                id:"rownr"
                minWidth:30
                selectable: false
                focusable: false
                name:""
                rerenderOnResize :true
                resizable:false
                sortable:false
                type:"bigint"
                type_code: 20
                width: rowNumberWidth
            @columns.unshift(rowNumberColumn)
            for d, index in @data
                d['rownr'] = index + 1

        @columnpick = false
        @startColumn = {}
        @selectedColumns = []
        @selectionModel = selectionModel
        resizeTimeout = null
        $(window).resize =>
            clearTimeout(resizeTimeout)
            resizeTimeout = setTimeout(@resize, 100)

    resize: () =>
        @grid.resizeCanvas()
        @grid.autosizeColumns()
        @grid.resizeCanvas()

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
        @grid.setSelectionModel(@selectionModel)
        @resize()
        @grid.onColumnsReordered.subscribe (e, args) =>
                @columns = @grid.getColumns()

        @grid.onSort.subscribe (e, args) =>
            @sortData()
            @grid.invalidate()
            @grid.render()
        @grid.onDblClick.subscribe (e, args) =>
            cell = @grid.getCellFromEvent(e)
            JSONModal.Show @data[cell.row][@columns[cell.cell]["field"]]

    onDidFinishAttaching: (callback) =>
        @grid.autosizeColumns()
        @emitter.on 'table:attach:finished', callback

module.exports = HoffTableView
