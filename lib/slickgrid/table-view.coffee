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
        @normalData = @data
        @normalColumns = @columns
        if @options.transpose and @data
            @transposeData()
        else
            @deTransposeData()

        @columnpick = false
        @startColumn = {}
        @selectedColumns = []
        @selectionModel = selectionModel
        resizeTimeout = null
        $(window).resize =>
            clearTimeout(resizeTimeout)
            resizeTimeout = setTimeout(@resize, 200)

    appendData: (data) =>
        for i in [0...data?.length?]
            @data.push data[i]
        for d, index in @data?
            d['rownr'] = index + 1
        @grid.updateRowCount()
        @grid.render()

    expandColumns: =>
        maxrows = 1
        for c in @columns when c["field"] != 'rownr'
            max = 0
            width = 200
            for d in @data
                if d[c["field"]] != null
                    rows = 0
                    for l in d[c["field"]].toString().split('\n')
                        rows += 1
                        if l.length * 9 > max
                            max = l.length * 9
                    if rows > maxrows
                        maxrows = rows
                max = Math.max(max, Math.round((c["name"].length * 8.4) + 12))
            width = max
            c['width'] = width
        @options.rowHeight = maxrows * 17 + 15
        @options.whitespace = 'pre'
        @grid.setOptions(@options);
        @grid.setColumns(@columns);
        @grid.invalidate();
        @grid.render();
        @resize()


    transposeData: =>
        @columns = @normalColumns.slice()
        @data = @normalData.slice()
        transpose = new TransposeSlickData @columns, @data
        @columns = transpose.columns
        @data = transpose.rows
        @options.transpose = true

    deTransposeData: =>
        @columns = @normalColumns.slice()

        if @options.rowNumberColumn
            rowNumberWidth = @options.rowcount.toString().length * 11.5
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
                sortable:true
                type:"bigint"
                type_code: 20
                width: rowNumberWidth
            @columns.unshift(rowNumberColumn)
            unless @normalData
                return
            @data = @normalData.slice()
            for d, index in @data
                d['rownr'] = index + 1
        @options.transpose = false

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

        @[0].transpose = () =>
            if @options.transpose
                @deTransposeData()
            else
                @transposeData()
            @grid.setData(@data)
            @grid.setColumns(@columns)
            @grid.invalidate()
            @resize()

        if @selectionModel
            @selectionModel = new @selectionModel @grid
        else
            @selectionModel = new WinningSelectionModel @grid
        @grid.setSelectionModel(@selectionModel)
        @resize()
        setTimeout( () =>
            @resize()
        , 250)
        @grid.onColumnsReordered.subscribe (e, args) =>
                @columns = @grid.getColumns()

        @grid.onColumnResizeDblClick.subscribe (e, args) =>
            headerid = $(e.currentTarget).parent().attr('headerid')
            column = @columns[@grid.getColumnIndex(headerid)]
            max = 0
            for d in @data
                if d[headerid] != null and d[headerid]?.toString()?.length > max
                    max = d[headerid].toString().length
            max = Math.max(max * 7.8 + 10, Math.round((column['name'].length * 8.4) + 12))
            @columns[@grid.getColumnIndex(headerid)].width = max
            @resize()

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
