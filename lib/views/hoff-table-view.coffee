{View, $} = require 'space-pen'
window.jQuery = $
SlickGrid = require 'bd-slickgrid/grid'
{Emitter, Disposable} = require 'atom'

class HoffTableView extends View
  @content: (options, data, columns, height) ->
    console.log 'width: 100% !important;height:'.concat(height, ';overflow: auto !important;')
    @div style: 'width: 100% !important;height:'.concat(height, ';overflow: auto !important;'), ->

  initialize: (@options, @data, @columns) ->
    @emitter = new Emitter()
    @columnpick = false
    @startColumn = {}
    @selectedColumns = []
    resizeTimeout = null
    $(window).resize =>
      clearTimeout(resizeTimeout)
      resizeTimeout = setTimeout(@resize, 100)

  resize: (heightOnly) =>
    @grid.resizeCanvas()
    @grid.autosizeColumns() #unless heightOnly

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
    return unless cols.data
    
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
    @resize()
    @grid.resizeCanvas()

    @grid.onColumnsReordered.subscribe (e, args) =>
        @columns = @grid.getColumns()

    @grid.onSort.subscribe (e, args) =>
      @sortData()
      @grid.invalidate()
      @grid.render()

    @grid.onDblClick.subscribe (e, args) =>
        @grid.removeCellCssStyles("birthday_highlight")
        obj1 = {}
        obj2 = {}
        obj1[@columns[args.cell]["field"]] = "highlight"
        obj2[args.row] = obj1
        @grid.setCellCssStyles("birthday_highlight", obj2)
        @startColumn["x"] = args.cell
        @startColumn["y"] = args.row
        @columnpick = true

    @grid.onClick.subscribe (e, args) =>
        if @columnpick
            @columnpick = false
            @grid.removeCellCssStyles("birthday_highlight")
            output = []
            for a in @selectedColumns
                output.push(@data[a.y][@columns[a.x]["field"]].toString())
            atom.clipboard.write(output.join(", ").toString())
        else
            @grid.flashCell(args.row, args.cell, 200)
            atom.clipboard.write(@data[args.row][@columns[args.cell]["field"]].toString())

    @grid.onMouseEnter.subscribe (e, args) =>
        if @columnpick
            #calculate selected area
            cell = @grid.getCellFromEvent(e)
            xFrom = Math.min(@startColumn.x, cell.cell)
            xTo = Math.max(@startColumn.x, cell.cell)
            yFrom = Math.min(@startColumn.y, cell.row)
            yTo = Math.max(@startColumn.y, cell.row)
            obj1 = {}
            obj2 = {}
            @selectedColumns = []
            for x in [xFrom..xTo]
                for y in [yFrom..yTo]
                    #console.log @columns[cell.cell]["field"], x, y
                    obj1[@columns[x]["field"]] = "highlight"
                    obj2[y] = obj1
                    @selectedColumns.push({x: x, y:y})
            @grid.setCellCssStyles("birthday_highlight", obj2)






  onDidDoubleClick: (callback) =>
     @emitter.on 'doubleclicked', callback

  onDidFinishAttaching: (callback) =>
    @emitter.on 'table:attach:finished', callback



module.exports = HoffTableView
