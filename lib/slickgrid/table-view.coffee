{Emitter, Disposable}               = require 'atom'
{View, $}                           = require 'space-pen'
SlickGrid                           = require '../../extlib/bd-slickgrid/grid'
WinningSelectionModel               = require './selection-models/winning-selectionmodel'
TransposeSlickData                  = require './transpose'
JSONModal                           = require '../modals/json-modal'
{showOpenScripts, openScripts, showWriteScripts, writeScripts, showWriteAndOpenScripts, writeAndOpenScripts}      = require '../open-scripts'

class HoffTableView extends View
    @content: (options, data, columns, height, selectionmodel) ->
        @div style: 'width:  100% !important;height:100%;overflow: auto !important;', ->

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

    sizeIt: (opts) =>
        opts = Object.assign({
            expandHeights: false,
            expandWidths: true
        }, opts)

        cellHeight = 0
        for c, i in @columns when c["field"] != 'rownr'
            cellLength = 0
            for d in @data
                if d[c["field"]] != null
                    rows = 0
                    for l in d[c["field"]].toString().trim().split('\n')
                        rows += 1
                        cellLength = l.length if l.length > cellLength
                    cellHeight = rows if rows > cellHeight
            cellLength = (c['name'].length + 1) if c['name'].length > cellLength
            if opts.expandWidths
                w = @getElementSize(cellLength, 1).width
                w = opts.maxWidth if opts.maxWidth? and w > opts.maxWidth
                @columns[i]['width'] = w

        if opts.expandHeights
            rowHeight = @getElementSize(1, cellHeight).height
            @options.rowHeight = rowHeight

        @options.whitespace = 'pre'

        @grid.setOptions(@options);
        @grid.setColumns(@columns);

        @grid.invalidate()
        @grid.render()
        @resize()

    appendData: (data) =>
        for i in [0...data.length]
            @data.push data[i]
        for d, index in @data
            d['rownr'] = index + 1
        @grid.updateRowCount()
        @grid.render()

    setData: (data) =>
        @data = data
        @grid.setData(@data)
        @grid.updateRowCount()
        @grid.invalidate()
        @grid.render()
        @resize()

    getElementSize: (x, y) =>
        span = document.createElement('span')
        span.className = 'slick-cell l1 r1';
        span.style['white-space'] = 'pre';
        str = 'X'.repeat(x) + '\n'
        str = str.repeat(y).trim()
        span.textContent = str
        span.style['background'] = 'yellow'
        @element.parentElement.appendChild(span);
        rect = span.getBoundingClientRect()
        ret = {
            width: parseInt(Math.ceil(rect.width) + 5),
            height: parseInt(Math.ceil(rect.height) + 2)
        }
        @element.parentElement.removeChild(span)
        return ret

    expandColumns: =>
        @sizeIt({
            expandHeights: true,
            expandWidths: true
        })

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
            rowNumberWidth = @options.rowcount.toString().length * 12
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
            @data = @normalData.slice()
            for d, index in @data
                d['rownr'] = index + 1
        @options.transpose = false

    resize: () =>
        return unless @grid

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

        @[0].showOpenScripts = () =>
            showOpenScripts(@data)

        @[0].openScripts = () =>
            openScripts(@data)

        @[0].showWriteScripts = () =>
            showWriteScripts(@data)

        @[0].writeScripts = () =>
            writeScripts(@data)

        @[0].showWriteAndOpenScripts = () =>
            showWriteAndOpenScripts(@data)

        @[0].writeAndOpenScripts = () =>
            writeAndOpenScripts(@data)

        @[0].transpose = () =>
            if @options.transpose
                @deTransposeData()
            else
                @transposeData()
            @grid.setData(@data)
            @grid.setColumns(@columns)
            @grid.invalidate()
            @resize()

        @selectionModel = new WinningSelectionModel @grid
        @grid.setSelectionModel(@selectionModel)
        @sizeIt({
            expandHeights: false,
            expandWidths: true,
            maxWidth: 350
        })
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
            max = column['name'].length if column['name'].length > max
            @columns[@grid.getColumnIndex(headerid)].width = @getElementSize(max, 1).width

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
