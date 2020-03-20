{CompositeDisposable, Disposable}   = require 'atom'
SlickGrid                           = require '../../../extlib/bd-slickgrid/grid'
CopyModel                           = require '../copy-models/copy-model'

class WinningSelectionModel
    onSelectedRangesChanged: null
    activeRange: null
    activeRangeComplete: false
    ranges: []
    grid : null
    lastCell: {}
    startCell: {}
    subscriptions: null

    init: (grid) =>
        @grid = grid
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onMouseEnter.subscribe(@onMouseEnter)
        @grid.onKeyDown.subscribe(@onKeyDown)
        @grid.onMouseDown.subscribe(@onMouseDown)
        @grid.onAnimationEnd.subscribe(@onAnimationEnd)
        @grid.onContextMenu.subscribe(@onContextMenu)
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:copy': => @onCopyCommand()

        @onSelectedRangesChanged = new Slick.Event

    onCoreCopy: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid
        columns = @grid.getColumns()
        console.log 'onCoreCopy', @getSelectedColumns(), columns
        selectedColumns = CopyModel.CopyDefault(@getSelectedColumns(), columns)
        if selectedColumns
            obj1 = {}
            obj2 = {}
            for cell in selectedColumns
                obj1[columns[cell.x]["field"]] = "copyFlash"
                obj2[cell.y] = obj1
            @grid.setCellCssStyles("copy_Flash", obj2)
            atom.workspace.getActivePane().activate()

        atom.workspace.getActivePane().activate()

    onCopyCommand: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid

        columns = @grid.getColumns()
        CopyModel.PromptCopy(@getSelectedColumns(), columns)
            .then (selectedColumns) =>
                obj1 = {}
                obj2 = {}
                for cell in selectedColumns
                    obj1[columns[cell.x]["field"]] = "copyFlash"
                    obj2[cell.y] = obj1
                @grid.setCellCssStyles("copy_Flash", obj2)
                atom.workspace.getActivePane().activate()
            .catch (reason) ->
                #console.log 'cancel'
    onMouseDown: (e, args, local) =>
        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)
        @lastCell = x: cell.cell, y: cell.row
        @dragCell = cell

        return unless cell?
        if not (@activeRange and
        @activeRange.fromRow == @activeRange.toRow and
        @activeRange.fromCell == @activeRange.toCell and
        @activeRange.fromRow == cell.row and
        @activeRange.fromCell == cell.cell)
            @deSelect = false

        unless e.shiftKey or e.metaKey
            @activeRange = null
            @ranges = []

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        unless @activeRange?
            @startCell = x: cell.cell, y: cell.row
            @activeRange = new Slick.Range(cell.row, cell.cell, cell.row, cell.cell)

        else if not local?
            @increaseRange cell.cell, cell.row

         @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    increaseRange: (x, y) =>
        @activeRange.fromRow = Math.min(@startCell.y, y)
        @activeRange.toRow = Math.max(@startCell.y, y)

        @activeRange.fromCell = Math.min(@startCell.x, x)
        @activeRange.toCell = Math.max(@startCell.x, x)

    handleGridClick: (e, args) =>
        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)

        if @activeRange and
        @activeRange.fromRow == @activeRange.toRow and
        @activeRange.fromCell == @activeRange.toCell and
        @activeRange.fromRow == cell.row and
        @activeRange.fromCell == cell.cell and
        @deSelect == false
            @deSelect = true
            return
        else if @deSelect == true
            @deSelect = false
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
            return
        else
            @onMouseDown(e, args, true)

    @ActiveGrid: null # STATIC
    onKeyDown: (e, args) =>
        WinningSelectionModel.ActiveGrid = @grid
        data = @grid.getData()
        columns = @grid.getColumns()
        if @lastCell? and ( [ 37, 38, 39, 40 ].indexOf e.keyCode ) >= 0
            deltaX = 0
            deltaY = 0
            if e.keyCode == 37 and @lastCell? # LEFT
                deltaX = -1
            else if e.keyCode == 38 and @lastCell? # UP
                deltaY = -1
            else if e.keyCode == 39 and @lastCell? # RIGHT
                deltaX = 1
            else if e.keyCode == 40 and @lastCell? # DOWN
                deltaY = 1

            unless @lastCell.x
                @lastCell = {x:1, y:0}
                @startCell = {x:1, y:0}
                @activeRange = new Slick.Range 0, 1, 0, 1
                @onSelectedRangesChanged.notify [ @activeRange ]
                return

            cellCanBeSelected = @grid.canCellBeSelected(@lastCell.y + deltaY, @lastCell.x + deltaX)
            outOfBounds = true
            unless cellCanBeSelected == false or @lastCell.x + deltaX < 0 or @lastCell.x + deltaX >= columns.length
                @lastCell.x = @lastCell.x + deltaX
                outOfBounds = false

            unless cellCanBeSelected == false or @lastCell.y + deltaY < 0 or @lastCell.y + deltaY >= data.length
                @lastCell.y = @lastCell.y + deltaY
                outOfBounds = false

            unless outOfBounds
                if e.shiftKey
                    @increaseRange @lastCell.x, @lastCell.y
                else
                    @startCell = x: @lastCell.x, y: @lastCell.y
                    @activeRange = new Slick.Range @lastCell.y, @lastCell.x, @lastCell.y, @lastCell.x

                @onSelectedRangesChanged.notify [ @activeRange ]
        if e.keyCode == 27
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
        if e.keyCode == 65 and e.metaKey and data.length > 0
            @ranges = []
            firstColumn = 0
            firstColumn = 1 unless @grid.canCellBeSelected(0, 0)
            @activeRange = new Slick.Range 0, firstColumn, data.length - 1, columns.length - 1
            @onSelectedRangesChanged.notify [ @activeRange ]
        if (e.metaKey or e.ctrlKey) and e.keyCode == 67
            @.onCoreCopy()
            e.stopPropagation()

    getSelectedColumns: () =>
        selectedColumns = []
        data = @grid.getData()
        columns = @grid.getColumns()
        for range in @ranges.concat( [ @activeRange ] )
            continue unless range?
            for x in [range.fromCell..range.toCell]
                for y in [range.fromRow..range.toRow]
                    selectedColumns.push({x: x, y:y}) if @grid.canCellBeSelected(y, x)
        for cell in selectedColumns
            cell.value = data[cell.y][columns[cell.x]["field"]]
        return selectedColumns

    formatCell: (columnType, cellValue) ->
        if cellValue == null
            return 'NULL'
        else if atom.config.get('pg-hoff.quoteValues') and columnType not in ['integer', 'bigint', 'numeric', 'real']
            return "'" + cellValue + "'"
        else
            return cellValue

    onAnimationEnd: (e, args) =>
        @grid.removeCellCssStyles("copy_Flash")

    onDoubleClick: (e, args) =>


    onMouseEnter: (e, args) =>
        return unless e.buttons == 1 and e.button == 0

        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)
        @lastCell = x: cell.cell, y: cell.row

        @activeRange = null

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        return unless @dragCell?
        @activeRange = new Slick.Range(@dragCell.row, @dragCell.cell, @dragCell.row, @dragCell.cell)

        @activeRange.fromRow = Math.min(@activeRange.fromRow, cell.row)
        @activeRange.toRow = Math.max(@activeRange.toRow, cell.row)

        @activeRange.fromCell = Math.min(@activeRange.fromCell, cell.cell)
        @activeRange.toCell = Math.max(@activeRange.toCell, cell.cell)
        @activeRangeComplete = true

        @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    onContextMenu: (e) =>
      e.preventDefault()
      cell = @grid.getCellFromEvent(e)
      columns = @grid.getColumns()
      columnname = columns[cell.cell]['name']
      target = '.' + e.target.classList[0] + '.' + e.target.classList[1]
      value = @grid.getData()[cell.row][columns[cell.cell]["field"]]
      commandparams = {}
      commandparams['pg-hoff:executecellops' + cell.cell.toString() + cell.row.toString()] = (event) => @performCellOps(command, columnname, value)
      command = atom.commands.add 'atom-workspace', commandparams
      if columnname.toLowerCase() == 'orderid'
          menu = {}
          menu[target] = [{
               'label': 'Do awesome stuff with ' + columnname,
               'command':'pg-hoff:executecellops' + cell.cell.toString() + cell.row.toString()
            }]
          menuitem = atom.contextMenu.add menu

    performCellOps: (command, columnname, value) ->
        command.dispose()
        atom.notifications.addInfo('Awestome stuff happening with ' + columnname + ' ' + value)

    destroy: =>

module.exports = WinningSelectionModel
