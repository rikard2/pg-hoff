request = require('request')
Promise = require('promise')
PgHoffTable = require('./pg-hoff-table')
Type = require('./pg-hoff-types').Type

class PgHoffTable
    resultset: null
    element: null

    constructor: (resultset) ->
        @resultset = resultset
        @element = document.createElement('div')
        @redraw()

    selectedAreas: []
    onSelection: (selection) ->
        console.debug 'not implemented selection', selection

    redraw: () ->
        while (@element.firstChild)
            @element.removeChild(@element.firstChild)
        @element.appendChild @createTable(@resultset)

    getElement: () ->
        return @element

    getCompare: (typeName, asc, colIdx) ->
        defaultCompare = (left, right) ->
            switch
                when left is null and right is null then 0
                when left is null then 1
                when right is null then -1
                else +(left > right) || - (right > left)
        compare = Type[typeName]?.compare || defaultCompare
        (left, right) -> compare(left[colIdx], right[colIdx]) * if asc then 1 else -1 ? 0

    sort: (columnIndex) ->
        console.log '@resultset', @resultset
        ascending = +@resultset.columns[columnIndex].ascending = !@resultset.columns[columnIndex].ascending
        typeName = @resultset.columns[columnIndex].type
        compare = @getCompare(typeName, ascending, columnIndex)
        @resultset.rows.sort compare

    createTable: (resultset) ->
        container = document.createElement('div')
        container.classList.add('table')
        container.classList.add('executing')

        if resultset.notices?.length > 0
            for n in resultset.notices
                notice = container.appendChild document.createElement('div')
                notice.classList.add 'notice'
                notice.textContent = n

        table = container.appendChild(document.createElement('table'))

        # Header columns
        if resultset.columns?
            col_tr = table.appendChild(document.createElement('tr'))
            for c, i in resultset.columns
                col_tr.appendChild(@createTh(c, i))

        # Rows
        if resultset.rows?
            for r, y in resultset.rows
                row_tr = table.appendChild(document.createElement('tr'))
                for c, i in r
                    row_tr.appendChild(@createTd(c, resultset.columns[i].type, i, y))

        return container

    createTh: (col, columnIndex) ->
        th = document.createElement('th')
        th.textContent = col.name
        th.setAttribute 'title', col.type
        th.textContent += if @resultset.columns[columnIndex].ascending then ' +' else ' -' ? ''

        th.onclick = =>
            @sort columnIndex
            @redraw()

        return th

    createTd: (text, typeName, x, y) ->
        td = document.createElement('td')
        td.classList.add 'cell_' + x + '_' + y
        if text is null
            td.className = 'null'
            td.textContent = atom.config.get('pg-hoff.nullString')
        else
            td.className = typeName + '_' + text if typeName == 'boolean'
            try
                td.textContent = @cellText(text, typeName)
            catch err
                console.error 'Could not format as ' + typeName, text
        td.setAttribute 'title', text

        td.onmousedown = () =>
            @selectedAreas = []
            @selectedAreas.push { 'start_x': x, 'start_y': y, 'end_x': null, 'end_y': null }

            selected = @element.getElementsByClassName('selected')

            while selected.length > 0
                selected[0].classList.remove 'selected'

            td.classList.add 'selected'
            window.mousedown = true

        td.onmouseover = (event) =>
            if window.mousedown
                end = @selectedAreas[@selectedAreas.length - 1]
                end.end_x = x
                end.end_y = y
                selected = @element.getElementsByClassName('selected')
                while selected.length > 0
                    selected[0].classList.remove 'selected'

                for zx in [end.start_x..end.end_x]
                    for zy in [end.start_y..end.end_y]
                        e = document.getElementsByClassName('cell_' + zx + '_' + zy)[0]
                        if e?
                            e.classList.add 'selected'

        td.onmouseup = () =>
            window.mousedown = false
            selectedCells = []
            for area in @selectedAreas
                 for zx in [area.start_x..area.end_x]
                     for zy in [area.start_y..area.end_y]
                         selectedCells.push @cellValue(zx, zy)

            @onSelection(selectedCells)
            #selectedCells = PgHoffResultsView.GetSelectedCells()

        return td

    cellValue: (x, y) ->
        cell = {}
        cell.x = x
        cell.y = y
        if @resultset.columns?
            for c, i in @resultset.columns
                if i == x
                    cell.column = { value: c, index: i }

        if @resultset.rows?
            for r, zy in @resultset.rows
                for c, zx in r
                    if x == zx and y == zy
                        cell.value = c
        return cell

    cellText: (data, typeName) ->
        typeName = typeName.slice(0, -2) if typeName.match /\[\]$/
        if data?.constructor == Array
            ct = (e) => if e is null then 'NULL' else @cellText e, typeName
            elements = (ct e for e in data)
            '[' + elements.join(', ') + ']'
        else if Type[typeName]?.format and atom.config.get('pg-hoff.formatColumns')
            Type[typeName].format(data)
        else
            data

module.exports = PgHoffTable
