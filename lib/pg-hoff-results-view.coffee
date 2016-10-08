request = require('request')
Promise = require('promise')

class PgHoffResultsView
    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add('pg-hoff-results-view')
        @element.setAttribute('tabindex', -1)
        @element.classList.add('native-key-bindings')

    resultsets: []

    canTypeBeSorted: (typeCode) ->
        return typeCode == 1184 || typeCode == 23 || typeCode == 25

    compare: (typeCode, left, right, asc) ->
        val = 0
        if typeCode == 1184
            val = Date.parse(left) - Date.parse(right)
        else if typeCode == 23
            val = left - right
        else if typeCode == 25
            if left < right
                val = -1
            else
                val = 1

        if !asc
            val = val * -1

        return val

    sort: (resultset, columnIndex, asc, resultsView) ->
        if resultset.columns[columnIndex].ascending?
            resultset.columns[columnIndex].ascending = !resultset.columns[columnIndex].ascending
        else
            resultset.columns[columnIndex].ascending = true

        ascending = resultset.columns[columnIndex].ascending


        typeCode = resultset.columns[columnIndex].type_code
        console.log 'trying to sort', typeCode
        compare = resultsView.compare

        resultset.rows.sort (left, right) ->
            return compare(typeCode, left[columnIndex], right[columnIndex], ascending)

    createTh: (text, resultsetIndex, columnIndex) ->
        resultsView = @
        th = document.createElement('th')
        th.textContent = text
        th.setAttribute('column_index', columnIndex)
        th.setAttribute('resultset_index', resultsetIndex)
        if resultsView.canTypeBeSorted(resultsView.resultsets[resultsetIndex].columns[columnIndex].type_code)
            th.classList.add('sortable')
            if resultsView.resultsets[resultsetIndex].columns[columnIndex].ascending == true
                th.textContent = th.textContent + ' +'
            else if resultsView.resultsets[resultsetIndex].columns[columnIndex].ascending == false
                th.textContent = th.textContent + ' -'

            th.onclick = ->
                console.log resultsView.resultsets[this.getAttribute('resultset_index')], this.getAttribute('column_index'), true
                resultsView.sort(resultsView.resultsets[this.getAttribute('resultset_index')], this.getAttribute('column_index'), true, resultsView)
                console.log 'sort by column', this.getAttribute('resultset_index'), this.getAttribute('column_index')
                resultsView.update(resultsView.resultsets)
        return th

    createTable: (x, resultsetIndex) ->
        #sort(x, 0, true)
        container = document.createElement('div')
        container.classList.add('table')

        if x.executing
            pre = container.appendChild(document.createElement('pre'))
            pre.textContent = 'Executing for ' + x.runtime_seconds + ' seconds...'
            container.classList.add('executing')
            return container

        table = container.appendChild(document.createElement('table'))

        # Header columns
        col_tr = table.appendChild(document.createElement('tr'))
        i = 0
        for c in x.columns
            col_tr.appendChild(@createTh(c.name, resultsetIndex, i))
            i = i + 1

        # Rows
        for r in x.rows
            row_tr = table.appendChild(document.createElement('tr'))
            i = 0
            for c in r
                row_tr.appendChild(@createTd(c, x.columns[i].type_code))
                i = i + 1

        return container

    createTd: (text, typeCode) ->
        td = document.createElement('td')
        td.textContent = text

        if (typeCode == 114) # JSON
            pre = document.createElement('pre')
            pre.textContent = JSON.stringify(JSON.parse(text), null, '  ')
            td.textContent = ""
            td.appendChild(pre)

        return td

    serialize: ->

    update: (resultsets) ->
        @resultsets = resultsets
        while (@element.firstChild)
            @element.removeChild(@element.firstChild)

        toolbar = @element.appendChild(document.createElement('div'))
        toolbar.classList.add('toolbar')

        element = @element
        element.style.display = 'block'

        # CLOSE
        close = toolbar.appendChild(document.createElement('div'))
        close.classList.add('tool')
        close.textContent = 'X'
        close.onclick = ->
            element.style.display = 'none'

        # MAXIMIZE
        maximize = toolbar.appendChild(document.createElement('div'))
        maximize.classList.add('tool')
        maximize.textContent = '+'
        maximize.onclick = ->
            element.style['max-height'] = '800px'
            element.style['height'] = '800px'

        # MINIMIZE
        minimize = toolbar.appendChild(document.createElement('div'))
        minimize.classList.add('tool')
        minimize.textContent = '-'
        minimize.onclick = ->
            element.style['height'] = '150px'
            element.style['max-height'] = '150px'

        # RESTORE
        restore = toolbar.appendChild(document.createElement('div'))
        restore.classList.add('tool')
        restore.textContent = '[]'
        restore.onclick = ->
            element.style['max-height'] = '300px'
            element.style['height'] = '300px'

        clear = toolbar.appendChild(document.createElement('div'))
        clear.classList.add('clear')

        i = 0
        for resultset in resultsets
            if atom.config.get('pg-hoff.displayQueryExecutionTime') && !resultset.executing
                time = @element.appendChild(document.createElement('div'))
                time.textContent = resultset.runtime_seconds + ' seconds.'

            @element.appendChild(@createTable(resultset, i))
            i++

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffResultsView
