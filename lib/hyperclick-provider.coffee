console.log 'exports'
module.exports =
    priority: 1
    constructed: false
    providerName: "pg-hoff"

    constructor: ->
        console.log 'hoff-hyperclick constructor'

    getSuggestionForWord: (editor, text, range) ->
        console.log 'getSuggestionForWord'
        return {
            range: range,
            callback: () ->
                console.log 'callback'
        }
