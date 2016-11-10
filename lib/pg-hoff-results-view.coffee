request = require('request')
Promise = require('promise')
PgHoffTable = require('./pg-hoff-table')
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
    selection: null

    onCopy: () ->
        if @selection?
            atom.clipboard.write @selection.map( (z) -> return z.value).join(', ')

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
        attachIcon.setAttribute 'tab-index',
        attachIcon.classList.add 'close-icon'
        attachIcon.classList.add 'pin-icon'
        attachIcon.onclick = (e) =>
            if attachIcon.classList.contains('pinned')
                e.target.classList.remove 'pinned'
            else
                e.target.classList.add 'pinned'

        closeIcon = tab.appendChild document.createElement('div')
        closeIcon.classList.add 'close-icon'

        if resultset.statusmessage?
            title.textContent = resultset.statusmessage

        if resultset.executing
            title.textContent = 'Executing...'

        return tab

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
            table = new PgHoffTable(resultset)
            table.onSelection = (selection) =>
                @selection = selection
            area.appendChild table.getElement()

    @SelectedAreas: []
    @GetSelectedCells: () ->
        return PgHoffResultsView.SelectedAreas

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
