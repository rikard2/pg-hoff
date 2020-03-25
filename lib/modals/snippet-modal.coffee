{TextEditor} = require 'atom'
module.exports = class SnippetModal
    @Edit: (snippet) ->
        return new Promise((fulfil, reject) ->
            element = document.createElement('div')
            element.classList.add('hoff-dialog')
            nameTextEditor = new TextEditor({ mini: true })
            sqlTextEditor = new TextEditor({ })

            element.appendChild nameTextEditor.element
            element.appendChild sqlTextEditor.element

            nameTextEditor.setText(snippet.name) if (snippet.name)
            nameTextEditor.element.tabIndex = 1
            sqlTextEditor.setText(snippet.sql) if (snippet.sql)
            nameTextEditor.element.tabIndex = 2

            divElement = element.appendChild document.createElement('div')
            divElement.style['padding'] = '10px'
            divElement.style['white-space'] = 'pre'
            divElement.style['font-family'] = 'Menlo'

            if snippet.replace?
                c = divElement.appendChild document.createElement('div')
                c.innerHTML = 'Column: ' + snippet.column
                a = divElement.appendChild document.createElement('div')
                a.innerHTML = '$IDS$:  ' + snippet.replace.ids
                b = divElement.appendChild document.createElement('div')
                b.innerHTML = '$ID$:   ' + snippet.replace.id

            buttonElement = element.appendChild document.createElement('button')
            buttonElement.classList.add('btn')
            buttonElement.classList.add('btn-primary')
            buttonElement.style['font-size'] = '1.25em'
            buttonElement.style['display'] = 'block'
            buttonElement.innerHTML = 'Save'
            buttonElement.addEventListener('click', () ->
                fulfil({
                    id: snippet.id,
                    column: snippet.column,
                    name: nameTextEditor.getText(),
                    sql: sqlTextEditor.getText()
                })
                modal.destroy()
            )

            modal = atom.workspace.addModalPanel(item: element, visible: true)

            atom.commands.add('body', {
                'core:cancel': (event) =>

                    reject()

                    modal.destroy()
                    event.stopPropagation()
                    event.stopImmediatePropagation()
            })
        )
