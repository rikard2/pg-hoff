TableView       = require('../slickgrid/table-view')
SlickFormatting = require('../slickgrid/formatting')
Helper          = require('../helper')
DBQuery         = require('../dbquery')
ResultsPaneItem = require('../pane-items/results')
{View, $}       = require 'space-pen'
module.exports = class QuickQuery
    @Show: (sql, alias) ->
        d = new DBQuery(sql, alias)

        d.executePromise()
            .then (r) ->
                return new Promise((fulfil, reject) ->
                    element = document.createElement('div')
                    element.classList.add('hoff-dialog')
                    element.classList.add('native-key-bindings')
                    element.classList.add('gulp-pane')

                    resultsPane = new ResultsPaneItem

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
                    resultsPane.render(r.result)
                    element.appendChild(resultsPane.element)

                    modal = atom.workspace.addModalPanel(item: element, visible: true)
                    element.parentElement.style['min-width'] = '100em'
                    console.log 'minWidth', element.parentElement

                    atom.commands.add('body', {
                        'core:cancel': (event) =>
                            console.log 'cancel'
                            modal.destroy()
                            event.stopPropagation()
                    })
                    resultsPane.focusFirstResult()
                    element.focus()
                    element.addEventListener 'blur', () ->
                        console.log 'blur'
                        modal.destroy()
                )
            .catch (x) ->
                console.log 'catch', x
