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
    @Show: (sql, alias) ->
        d = new DBQuery(sql, alias)
        subscriptions = new CompositeDisposable

        d.executePromise()
            .then (r) =>
                return new Promise((fulfil, reject) =>
                    element = document.createElement('div')
                    element.classList.add('hoff-dialog')
                    element.classList.add('native-key-bindings')
                    element.classList.add('gulp-pane')

                    p = hrequire('/pane-items/results')
                    resultsPane = new p()

                    element.classList.add('native-key-bindings')
                    element.style['overflow'] = 'auto'
                    element.style['width'] = '100%'
                    element.style['height'] = '600px'
                    element.style['font-family'] = 'Menlo'
                    element.style['border'] = 'none'
                    element.style['background'] = 'transparent'
                    element.style['white-space'] = 'pre'
                    element.style['overflow-wrap'] = 'normal'
                    element.style['overflow-x'] = 'scroll'
                    element.wrap = 'soft'


                    element.classList.add 'force-select'
                    resultsPane.id = Helper.GenerateUUID()

                    q = document.createElement('input')
                    q.type = 'text'

                    resultsPane.render(r.result)
                    element.appendChild(q)
                    q.focus()
                    element.appendChild(resultsPane.element)


                    modal = atom.workspace.addModalPanel(item: element, visible: true)
                    element.parentElement.style['min-width'] = '100em'

                    resultsPane.focusFirstResult()

                    subscriptions.add atom.commands.add 'atom-text-editor', 'core:copy', (e) ->
                        e.stopImmediatePropagation()

                    subscriptions.add atom.commands.add('body', {
                        'core:cancel': (event) =>
                            subscriptions.dispose()
                            modal.destroy()
                            event.stopPropagation()
                            event.stopImmediatePropagation()
                            atom.workspace.getActiveTextEditor().focu
                    })
                )
            .catch (x) ->
                console.log 'catch', x
