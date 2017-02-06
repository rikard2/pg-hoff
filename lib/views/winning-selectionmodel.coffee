SlickGrid = require 'bd-slickgrid/grid'

class WinningSelectionModel
    onSelectedRangesChanged: new Slick.Event
    activeRange: null
    activeRangeComplete: false
    ranges: []

    init: (@grid) =>
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onClick.subscribe(@onClick)
        @grid.onMouseEnter.subscribe(@onMouseEnter)

    handleGridClick: (e, args) =>
        #console.log 'e', e
        cell = @grid.getCellFromEvent(e)
        return unless cell?

        unless e.shiftKey or e.metaKey
            @activeRange = null
            @ranges = []

        if e.metaKey and @activeRange
            console.log 'new range!!!', @activeRange
            @ranges.push @activeRange
            @activeRange = null


        unless @activeRange?
            @activeRange = new Slick.Range(cell.row, cell.cell, cell.row, cell.cell)
            @activeRangeComplete = false
        else
            @activeRange.toRow = cell.row
            @activeRange.toCell = cell.cell
            @activeRangeComplete = true

         @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    onDoubleClick: (e, args) =>

    onClick: (e, args) =>

    onMouseEnter: (e, args) =>

    destroy: =>

module.exports = WinningSelectionModel
