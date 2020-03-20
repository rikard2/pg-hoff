PgHoffServerRequest = require './server-request'

class PgHoffQuery
    constructor: (serializedState) ->
    serialize: ->
    destroy: ->

    @HoffImport: (hoffimportfile) ->
        request =
            hoffimportfile: hoffimportfile
        return Perform_request('hoff_import', request)

    @Execute: (query, alias) ->
        request =
            query: query
            alias: alias ? atom.workspace.getActivePaneItem().alias
        return @Perform_request('query', request)

    @Perform_request: (path, request) ->
        url = null
        return PgHoffServerRequest
            .Post(path, request)
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
