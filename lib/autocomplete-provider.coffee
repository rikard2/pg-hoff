{CompositeDisposable}   = require 'atom'
PgHoffServerRequest     = require './server-request'
Helper                  = require './helper'

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
        window.lastrun = (new Date()).getTime()
        lastrun_myself = window.lastrun
        dis = @
        retries = 0
        lolz = (time, retries) ->
            return Helper.Timeout(time).then () ->
                if (retries > 100)
                    return
                retries = retries + 1
                if (window.requesting == 1)
                    return lolz(time, retries)
                if window.lastrun == lastrun_myself
                    window.requesting = 0
                    return dis.getSuggestions(options)
                return lolz(time, retries)

        if window.requesting == 1
            return lolz(5, 0)

        if not atom.config.get('pg-hoff.autocompletionEnabled')
            return []
        if not atom.workspace.getActivePaneItem().alias
            console.debug 'The pane has no alias.'
            if alias = atom.config.get('pg-hoff.defaultConnection')
              atom.workspace.getActivePaneItem().alias = alias
            else
              return []

        window.requesting = 1
        text = atom.workspace.getActiveTextEditor().getText()
        before = options.editor.getTextInBufferRange([[0, 0], options.bufferPosition])
        pos = before.length

        request =
            pos: pos
            query: text
            alias: atom.workspace.getActivePaneItem().alias
        return PgHoffServerRequest.Post('completions', request)
            .then (response) ->
                window.requesting = 0
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
                        value.displayText = PgHoffAutocompleteProvider.Pascalize(value.displayText)

                    if unQuoteFunctionNames
                        value.text = PgHoffAutocompleteProvider.UnQuote(value.text)
                        value.displayText = PgHoffAutocompleteProvider.UnQuote(value.displayText)

                    replacementPrefix = switch before[-1..-1]
                        when '*' then '*'
                    longest_parameter_length = null
                    if value.type == 'function'
                        params = value.text.match /\w+\s+:=/g
                        if params
                            matches = params.map (x) -> return x.replace(/\s+:=/, '')
                            longest_parameter_length = Math.max.apply(null, matches.map (x) -> return x.length)

                    value.text = value.text.replace /([(])([_])/g   ,   '$1\n\t$2'
                    value.text = value.text.replace /([}])([)])/g   ,   '$1\n$2'
                    value.text = value.text.replace /([,])\s+([_])/g,   '$1\n\t$2'
                    markdownText = value.text
                    if longest_parameter_length
                        # Align parameters with spaces
                        markdownText = value.text.replace /\w+\s+:=/g, (x) ->
                            y = x.replace(/\s+:=/g, '')
                            return x unless y
                            return y + ' '.repeat(longest_parameter_length - y.length + 1) + ':='
                    suggestion =
                        snippet: value.text
                        displayText: value.displayText
                        iconHTML: iconHTML
                        rightLabel: value.type
                        replacementPrefix: replacementPrefix
                        descriptionMarkdown: '```\n' + markdownText + '\n```' if value.type == 'function' or value.text.length > 60
                        type: type
                    return suggestion
                return suggestions

            .catch (err) ->
                if new RegExp(/ECONNREFUSED/).test(err)
                    console.error 'Cannot autocomplete because of connection refused.'
                else if new RegExp(/Cannot read property/).test(err)
                    console.error 'Cannot autocomplete probably because you are not connected to any servers.'
                    console.debug 'Could be wrong version of pgcli (try pip install pgcli==1.8.1 --force-reinstall)'
                else
                    console.error 'Cannot autocomplete because', err

module.exports = PgHoffAutocompleteProvider
