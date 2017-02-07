SlickGrid = require 'bd-slickgrid/grid'

class WinningSelectionModel
    onSelectedRangesChanged: null
    activeRange: null
    activeRangeComplete: false
    ranges: []
    grid : null

    init: (grid) =>
        @grid = grid
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onMouseEnter.subscribe(@onMouseEnter)
        @grid.onKeyDown.subscribe(@onKeyDown)
        @grid.onMouseDown.subscribe(@onMouseDown)
        @onSelectedRangesChanged = new Slick.Event

    onMouseDown: (e, args) =>
        cell = @grid.getCellFromEvent(e)
        @dragCell = cell
        return unless cell?

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
            @activeRange = new Slick.Range(cell.row, cell.cell, cell.row, cell.cell)
            @activeRangeComplete = false
        else
            @activeRange.fromRow = Math.min(@activeRange.fromRow, cell.row)
            @activeRange.toRow = Math.max(@activeRange.fromRow, cell.row)

            @activeRange.fromCell = Math.min(@activeRange.fromCell, cell.cell)
            @activeRange.toCell = Math.max(@activeRange.fromCell, cell.cell)
            @activeRangeComplete = true

         @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    handleGridClick: (e, args) =>
        cell = @grid.getCellFromEvent(e)
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
            @onMouseDown(e, args)

    onKeyDown: (e, args) =>
        data = @grid.getData()
        columns = @grid.getColumns()
        if e.keyCode == 27
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
        if e.keyCode == 65 and e.metaKey and data.length > 0
            @ranges = []
            @activeRange = new Slick.Range 0, 0, data.length - 1, columns.length - 1
            console.log @activeRange, data.length, data[0]
            @onSelectedRangesChanged.notify [ @activeRange ]
        if (e.metaKey or e.ctrlKey) and e.keyCode == 67
            selectedColumns = []
            output = []
            data = @grid.getData()
            columns = @grid.getColumns()
            for range in @ranges.concat( [ @activeRange ] )
                for x in [range.fromCell..range.toCell]
                    for y in [range.fromRow..range.toRow]
                        selectedColumns.push({x: x, y:y})
            for cell in selectedColumns
                output.push(data[cell.y][columns[cell.x]["field"]]?.toString())
            atom.clipboard.write(output.join(", ").toString())
            #atom.clipboard.write(@data[args.row][@columns[args.cell]["field"]].toString())


    onDoubleClick: (e, args) =>

    onClick: (e, args) =>

    onMouseEnter: (e, args) =>
        return unless e.buttons == 1 and e.button == 0

        cell = @grid.getCellFromEvent(e)
        return unless cell?

        @activeRange = null
        #@ranges = []

        if e.metaKey and @activeRange
            # console.log 'new range!!!', @activeRange
            @ranges.push @activeRange
            @activeRange = null

        @activeRange = new Slick.Range(@dragCell.row, @dragCell.cell, @dragCell.row, @dragCell.cell)

        @activeRange.fromRow = Math.min(@activeRange.fromRow, cell.row)
        @activeRange.toRow = Math.max(@activeRange.toRow, cell.row)

        @activeRange.fromCell = Math.min(@activeRange.fromCell, cell.cell)
        @activeRange.toCell = Math.max(@activeRange.toCell, cell.cell)
        @activeRangeComplete = true

        @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    destroy: =>

module.exports = WinningSelectionModel
