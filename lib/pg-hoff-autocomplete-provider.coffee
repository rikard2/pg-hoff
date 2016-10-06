{CompositeDisposable} = require 'atom'

module.exports =
class AutocompleteProvider

  constructor: () ->
  selector: '.source.js, .source.coffee'
  inclusionPriority: () ->
    return 10whate
u.userna
  getSuggestionsFromJoins: (beforeDot, afterDot, joins) ->
    suggestions = []
    tables = []

    return new Promise( (fulfill, reject) ->
      suggestions.push({
        text: 'fuckingaye',
        type: 'type'
        rightLabel: 'table' # (optional)
        description: 'dubisteinidiot'
      })

      options =
        method: 'GET',
        url: 'http://localhost:5000/pos/9/query/SELECT%20U.%20FROM%20Users%20U;',
        headers:
          'cache-control': 'no-cache',
          'content-type': 'application/x-www-form-urlencoded'

      request(options, (error, response, body) ->
        array = JSON.parse(body)
        for x in array
          suggestions.push({
            text: x,
            type: 'type'
            rightLabel: 'table' # (optional)
            description: x
          })
        fulfil(suggestions)
      )

      return suggestions
    )
