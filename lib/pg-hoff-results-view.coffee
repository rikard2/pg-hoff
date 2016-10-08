request = require('request')
Promise = require('promise')

class PgHoffResultsView
    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add('pg-hoff-results-view')

    createTable: (x) ->
        container = document.createElement('div')
        container.classList.add('table')

        if x.executing
            pre = container.appendChild(document.createElement('pre'))
            pre.textContent = 'Executing for ' + x.runtime_seconds + ' seconds...'
            container.classList.add('executing')
            return container
        # select pg_sleep(5), 2356 as number

        table = container.appendChild(document.createElement('table'))

        # Header columns
        col_tr = table.appendChild(document.createElement('tr'))
        for c in x.columns
            col_tr.appendChild(@createTh(c.name))

        # Rows
        for r in x.rows
            row_tr = table.appendChild(document.createElement('tr'))
            i = 0
            for c in r
                row_tr.appendChild(@createTd(c, x.columns[i].type_code))
                i = i + 1

        return container

    createTh: (text) ->
        th = document.createElement('th')
        th.textContent = text
        return th

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
            element.style['max-height'] = '100%'
            element.style['height'] = '100%'

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

        for resultset in resultsets
            if atom.config.get('pg-hoff.displayQueryExecutionTime') && !resultset.executing
                time = @element.appendChild(document.createElement('div'))
                time.textContent = resultset.runtime_seconds + ' seconds.'

            @element.appendChild(@createTable(resultset))

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffResultsView
