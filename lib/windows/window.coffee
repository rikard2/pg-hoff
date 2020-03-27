{CompositeDisposable}   = require 'atom'

module.exports = class HoffWindow
    element: null
    @QuickQuerys: []
    header: null
    resizer: null
    options: {}

    constructor: (options) ->
        @options = Object.assign(options || {}, {
            title: 'hello there'
        })
        @subscriptions = new CompositeDisposable()

    show: (@element) =>
        @windowElement = document.createElement('div')
        @windowElement.classList.add('native-key-bindings')

        @header = @windowElement.appendChild document.createElement('div')
        @windowElement.appendChild @element
        @resizer = @windowElement.appendChild document.createElement('div')

        @windowElement.style['min-width'] = '300px'
        @windowElement.style['min-height'] = '225px'
        @windowElement.style['transition'] = 'height 0.4s cubic-bezier(0.22, 0.61, 0.36, 1)'
        @windowElement.style['font-family'] = 'Menlo'
        @windowElement.style['overflow-x'] = 'scroll !important'
        @windowElement.style['overflow-y'] = 'hidden !important'
        @windowElement.style['border'] = '1 px solid rgb(22, 22, 22) !important'
        @windowElement.style['position'] = 'absolute'
        @windowElement.style['background'] = 'rgb(22, 22, 22)'
        @windowElement.style['white-space'] = 'pre'
        @windowElement.style['top'] = '323px'
        @windowElement.style['left'] = '863px'
        @windowElement.style['border'] = '1px solid #151515'

        @windowElement.wrap = 'soft'

        @header.style['height'] = '18px'
        @header.style['cursor'] = 'move'
        @header.style['background'] = 'rgb(65, 65, 65)'
        @header.style['padding'] = '2px'
        @header.style['text-align'] = 'center'

        @resizer.style['z-index'] = '9999'
        @resizer.style['width'] = '14px'
        @resizer.style['height'] = '17px'
        @resizer.style['bottom'] = '0px'
        @resizer.style['right'] = '0'
        @resizer.style['position'] = 'absolute'
        @resizer.style['cursor'] = 'nwse-resize'
        i = document.createElement('span')
        i.classList.add('icon')
        i.classList.add('icon-alignment-align')
        @resizer.appendChild i

        @windowElement.classList.add 'force-select'

        containerElement = document.createElement('div')
        containerElement.style.width = '100%'
        containerElement.style.height = '100%'
        #containerElement.style.position = 'relative'
        containerElement.appendChild(@element)
        console.log 'initDrag', @initDrag
        @resizer.addEventListener('mousedown', @initDrag, false);
        containerElement.appendChild(@resizer)
        @windowElement.appendChild(containerElement)
        atom.workspace.element.appendChild(@windowElement)
        console.log('@windowElement', @windowElement)
        @dragElement @windowElement, @header
        @windowElement.parentElement.style['min-width'] = '100em'

        maxZ = 10
        for q in HoffWindow.QuickQuerys
            if Number(q.element.style['z-index']) > maxZ
                maxZ = Number(q.element.style['z-index'])
            q.header.style['background'] = 'rgb(30, 30, 30)'
            q.element.style['border'] = '1px solid #101010'
        @windowElement.style['z-index'] = maxZ + 1

        HoffWindow.QuickQuerys.push {element: @windowElement, header: @header}

        @windowElement.addEventListener 'click', () =>
            maxZ = 0
            for q in HoffWindow.QuickQuerys
                if Number(q.element.style['z-index']) > Number(@windowElement.style['z-index'])
                    if Number(q.element.style['z-index']) > maxZ
                        maxZ = Number(q.element.style['z-index'])
                    q.element.style['z-index'] = Number(q.element.style['z-index']) - 1
                    q.header.style['background'] = 'rgb(30, 30, 30)'
                    q.element.style['border'] = '1px solid #101010'
            if maxZ > 0
                element.style['z-index'] = maxZ
            @header.style['background'] = 'rgb(65, 65, 65)'
            @windowElement.style['border'] = '1px solid #151515'

        oldSize = 636
        @header.addEventListener 'dblclick', () =>
            if Number(@windowElement.style['height'].substring(0, @windowElement.style['height'].length - 2)) > 14
                oldSize = Number(@windowElement.style['height'].substring(0, @windowElement.style['height'].length - 2))
                @windowElement.style['height'] = '0px'
                #$(element).css({opacity: 0.0, visibility: "hidden"}).animate({opacity: 1.0}, 200));

            else
                @windowElement.style['height'] = oldSize + 'px'

        @windowElement.classList.add 'force-select'

        @subscriptions.add atom.commands.add 'atom-text-editor', 'core:copy', (e) ->
            e.stopImmediatePropagation()

        @subscriptions.add atom.commands.add('body', {
            'core:cancel': (event) =>
                @subscriptions.dispose()
                maxZ = 0
                for q in HoffWindow.QuickQuerys
                    if Number(q.element.style['z-index']) > maxZ
                        maxZ = Number(q.element.style['z-index'])
                q.element.remove() for q in HoffWindow.QuickQuerys when Number(q.element.style['z-index']) == maxZ
                HoffWindow.QuickQuerys = (q for q in HoffWindow.QuickQuerys when Number(q.element.style['z-index']) != maxZ)
                for q in HoffWindow.QuickQuerys when Number(q.element.style['z-index']) == maxZ-1
                    q.header.style['background'] = 'rgb(65, 65, 65)'
                    q.element.style['border'] = '1px solid #151515'
                event.stopPropagation()
                event.stopImmediatePropagation()
                atom.workspace.getActiveTextEditor().focus
        })

        @setTitle(@options.title) if @options.title?

    setTitle: (title) ->
        @header.textContent = title

    initDrag: (e) =>
        console.log 'initdrag'
        @startX = e.clientX
        @startY = e.clientY
        @startWidth = parseInt(document.defaultView.getComputedStyle(@windowElement).width, 10)
        @startHeight = parseInt(document.defaultView.getComputedStyle(@windowElement).height, 10)
        document.documentElement.addEventListener 'mousemove', @doDrag, false
        document.documentElement.addEventListener 'mouseup', @stopDrag, false
        return

    doDrag: (e) =>
        @windowElement.style.width = @startWidth + e.clientX - @startX + 'px'
        @windowElement.style.height = @startHeight + e.clientY - @startY + 'px'
        return

    stopDrag: (e) =>
        document.documentElement.removeEventListener 'mousemove', @doDrag, false
        document.documentElement.removeEventListener 'mouseup', @stopDrag, false
        return

    dragElement: (wElement, elmnt) =>
        console.log 'dragElement', wElement
        pos1 = 0
        pos2 = 0
        pos3 = 0
        pos4 = 0

        dragMouseDown = (e) =>
          e = e or window.event
          e.preventDefault()
          # get the mouse cursor position at startup:
          pos3 = e.clientX
          pos4 = e.clientY
          document.onmouseup = closeDragElement
          # call a function whenever the cursor moves:
          document.onmousemove = elementDrag
          return

        elementDrag = (e) =>
          e = e or window.event
          e.preventDefault()
          # calculate the new cursor position:
          pos1 = pos3 - (e.clientX)
          pos2 = pos4 - (e.clientY)
          pos3 = e.clientX
          pos4 = e.clientY
          # set the element's new position:
          console.log 'windowElement', wElement
          wElement.style.top = wElement.offsetTop - pos2 + 'px'
          wElement.style.left = wElement.offsetLeft - pos1 + 'px'
          return

        closeDragElement = ->
            # stop moving when mouse button is released:
            document.onmouseup = null
            document.onmousemove = null
            return

        if document.getElementById(elmnt.id + 'header')
          # if present, the header is where you move the DIV from:
          document.getElementById(elmnt.id + 'header').onmousedown = dragMouseDown
        else
          # otherwise, move the DIV from anywhere inside the DIV:
          elmnt.onmousedown = dragMouseDown
        return
