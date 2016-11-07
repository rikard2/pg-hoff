class PgHoffDialog
    constructor: (serializedState) ->
    serialize: ->
    destroy: ->

    @Prompt: (text) ->
        return new Promise((fulfil, reject) ->
            element = document.createElement('div')
            element.classList.add('hoff-dialog')
            input = element.appendChild document.createElement('input')
            input.classList.add('native-key-bindings')
            input.type = 'text'
            input.placeholder = text
            modal = atom.workspace.addModalPanel(item: element, visible: true)
            input.focus()
            input.onkeyup = (e) ->
                if e.which == 27
                    modal.hide()
                    reject('escape')
                if e.which == 13
                    modal.hide()
                    fulfil(input.value)
        )

    @PromptPassword: (text) ->
        return new Promise((fulfil, reject) ->
            element = document.createElement('div')
            element.classList.add('hoff-dialog')
            input = element.appendChild document.createElement('input')
            input.classList.add('native-key-bindings')
            input.type = 'password'
            input.placeholder = text
            modal = atom.workspace.addModalPanel(item: element, visible: true)
            input.focus()
            input.onkeyup = (e) ->
                if e.which == 27
                    modal.hide()
                    reject('escape')
                if e.which == 13
                    modal.hide()
                    fulfil(input.value)
        )

module.exports = PgHoffDialog
