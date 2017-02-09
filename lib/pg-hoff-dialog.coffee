SelectListView = require 'atom-select-list'

class PgHoffDialog
    modalPanel: null
    listView: null
    constructor: (serializedState) ->
    serialize: ->
    destroy: ->

    @PromptList: (items, elementForItem) =>
        return new Promise((fulfil, reject) ->
            config =
                items: [{name: 'LF', value: '\n'}, {name: 'CRLF', value: '\r\n'}],
                filterKeyForItem: (lineEnding) =>
                    lineEnding.name
                didConfirmSelection: (item) =>
                    @modalPanel.hide()
                    fulfil(item)
                didCancelSelection: () =>
                    @modalPanel.hide()
                    reject('cancel')
                elementForItem: (item) =>
                    if elementForItem?
                        return elementForItem(item)
                    else
                        element = document.createElement('li')
                        element.textContent = item.name
                        return element

            @lineEndingListView = new SelectListView(config);
            @modalPanel = atom.workspace.addModalPanel({item: @lineEndingListView})
            @lineEndingListView.reset()
            @modalPanel.show()
            @lineEndingListView.focus()
        )

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
