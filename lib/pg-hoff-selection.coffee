request = require('request')
Promise = require('promise')
Type = require('./pg-hoff-types').Type
{CompositeDisposable, Disposable} = require 'atom'

class PgHoffResultsSelection
    _selectables: []

    _selection: []
    _startSelection: null
    _endSelection: null

    _mouseupListeners: []
    _positionMap: { }

    constructor: (serializedState) ->
        document.addEventListener('mouseup', (e) =>
            @mouseup()
            @_mouseupListeners.forEach((listener) =>
                if (listener)
                    listener()
            )
        )
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'core:copy': => @onCopy()

    onCopy: () ->
        console.log 'oncopy'

    clearAreaSelection: () ->
        @_selection = [];
        @_startSelection = null;
        @_endSelection = null;

    redrawSelection: () ->
        @_selectables.forEach((selectable) =>
            @deselectCell(selectable)
        )

        @_selection.forEach((selection) =>
            @selectCell(selection)
        )

        @getAreaSelection().forEach((selection) =>
            @selectCell(selection)
        )

    selectCell: (cell) ->
        cell.selected = true
        cell.element.classList.add('marked')

    deselectCell: (cell) ->
        cell.selected = false
        cell.element.classList.remove('marked')

    attachSelectable: (selectable) ->
        @_selectables.push(selectable)
        @_positionMap[selectable.column + '_' + selectable.row] = selectable

        selectable.element.addEventListener('mousedown', (e) =>
            @selectableMousedown(selectable, e.metaKey, e.shiftKey)
        )

        selectable.element.addEventListener('mousemove', (e) =>
            @selectableMousemove(selectable, e.ctrlKey, e.shiftKey)
        )

    getAreaSelection: () ->
        selection = []

        if (@_startSelection and @_endSelection)
            startX = Math.min(@_startSelection.column, @_endSelection.column)
            endX = Math.max(@_startSelection.column, @_endSelection.column)

            startY = Math.min(@_startSelection.row, @_endSelection.row)
            endY = Math.max(@_startSelection.row, @_endSelection.row)

            #for (x = startX; x <= endX; x++)
            for x in [startX..endX]
                for y in [startY..endY]
                    if (@_positionMap[x + '_' + y])
                        selection.push(@_positionMap[x + '_' + y])

        return selection

    selectableMousedown: (selectable, ctrlKey, shiftKey) ->
        if (selectable.selected)
            if (@_selection.length == 1)
                @clearAreaSelection()
                @redrawSelection()
                return
            else if (ctrlKey)
                if (@_endSelection == null and @_startSelection != null)
                    @_selection.splice(@_selection.indexOf(selectable), 1)
                    @deselectCell(selectable)
                    return

        if (!ctrlKey && !shiftKey)
            @clearAreaSelection()

        if (shiftKey && @_startSelection)
            @_endSelection = selectable
        else
            @_startSelection = selectable
            @_endSelection = selectable
        @redrawSelection()

    selectableMousemove: (selectable, ctrlKey, shiftKey) ->
        if (@_endSelection)
            @_endSelection = selectable

        @redrawSelection()

    mouseup: () ->
        @getAreaSelection().forEach((selection) =>
            @_selection.push(selection)
        )
        @_endSelection = null

module.exports = PgHoffResultsSelection

###
export class Selection {
    private _selectables: TableCell[] = [];

    private _selection: TableCell[] = [];
    private _startSelection: TableCell = null;
    private _endSelection: TableCell = null;

    private _mouseupListeners: Function[] = [];
    private _positionMap: any = { };

    constructor() {
        document.addEventListener('mouseup', e => {
            @mouseup();
            @_mouseupListeners.forEach(listener => {
                if (listener) listener();
            });
        });
    }

    public getSelection() {
        return @_selection.map((selection) => {
            let x: any = {
                "column": selection.column,
                "row": selection.row,
                "value": selection.value
            };
            return x;
        })
    }

    private clearAreaSelection() {
        @_selection = [];
        @_startSelection = null;
        @_endSelection = null;
    }

    private redrawSelection() {
        @_selectables.forEach(selectable => {
            @deselectCell(selectable);
        });

        @_selection.forEach(selection => {
            @selectCell(selection);
        });
        @getAreaSelection().forEach(selection => {
            @selectCell(selection);
        });
    }

    private selectCell(cell: TableCell) {
        cell.selected = true;
        cell.element.classList.add('marked');
    }
    private deselectCell(cell: TableCell) {
        cell.selected = false;
        cell.element.classList.remove('marked');
    }

    attachSelectable(selectable: TableCell) {
        @_selectables.push(selectable);
        @_positionMap[selectable.column + '_' + selectable.row] = selectable;

        selectable.element.addEventListener('mousedown', e => {
            @selectableMousedown(selectable, e.metaKey, e.shiftKey);
        });

        selectable.element.addEventListener('mousemove', e => {
            @selectableMousemove(selectable, e.ctrlKey, e.shiftKey);
        });
    }

    private selectableMousedown(selectable: TableCell, ctrlKey: boolean, shiftKey: boolean) {
        if (selectable.selected) {
            if (@_selection.length == 1) {
                @clearAreaSelection();
                @redrawSelection();
                return;
            } else if (ctrlKey) {
                if (@_endSelection == null && @_startSelection != null) {
                    @_selection.splice(@_selection.indexOf(selectable), 1);
                    @deselectCell(selectable);
                    return;
                }
            }
        }

        if (!ctrlKey && !shiftKey) {
            @clearAreaSelection();
        }

        if (shiftKey && @_startSelection) {
            @_endSelection = selectable;
        } else {
            @_startSelection = selectable;
            @_endSelection = selectable;
        }
        @redrawSelection();
    }

    private selectableMousemove(selectable: TableCell, ctrlKey: boolean, shiftKey: boolean) {
        if (@_endSelection) {
            @_endSelection = selectable;
        }
        @redrawSelection();
    }

    private mouseup() {
        @getAreaSelection().forEach(selection => {
            @_selection.push(selection);
        });
        @_endSelection = null;
    }

    private getAreaSelection(): TableCell[] {
        let selection: TableCell[] = [];

        if (@_startSelection && @_endSelection) {
            let startX = Math.min(@_startSelection.column, @_endSelection.column);
            let endX = Math.max(@_startSelection.column, @_endSelection.column);

            let startY = Math.min(@_startSelection.row, @_endSelection.row);
            let endY = Math.max(@_startSelection.row, @_endSelection.row);

            for (let x = startX; x <= endX; x++) {
                for (let y = startY; y <= endY; y++) {
                    if (@_positionMap[x + '_' + y]) {
                        selection.push(@_positionMap[x + '_' + y]);
                    }
                }
            }
        }

        return selection;
    }
}

import { TableCell } from './tableCell'###
