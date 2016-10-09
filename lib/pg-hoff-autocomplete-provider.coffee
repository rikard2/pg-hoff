Promise = require('promise')
PgHoffServerRequest = require './pg-hoff-server-request'
{CompositeDisposable} = require 'atom'

class PgHoffAutocompleteProvider
    selector: '.source.sql'
    constructor: () ->

    @Pascalize: (text) ->
        return text
            .replace /^[a-z]/,      (x) -> return x.toUpperCase()
            .replace /[_][a-z]/g,   (x) -> return x.toUpperCase()

    @UnQuote: (text) ->
        return text
            .replace /"([A-Za-z_]+)"\(\)/, "$1()"

    getSuggestions: (options) ->
        if not atom.config.get('pg-hoff.autocompletionEnabled')
            return []

        text = atom.workspace.getActiveTextEditor().getText()
        before = options.editor.getTextInBufferRange([[0, 0], options.bufferPosition])
        pos = before.length

        request =
            pos: pos
            query: text

        return PgHoffServerRequest.Post('completions', request)
            .then (response) ->
                pascalize = atom.config.get('pg-hoff.pascaliseAutocompletions')
                unQuoteFunctionNames = atom.config.get('pg-hoff.unQuoteFunctionNames')
                suggestions = response.map (value) ->
                    type = switch value.type
                        when 'table'        then 'type'
                        when 'function'     then 'function'
                        when 'keyword'      then 'keyword'
                        when 'schema'       then 'import'
                        when 'column'       then 'value' else 'variable'

                    iconHTML = value.type.substr(0, 1).toUpperCase()

                    if pascalize
                        value.displayText = value.text = PgHoffAutocompleteProvider.Pascalize(value.text)

                    if unQuoteFunctionNames
                        value.displayText = value.text = PgHoffAutocompleteProvider.UnQuote(value.text)

                    suggestion =
                        text: value.text
                        displayText: value.text
                        iconHTML: iconHTML
                        rightLabel: value.type
                        #description: 'this would be nice'
                        type: type
                    return suggestion

                return suggestions

            .catch (err) ->
                if new RegExp(/ECONNREFUSED/).test(err)
                    console.error 'Cannot autocomplete because of connection refused.'
                else if new RegExp(/Cannot read property/).test(err)
                    console.error 'Cannot autocomplete probably because you are not connected to any servers.'
                else
                    console.error 'Cannot autocomplete because', err

#    onDidInsertSuggestion: ({editor, triggerPosition, suggestion}) ->
#        console.log 'onDidInsertSuggestion'

module.exports = PgHoffAutocompleteProvider
