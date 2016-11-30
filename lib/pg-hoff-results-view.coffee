request = require('request')
Promise = require('promise')
Type = require('./pg-hoff-types').Type
{CompositeDisposable, Disposable} = require 'atom'

class PgHoffResultsView
    # There are only two rules of PgHoffResultsView...
    # 1. It should update @element on update(resultsets)
    # 2. Never remove @element from DOM

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add('pg-hoff-results-view')
        @element.setAttribute('tabindex', -1)
        @element.classList.add('native-key-bindings')

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.table', 'pg-hoff:toggle-transpose': (element) => @toggleTranspose(element)

    resultsets: []
    pinnedResultsets: []
    selectedIndex: 0

    toggleTranspose: (event) ->
        table = event.target.closest(".table")
        return unless table?

        index = parseInt table.getAttribute('resultset-index')
        @resultsets[index].transpose = not @resultsets[index].transpose ? false
        @update(@resultsets)

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
        area.style.height = (@element.clientHeight - 36 - 11) + 'px'

        dis = @
        for resultset, i in resultsets
            tab = tabs.appendChild @createTab(resultset, i)
            tab.setAttribute 'index', i
            tab.onclick = (e) =>
                index = parseInt(e.target.getAttribute('index'))
                if e.target.parentElement.classList.contains('tab-bar')
                    @selectTab(index)

        clear = tabs.appendChild document.createElement('div')
        clear.classList.add 'clear'

        return tabContainer

    createTab: (resultset, tabIndex) ->
        tab = document.createElement 'li'
        tab.classList.add 'tab'
        tab.classList.add 'notices'
        title = tab.appendChild document.createElement('div')
        title.classList.add 'title'

        attachIcon = tab.appendChild document.createElement('div')
        attachIcon.classList.add 'close-icon'
        attachIcon.classList.add 'pin-icon'
        attachIcon.onclick = (e) =>
            if attachIcon.classList.contains('pinned')
                e.target.classList.remove 'pinned'
            else
                e.target.classList.add 'pinned'
        attachIcon.style.display = 'none'

        closeIcon = tab.appendChild document.createElement('div')
        closeIcon.classList.add 'close-icon'
        closeIcon.onclick = (e) =>
            tab.style.display = 'none'
            @closedTabs.add tabIndex
            if @tabCount() == 0
                @closeUI()
            else if tabIndex == @selectedIndex
                @selectNearestTab(tabIndex)

        if resultset.statusmessage?
            title.textContent = resultset.statusmessage
            
        if resultset.executing
            title.textContent = 'Executing...'

        return tab

    tabs: ->
        Array.from(@element.children[1].children[0].children)
        .filter((e) -> e.tagName == 'LI')

    selectNearestTab: (index) ->
        tabs = @tabs()
        for t, i in tabs
            if i > index and not @closedTabs.has(i)
                return @selectTab(i)
        for i in [tabs.length-1...-1]
            if not @closedTabs.has(i)
                return @selectTab(i)

    tabCount: ->
        @resultsets.length - @closedTabs.size

    closeUI: ->
        while (@element.firstChild)
            @element.removeChild(@element.firstChild)
        @element.style.display = 'none'

    selectTab: (index) ->
        resultset = @resultsets[index]
        @selectedIndex = index
        area = @element.children[1].children[1]
        for t, i in @element.children[1].children[0].children
            t.classList.remove 'active'
            if i == index
                t.classList.add 'active'
                window.queryId = resultset.queryid

        if area.children.length > 0
            area.removeChild area.firstChild

        if resultset
            area.appendChild @createTable(resultset, index)

    createTable: (x, resultsetIndex) ->
        container = document.createElement('div')
        container.setAttribute 'resultset-index', resultsetIndex

        container.classList.add('table')
        container.classList.add('executing')

        if x.error?
            error = container.appendChild document.createElement('div')
            error.classList.add 'error'
            error.textContent = x.error

        runtime = container.appendChild document.createElement('div')
        runtime.textContent = @resultsets[resultsetIndex].runtime_seconds + ' seconds'
        if x.notices?.length > 0
            for n in x.notices
                notice = container.appendChild document.createElement('div')
                notice.classList.add 'notice'
                notice.textContent = n

        table = container.appendChild(document.createElement('table'))
        if @resultsets[resultsetIndex].transpose
            table.classList.add 'transpose'
            if x.columns?
                for c, i in x.columns
                    col_tr = table.appendChild(document.createElement('tr'))
                    th = @createTh(c, resultsetIndex, i)
                    col_tr.appendChild(th)

                    # Rows
                    if x.rows?
                        for r in x.rows
                            for rc, ri in r
                                if ri == i
                                    td = @createTd(rc, x.columns[ri].type)
                                    col_tr.appendChild(td)
        else
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
        th = document.createElement('td')
        th.classList.add 'header'
        th.textContent = col.name
        th.setAttribute 'title', col.type
        th.textContent += if @resultsets[resultsetIndex].columns[columnIndex].ascending then ' +' else ' -' ? ''

        th.onclick = =>
            @sort @resultsets[resultsetIndex], columnIndex
            @update(@resultsets)

        return th

    createTd: (text, typeName) ->
        td = document.createElement('td')
        td.classList.add 'cell'
        if text is null
            td.classList.add 'null'
            td.textContent =atom.config.get('pg-hoff.nullString')
        else
            td.classList.add typeName + '_' + text if typeName == 'boolean'
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
        @closedTabs = new Set()
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
