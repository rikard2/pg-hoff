request = require('request')
Promise = require('promise')
Type = require('./pg-hoff-types').Type

class PgHoffResultsView
    # There are only two rules of PgHoffResultsView...
    # 1. It should update @element on update(resultsets)
    # 2. Never remove @element from DOM

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add('pg-hoff-results-view')
        @element.setAttribute('tabindex', -1)
        @element.classList.add('native-key-bindings')

    resultsets: []
    pinnedResultsets: []
    selectedIndex: 0

    getCompare: (typeName, asc, colIdx) ->
        defaultCompare = (left, right) ->
            switch
                when left is null and right is null then 0
                when left is null then 1
                when right is null then -1
                else +(left > right) || - (right > left)
        compare = Type[typeName]?.compare || defaultCompare
        (left, right) -> compare(left[colIdx], right[colIdx]) * if asc then 1 else -1 ? 0

    sort: (resultset, columnIndex) ->
        ascending = +resultset.columns[columnIndex].ascending = !resultset.columns[columnIndex].ascending
        typeName = resultset.columns[columnIndex].type
        compare = @getCompare(typeName, ascending, columnIndex)
        resultset.rows.sort compare

    createTabs: (resultsets) ->
        tabContainer = document.createElement 'div'
        tabContainer.classList.add 'tab-container'

        tabs = tabContainer.appendChild document.createElement('ul')
        tabs.classList.add 'tab-bar'
        tabs.classList.add 'list-inline'

        area = tabContainer.appendChild document.createElement('div')
        area.classList.add 'tab-area'

        dis = @
        for resultset, i in resultsets
            tab = tabs.appendChild @createTab(resultset)
            tab.setAttribute 'index', i
            tab.onclick = (e) =>
                index = parseInt(e.target.getAttribute('index'))
                @selectTab(index)

        clear = tabs.appendChild document.createElement('div')
        clear.classList.add 'clear'

        return tabContainer

    createTab: (resultset) ->
        tab = document.createElement 'li'
        tab.classList.add 'tab'
        tab.classList.add 'notices'
        title = tab.appendChild document.createElement('div')
        title.classList.add 'title'

        attachIcon = tab.appendChild document.createElement('div')
        attachIcon.classList.add 'close-icon'
        attachIcon.classList.add 'pin-icon'

        closeIcon = tab.appendChild document.createElement('div')
        closeIcon.classList.add 'close-icon'

        if resultset.statusmessage?
            title.textContent = resultset.statusmessage

        return tab

    selectTab: (index) ->
        console.log 'selecttab', index
        resultset = @resultsets[index]
        @selectedIndex = index
        area = @element.children[1].children[1]
        for t, i in @element.children[1].children[0].children
            t.classList.remove 'active'
            if i == index
                t.classList.add 'active'

        if area.children.length > 0
            area.removeChild area.firstChild

        if resultset
            area.appendChild @createTable(resultset, index)

    createTable: (x, resultsetIndex) ->
        container = document.createElement('div')
        container.classList.add('table')
        container.classList.add('executing')

        if x.notices?.length > 0
            for n in x.notices
                notice = container.appendChild document.createElement('div')
                notice.classList.add 'notice'
                notice.textContent = n

        table = container.appendChild(document.createElement('table'))

        # Header columns
        if x.columns?
            col_tr = table.appendChild(document.createElement('tr'))
            for c, i in x.columns
                col_tr.appendChild(@createTh(c, resultsetIndex, i))

        # Rows
        if x.rows?
            for r in x.rows
                row_tr = table.appendChild(document.createElement('tr'))
                for c, i in r
                    row_tr.appendChild(@createTd(c, x.columns[i].type))

        return container

    createTh: (col, resultsetIndex, columnIndex) ->
        th = document.createElement('th')
        th.textContent = col.name
        th.setAttribute 'title', col.type
        th.textContent += if @resultsets[resultsetIndex].columns[columnIndex].ascending then ' +' else ' -' ? ''

        th.onclick = =>
            @sort @resultsets[resultsetIndex], columnIndex
            @update(@resultsets)

        return th

    createTd: (text, typeName) ->
        td = document.createElement('td')
        if text is null
            td.className = 'null'
            td.textContent =atom.config.get('pg-hoff.nullString')
        else
            td.className = typeName + '_' + text if typeName == 'boolean'
            try
                td.textContent = @cellText(text, typeName)
            catch err
                console.error 'Could not format as ' + typeName, text
        td.setAttribute 'title', text
        return td

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

    update: (resultsets, newQuery) ->
        if newQuery
            @selectedIndex = 0

        @resultsets = resultsets
        while (@element.firstChild)
            @element.removeChild(@element.firstChild)

        resizeHandle = @element.appendChild document.createElement('div')
        resizeHandle.classList.add('resize-handle')
        resizeHandle.addEventListener 'mousedown', (e) => @resizeStarted(e)

        @element.style.display = 'block'

        @element.appendChild @createTabs(resultsets)
        @selectTab(@selectedIndex)

    resizeStarted: (mouseEvent) ->
        @startY = mouseEvent.pageY
        @startHeight = @element.clientHeight

        @moveHandler = (mouseEvent) =>
            deltaY = @startY - mouseEvent.pageY
            height = @startHeight + deltaY
            if height >= 100
                @element.style.height = height + 'px'
                area = @element.children[1].children[1]
                if area?
                    area.style.height = (height - 36 - 11) + 'px'

        @stopHandler = (mouseEvent) =>
            document.body.removeEventListener 'mousemove', @moveHandler
            document.body.removeEventListener 'mouseup', @stopHandler

        document.body.addEventListener 'mousemove', @moveHandler
        document.body.addEventListener 'mouseup', @stopHandler

    createToolbar: ->
        toolbar = document.createElement('div')
        toolbar.classList.add('toolbar')

        element = @element

        close = toolbar.appendChild(document.createElement('div'))
        close.classList.add('tool')
        close.textContent = 'X'
        close.onclick = =>
            element.style.display = 'none'

        maximize = toolbar.appendChild(document.createElement('div'))
        maximize.classList.add('tool')
        maximize.textContent = '+'
        maximize.onclick = =>
            element.style['height'] = '800px'

        minimize = toolbar.appendChild(document.createElement('div'))
        minimize.classList.add('tool')
        minimize.textContent = '-'
        minimize.onclick = ->
            element.style['height'] = '150px'

        # RESTORE
        restore = toolbar.appendChild(document.createElement('div'))
        restore.classList.add('tool')
        restore.textContent = '[]'
        restore.onclick = ->
            element.style['height'] = '300px'

        clear = toolbar.appendChild(document.createElement('div'))
        clear.classList.add('clear')

        return toolbar

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffResultsView
