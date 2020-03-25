{CompositeDisposable}   = require 'atom'
TableView               = hrequire '/slickgrid/table-view'
SlickFormatting         = hrequire '/slickgrid/formatting'
Helper                  = hrequire '/helper'
DBQuery                 = hrequire '/dbquery'
ResultsPaneItem         = hrequire '/pane-items/results'

{View, $}               = require 'space-pen'
module.exports          = class QuickQuery
    subscriptions: null
    modal: null
    @QuickQuerys: []

    @Show: (sql, alias) ->
        d = new DBQuery(sql, alias)
        subscriptions = new CompositeDisposable

        d.executePromise()
            .then (r) =>
                return new Promise((fulfil, reject) =>
                    element = document.createElement('div')
                    element.classList.add('native-key-bindings')
                    header = document.createElement('div')
                    resizer = document.createElement('div')
                    element.appendChild(header)

                    p = hrequire('/pane-items/results')
                    resultsPane = new p()

                    dragElement = (elmnt) =>
                        pos1 = 0
                        pos2 = 0
                        pos3 = 0
                        pos4 = 0

                        dragMouseDown = (e) ->
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
                          element.style.top = element.offsetTop - pos2 + 'px'
                          element.style.left = element.offsetLeft - pos1 + 'px'
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

                    initDrag = (e) =>
                        @startX = e.clientX
                        @startY = e.clientY
                        @startWidth = parseInt(document.defaultView.getComputedStyle(element).width, 10)
                        @startHeight = parseInt(document.defaultView.getComputedStyle(element).height, 10)
                        document.documentElement.addEventListener 'mousemove', doDrag, false
                        document.documentElement.addEventListener 'mouseup', stopDrag, false
                        return

                    doDrag = (e) =>
                        element.style.width = @startWidth + e.clientX - @startX + 'px'
                        element.style.height = @startHeight + e.clientY - @startY + 'px'
                        return

                    stopDrag = (e) =>
                        document.documentElement.removeEventListener 'mousemove', doDrag, false
                        document.documentElement.removeEventListener 'mouseup', stopDrag, false
                        resultsPane.refresh()
                        return

                    element.style['width'] = '40%'
                    element.style['height'] = '636px'
                    element.style['transition'] = 'height 0.4s cubic-bezier(0.22, 0.61, 0.36, 1)'
                    element.style['font-family'] = 'Menlo'
                    element.style['overflow-x'] = 'scroll !important'
                    element.style['overflow-y'] = 'hidden !important'
                    element.style['border'] = '1 px solid rgb(22, 22, 22) !important'
                    element.style['position'] = 'absolute'
                    element.style['background'] = 'rgb(22, 22, 22)'
                    element.style['white-space'] = 'pre'
                    element.style['top'] = '323px'
                    element.style['left'] = '863px'
                    element.style['border'] = '1px solid #151515'

                    element.wrap = 'soft'

                    header.style['height'] = '14px'
                    header.style['cursor'] = 'move'
                    header.style['background'] = 'rgb(65, 65, 65)'

                    resizer.style['height'] = '10px'
                    resizer.style['cursor'] = 'nwse-resize'

                    maxZ = 10
                    for q in @QuickQuerys
                        if Number(q.element.style['z-index']) > maxZ
                            maxZ = Number(q.element.style['z-index'])
                        q.header.style['background'] = 'rgb(30, 30, 30)'
                        q.element.style['border'] = '1px solid #101010'
                    element.style['z-index'] = maxZ + 1

                    @QuickQuerys.push {element: element, header: header}

                    element.addEventListener 'click', () =>
                        maxZ = 0
                        for q in @QuickQuerys
                            if Number(q.element.style['z-index']) > Number(element.style['z-index'])
                                if Number(q.element.style['z-index']) > maxZ
                                    maxZ = Number(q.element.style['z-index'])
                                q.element.style['z-index'] = Number(q.element.style['z-index']) - 1
                                q.header.style['background'] = 'rgb(30, 30, 30)'
                                q.element.style['border'] = '1px solid #101010'
                        if maxZ > 0
                            element.style['z-index'] = maxZ
                        header.style['background'] = 'rgb(65, 65, 65)'
                        element.style['border'] = '1px solid #151515'

                    oldSize = 636
                    header.addEventListener 'dblclick', () =>
                        if Number(element.style['height'].substring(0, element.style['height'].length - 2)) > 14
                            oldSize = Number(element.style['height'].substring(0, element.style['height'].length - 2))
                            element.style['height'] = '0px'
                            #$(element).css({opacity: 0.0, visibility: "hidden"}).animate({opacity: 1.0}, 200));

                        else
                            element.style['height'] = oldSize + 'px'

                    element.classList.add 'force-select'
                    resultsPane.id = Helper.GenerateUUID()

                    element.appendChild(resultsPane.element)
                    resizer.addEventListener('mousedown', initDrag, false);
                    element.appendChild(resizer)
                    atom.workspace.element.appendChild(element)
                    resultsPane.render(r.result)
                    dragElement header
                    element.parentElement.style['min-width'] = '100em'

                    resultsPane.focusFirstResult()

                    subscriptions.add atom.commands.add 'atom-text-editor', 'core:copy', (e) ->
                        e.stopImmediatePropagation()

                    subscriptions.add atom.commands.add('body', {
                        'core:cancel': (event) =>
                            subscriptions.dispose()
                            maxZ = 0
                            for q in @QuickQuerys
                                if Number(q.element.style['z-index']) > maxZ
                                    maxZ = Number(q.element.style['z-index'])
                            q.element.remove() for q in @QuickQuerys when Number(q.element.style['z-index']) == maxZ
                            @QuickQuerys = (q for q in @QuickQuerys when Number(q.element.style['z-index']) != maxZ)
                            for q in @QuickQuerys when Number(q.element.style['z-index']) == maxZ-1
                                q.header.style['background'] = 'rgb(65, 65, 65)'
                                q.element.style['border'] = '1px solid #151515'
                            event.stopPropagation()
                            event.stopImmediatePropagation()
                            atom.workspace.getActiveTextEditor().focus
                    })
                )
            .catch (x) ->
                console.log 'catch', x
