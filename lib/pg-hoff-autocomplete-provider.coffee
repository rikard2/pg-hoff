Promise = require('promise')
PgHoffServerRequest = require './pg-hoff-server-request'
{CompositeDisposable} = require 'atom'

class PgHoffAutocompleteProvider
    selector: '.source.sql'
    constructor: () ->

    getSuggestions: (options) ->
        suggestions = []

        text = atom.workspace.getActiveTextEditor().getText()
        before = options.editor.getTextInBufferRange([[0, 0], options.bufferPosition])
        pos = before.length

        request =
            pos: pos
            query: text

        return PgHoffServerRequest.Post('completions', request)
            .then (response) ->
                suggestions = response.map (value) ->
                    suggestion =
                        text: value
                        displayText: value
                        rightLabel: 'table'
                        type: 'class'
                    return suggestion

                return suggestions

            .catch (err) ->
                console.log 'catch', err

#    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
#        console.log 'onDidInsertSuggestion'

module.exports = PgHoffAutocompleteProvider
