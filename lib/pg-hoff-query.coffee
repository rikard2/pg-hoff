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
                return {
                    'queryids': response.queryids
                }

    @Timeout = (ms) ->
        return new Promise((fulfil) ->
            setTimeout(() ->
                fulfil()
            , ms)
        )
    @ExecuteOne: (queryid, update) ->
        url = 'result/' + queryid
        "localhost:5000/result/7be286e8-c11f-11e6-b4f1-38c986408e3f"
        console.log 'url', url
        return PgHoffServerRequest
            .Get(url)
            .then (response) ->
                console.log 'first', response
                if response.statusCode == 500
                    throw("/query status code 500")

                return response
            .then (response) ->
                console.log 'response', response
                update(response)
                if response.complete
                    return response
                else
                    return PgHoffQuery
                        .Timeout(100)
                        .then (response) =>
                            return PgHoffQuery.ExecuteOne(queryid, update)
                            .then (resultset) =>
                                return resultset
                console.error 'WTF, what happens now???'
                throw 'WTF, why no excecuting?'

module.exports = PgHoffQuery
