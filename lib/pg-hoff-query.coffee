PgHoffServerRequest = require './pg-hoff-server-request'

class PgHoffQuery
    constructor: (serializedState) ->
    serialize: ->
    destroy: ->

    @Execute: (query) ->
        request =
            query: query
            alias: atom.workspace.getActivePaneItem().alias

        url = null
        return PgHoffServerRequest
            .Post('query', request)
            .then (response) ->
                if response.statusCode == 500
                    throw("/query status code 500")
                else if not response.success && response.errormessage
                    throw(response.errormessage)
                else if not response.success
                    throw("Lost connection. Try again!")

                return response
            .then (response) ->
                url = response.Url
                return PgHoffServerRequest.Get(url, false)
            .then (resultsets) ->
                return {
                    'url': url
                    'resultsets': resultsets
                }

module.exports = PgHoffQuery
