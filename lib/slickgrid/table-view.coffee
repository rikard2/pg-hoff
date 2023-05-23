{Emitter, Disposable}               = require 'atom'
{View, $}                           = require 'space-pen'
SlickGrid                           = hrequire '/../extlib/bd-slickgrid/grid'
WinningSelectionModel               = hrequire '/slickgrid/selection-models/winning-selectionmodel'
TransposeSlickData                  = hrequire '/slickgrid/transpose'
JSONModal                           = hrequire '/modals/json-modal'

{showOpenScripts, openScripts, showWriteScripts, writeScripts, showWriteAndOpenScripts, writeAndOpenScripts}      = require '../open-scripts'

class HoffTableView extends View
    @content: (options, data, columns, height, selectionmodel) ->
        @div style: 'width:  100% !important;height:100%;overflow: auto !important;', ->

    initialize: (@options, @data, @columns, height, selectionModel) ->
        @emitter = new Emitter()
        @normalData = @data
        @normalColumns = @columns

        @columnpick = false
        @startColumn = {}
        @selectedColumns = []
        @selectionModel = selectionModel
        resizeTimeout = null

        $(window).resize =>
            clearTimeout(resizeTimeout)
            resizeTimeout = setTimeout(@resize, 200)

    format: (col, val) ->
        return '' unless val?

        formatter = col['formatter']
        if formatter? and val? and col.type in ['timestamp with time zone', 'timestamp without time zone', 'time with time zone', 'time without time zone']
            str = formatter(null, null, val, col, null)
        else
            str = val.toString().trim()

    refresh: () =>
        @attached() unless @grid;
        @grid.setOptions(@options);
        @grid.setColumns(@columns);

        @grid.invalidate()
        @grid.render()
        @resize()

    sizeIt: (opts) =>
        opts = Object.assign({
            expandHeights: false,
            expandWidths: true
        }, opts)

        cellHeight = 0
        for c, i in @columns when c["field"] != 'rownr'
            cellLength = 0
            formatter = c["formatter"]
            for d in @data
                if d[c["field"]] != null
                    rows = 0
                    val = d[c["field"]]
                    str = if @data.length < 1000 then @format(c, val) else val.toString().trim()

                    for l in str.split('\n')
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
        div = document.createElement('span')
        div.className = 'gulp-pane'
        span = div.appendChild document.createElement('span')
        span.className = 'slick-cell l1 r1';
        span.style['white-space'] = 'pre';
        str = 'X'.repeat(x) + '\n'
        str = str.repeat(y).trim()
        span.textContent = str
        span.style['background'] = 'yellow'
        document.body.appendChild(div);
        rect = span.getBoundingClientRect()
        xplus = 5
        yplus = 0
        yplus = 2 if x > 1
        ret = {
            width: parseInt(Math.ceil(rect.width) + xplus),
            height: parseInt(Math.ceil(rect.height) + yplus)
        }
        document.body.removeChild(div)
        return ret

    expandColumns: =>
        @sizeIt({
            expandHeights: true,
            expandWidths: true
        })

    transposeData: =>
        @withRowNumberColumns = @columns.slice()
        @withRowNumberData = @data.slice()

        transpose = new TransposeSlickData @withoutRowNumberColumns, @withoutRowNumberData

        @options.transpose = true
        @data = transpose.rows
        @columns = transpose.columns

        @grid.setData(@data)
        @grid.setColumns(@columns)

        @sizeIt({
            expandWidths: true,
            expandHeights: false
        })

        @grid.invalidate()
        @resize()

    deTransposeData: =>
        @data = @withRowNumberData
        @columns = @withRowNumberColumns

        @grid.setData(@data)
        @grid.setColumns(@columns)
        @options.transpose = false

        @sizeIt({
            expandWidths: true,
            expandHeights: false
        })

        @grid.invalidate()
        @resize()

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

    addRowNumber: () ->
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

        for d, index in @data
            d['rownr'] = index + 1
    attached: ->
        return if @grid
        @data = @data ? []
        @columns = @columns ? []

        @withoutRowNumberColumns = @columns.slice()
        @withoutRowNumberData = @data.slice()

        @addRowNumber() if @options.rowNumberColumn

        @grid = new SlickGrid @, @data, @columns, @options

        @[0].showOpenScripts = () =>
            #showOpenScripts(@data)

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

        @selectionModel = new WinningSelectionModel @grid
        @grid.setSelectionModel(@selectionModel)

        if @options.transpose and @data
            @transposeData()

        @sizeIt({
            expandHeights: false,
            expandWidths: true,
            maxWidth: 350
        })
        @grid.onColumnsReordered.subscribe (e, args) =>
                @columns = @grid.getColumns()

        @grid.onColumnResizeDblClick.subscribe (e, args) =>
            headerid = $(e.currentTarget).parent().attr('headerid')
            column = @columns[@grid.getColumnIndex(headerid)]
            max = 0
            for d in @data
                val = d[headerid]
                val = if @data.length < 1000 then @format(column, val) else val.toString()
                if val?
                    for l in val.split('\n')
                        if l.length > max
                            max = l.length
            max = column['name'].length + 1 if column['name'].length > max
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
