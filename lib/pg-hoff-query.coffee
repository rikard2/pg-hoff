PgHoffServerRequest = require './pg-hoff-server-request'

class PgHoffQuery
    constructor: (serializedState) ->
    serialize: ->
    destroy: ->

    @Execute: (query) ->
        request =
            query: query

        url = null
        return PgHoffServerRequest
            .Post('query', request, false)
            .then (response) ->
                if response.statusCode == 500
                    throw("/query status code 500")
                re = new RegExp("([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})$")
                if response == 'not_connected'
                    throw("Connect to a server douchebag (" + atom.keymaps.findKeyBindings(command: 'pg-hoff:connect')[0].keystrokes + ")")
                if !re.test(response)
                    console.error('response', response)
                    throw("/query did not generate a valid response")
                url = response
                return response
            .then (url) ->
                return PgHoffServerRequest.Get(url, false)
            .then (resultsets) ->
                return {
                    'url': url
                    'resultsets': resultsets
                }

module.exports = PgHoffQuery
