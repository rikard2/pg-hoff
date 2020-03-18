PgHoffServerRequest = require './server-request'

class DBQuery
    constructor: (@query, @alias, @options) ->

    execute: () ->
        @options = @options || {}

        options = Object.assign(
            {
                cursor_pos: null,
                onPartialQueryStatus: (data) => console.log 'onQueryStatus',   data if @options.verbose,
                onQuery:              (data) => console.log 'onQuery',         data if @options.verbose,
                onQueryStatus:        (data) => console.log 'onQueryStatus',   data if @options.verbose,
                onQueryError:         (data) => console.log 'onQueryError',    data if @options.verbose,
                onError:              (data) => console.log 'onError',         data if @options.verbose,
                onPartialResult:      (data) => console.log 'onPartialResult', data if @options.verbose,
                onResult:             (data) => console.log 'onResult',        data if @options.verbose,
                onResultStatus:       (data) => console.log 'onResultStatus',  data if @options.verbose,
                onAllResults:         (data) => console.log 'onAllResults',    data if @options.verbose,
                onQueryPlan:          (data) => console.log 'onQueryPlan',     data if @options.verbose,
                onCompletion:         (data) => console.log 'onCompletion',    data if @options.verbose
            },
            @options
        )

        request =
            query: @query
            alias: @alias
            cursor_pos: options.cursor_pos

        return PgHoffServerRequest.Post('query', request)
            .then (response) ->
                if response.statusCode == 500
                    options.onError({ errorCode: "QUERY_STATUS_CODE_500" })
                else if not response.success && response.errormessage
                    options.onError({ errorCode: "UNKOWN_ERROR", errorMessage: response.errormessage })
                else if not response.success
                    options.onError({ errorCode: "LOST_CONNECTION" })
                else
                    return response
            .then (response) =>
                timeout = (ms) ->
                    return new Promise((fulfil) ->
                        setTimeout(() ->
                            fulfil()
                        , ms)
                    )
                options.onQuery({

                })
                first = true
                gotResults = false
                gotErrors = false
                gotNotices = false
                newBatch = true
                rowcount = null
                NumberOfQueries = response.queryids.length

                return unless response.queryids.length >= 1
                queryCount = response.queryids.length

                getResult = (queryid) =>
                    if not queryid?
                        queryid = response.queryids.shift()
                    url = 'query_status/' + queryid
                    return PgHoffServerRequest.Get(url, true)
                        .then (result) =>
                            options.onPartialQueryStatus({
                                newBatch: newBatch,
                                queryNumber: NumberOfQueries - response.queryids.length,
                                result: result
                            })
                            if not result.complete
                                newBatch = false
                                return timeout(100)
                                    .then () ->
                                        return getResult(queryid)
                            else
                                return result

                boom = () =>
                    return getResult()
                        .then (result) =>
                            gotResults = true if result.has_result
                            gotNotices = true if result.has_notices

                            if queryCount == 1 and result.has_queryplan
                                gotQueryplan = true
                            currentpage = 0
                            pagesize = 10000
                            options.onQueryStatus({
                                queryCount: queryCount,
                                gotResults: true if result.has_result,
                                gotNotices: true if result.has_notices,
                                hasQueryPlan: result.has_queryplan,
                                result: result
                            })
                            url = 'result/' + result.queryid + '/'
                            fetchPartialResult = () =>
                                return PgHoffServerRequest.Get(
                                    url + currentpage + '/' + (currentpage + pagesize),
                                    true
                                )
                                .then (result) =>
                                    if result.errormessage?
                                        options.onError({
                                            errorCode: 'UNKOWN_ERROR',
                                            errorMessage: result.errormessage
                                        })

                                    errors: true if result.error? and not result.error.match /can\'t execute an empty query/

                                    if result.error?
                                        if result.error == 'connection already closed'
                                            options.onError({
                                                errorCode: 'CONNECTION_ALREADY_CLOSED'
                                            })
                                        else:
                                            options.onQueryError(result)

                                    if  result.rowcount > 0 and currentpage + pagesize < result.rowcount
                                        options.onPartialResult({
                                            queryCount: queryCount,
                                            rowCount: result.rowcount,
                                            result: result
                                        })
                                        return fetchPartialResult()
                                    else
                                        #if gotQueryplan
                                        #    options.onQueryPlan({
                                        #        queryPlan: result.rows
                                        #    })
                                        options.onResult({
                                            gotQueryplan: gotQueryplan,
                                            result: result
                                        })

                                        if response.queryids.length > 0
                                            return boom()

                                        return result
                                .catch (err) ->
                                    console.log err
                                    throw err

                            first = false
                            return fetchPartialResult()

                return boom()
                    .then (result) =>
                        options.onAllResults({
                            gotErrors: gotErrors,
                            gotResults: gotResults,
                            gotNotices: gotResults
                        })
            .catch (err) =>
                options.onError({
                    errorCode: err,
                    errorMessage: err
                })
            .finally =>
                options.onCompletion({
                })

module.exports = DBQuery
