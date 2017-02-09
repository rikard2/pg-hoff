SlickGrid = require 'bd-slickgrid/grid'

class RowSelectionModel
    onSelectedRangesChanged: null
    activeRange: null
    activeRangeComplete: false
    ranges: []
    grid : null
    lastCell: {}
    startCell: {}

    init: (grid) =>
        @grid = grid
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onKeyDown.subscribe(@onKeyDown)
        @grid.onAnimationEnd.subscribe(@onAnimationEnd)

        @onSelectedRangesChanged = new Slick.Event

    handleGridClick: (e, args) =>
        cell = @grid.getCellFromEvent(e)
        @lastCell = x: cell.cell, y: cell.row
        @activeRange = new Slick.Range cell.row, 0, cell.row, 3
        @onSelectedRangesChanged.notify [ @activeRange ]

    onKeyDown: (e, args) =>
        data = @grid.getData()
        columns = @grid.getColumns()
        if @lastCell? and ( [ 38, 40 ].indexOf e.keyCode ) >= 0
            deltaX = 0
            deltaY = 0
            if e.keyCode == 38 and @lastCell? # UP
                deltaY = -1
            else if e.keyCode == 40 and @lastCell? # DOWN
                deltaY = 1

            outOfBounds = true

            unless @lastCell.y + deltaY < 0 or @lastCell.y + deltaY >= data.length
                @lastCell.y = @lastCell.y + deltaY
                outOfBounds = false

            unless outOfBounds
                @activeRange = new Slick.Range @lastCell.y, 0, @lastCell.y, 3
                @onSelectedRangesChanged.notify [ @activeRange ]

        if (e.metaKey or e.ctrlKey) and e.keyCode == 67
            obj1 = {}
            obj2[@lastCell.y] = obj1
            atom.clipboard.write(data[@lastCell.y]["query"]?.toString())
            @grid.setCellCssStyles("copy_Flash", obj2)

        if e.keyCode == 13
            for pane in atom.workspace.getPanes()
                atom.commands.dispatch(atom.views.getView(pane), 'application:new-file')
            setTimeout( () =>
                atom.workspace.getActiveTextEditor().insertText(data[@lastCell.y]["query"].toString())
            , 50)

    onAnimationEnd: (e, args) =>
        @grid.removeCellCssStyles("copy_Flash")

    onDoubleClick: (e, args) =>

    onClick: (e, args) =>

    destroy: =>

module.exports = RowSelectionModel
