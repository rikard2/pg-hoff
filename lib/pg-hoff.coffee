PgHoffView                  = require './pg-hoff-view'
PgHoffServerRequest         = require './pg-hoff-server-request'
PgHoffResultsView           = require './pg-hoff-results-view'
PgHoffListServersView       = require './pg-hoff-list-servers-view'
PgHoffQuery                 = require './pg-hoff-query'
PgHoffAutocompleteProvider  = require('./pg-hoff-autocomplete-provider')
{CompositeDisposable, Disposable} = require 'atom'

module.exports = PgHoff =
    provider: null
    pgHoffView: null
    modalPanel: null
    subscriptions: null
    resultsView: null
    resultsViewPanel: null
    listServersView: null
    listServersViewPanel: null

    runningQueries: []

    config:
        host:
            type: 'string'
            default: 'http://localhost:5000'
            order: 1
        pollInterval:
            type: 'integer',
            description: 'Poll interval in milliseconds.'
            minimum: 10
            maximum: 10000
            default: 100
            order: 2
        displayQueryExecutionTime:
            type: 'boolean'
            description: 'Display query execution time after the query is finished.'
            default: true
            order: 3
        autocompletionEnabled:
            type: 'boolean'
            default: true
            order: 4
        pascaliseAutocompletions:
            type: 'boolean'
            default: true
            description: 'user_name becomes User_Name'
            order: 5
        unQuoteFunctionNames:
            type: 'boolean'
            default: true
            description: '"sum"() becomes sum()'
            order: 6
        locale:
            type: 'string'
            default: 'sv-SE'
            order: 7
        executeAllWhenNothingSelected:
            type: 'boolean'
            description: 'Execute all text in editor when no text is selected'
            default: true,
            order: 8
        formatColumns:
            type: 'boolean'
            description: 'This can possibly be slow'
            default: true
            order: 9

    activate: (state) ->
        console.debug 'Activating the greatest plugin ever..'
        @pgHoffView             = new PgHoffView(state.pgHoffViewState)
        @resultsView            = new PgHoffResultsView(state.pgHoffViewState)
        @listServersView        = new PgHoffListServersView(state.pgHoffViewState)

        editor = atom.workspace.getActiveTextEditor()

        @listServersViewPanel = atom.workspace.addModalPanel(item: @listServersView.getElement(), visible: false)
        @resultsViewPanel = atom.workspace.addBottomPanel(item: @resultsView.getElement(), visible: false)

        unless @provider?
            @provider = new PgHoffAutocompleteProvider()

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:connect': => @connect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQuery()

    deactivate: ->
        @subscriptions.dispose()
        @pgHoffView.destroy()
        @resultsView.destroy()
        @listServersView.destroy()

    serialize: ->
        pgHoffViewState: @pgHoffView.serialize()

    provide: ->
        @provider

    connect: ->
        if @listServersViewPanel.isVisible()
            @listServersViewPanel.hide()
            return

        pgHoff = @
        @listServersView.connect(@listServersViewPanel)
            .then (server) ->
                atom.notifications.addSuccess('Connected to ' + server.alias)
            .catch (error) ->
                if error == 'Already connected to server.'
                    atom.notifications.addInfo(error)
                else
                    atom.notifications.addError(error)
            .finally ->
                pgHoff.listServersViewPanel.hide()

    renderResults: (resultsets, pgHoff) ->
        pgHoff.resultsViewPanel.show();
        pgHoff.resultsView.update(resultsets)

    keepGoing: (url, complete, pgHoff) ->
        interval = setInterval( () ->
            return PgHoffServerRequest.Get(url, false)
                .then (resultsets) ->
                    i = 0
                    for resultset in resultsets
                        if resultset.error
                            complete[i] = true
                            atom.notifications.addError(resultset.error)
                        else
                            if resultset.executing
                                complete[i] = false
                            else
                                if complete[i] == false
                                    complete[i] = true
                        i++

                    pgHoff.renderResults(resultsets, pgHoff)
                    if !complete.some( (val) -> return val == false )
                        clearInterval(interval)

                .catch (err) ->
                    console.error 'catch', err
                    clearInterval(interval)
                    atom.notifications.addError(err)
        , atom.config.get('pg-hoff.pollInterval'))

    executeQuery: ->
        selectedText = atom.workspace.getActiveTextEditor().getSelectedText().trim()
        pgHoff = @
        if selectedText.trim().length == 0
            if atom.config.get('pg-hoff.executeAllWhenNothingSelected')
                selectedText = atom.workspace.getActiveTextEditor().getText().trim()
            else
                pgHoff.resultsViewPanel.hide()
                return

        PgHoffQuery.Execute(selectedText)
            .then (result) ->
                complete = []
                queryStillExecuting = false
                for resultset in result.resultsets
                    if resultset.error
                        complete.push(true)
                        atom.notifications.addError(resultset.error)
                    else
                        if resultset.executing
                            complete.push(false)
                            queryStillExecuting = true
                        else
                            complete.push(true)
                if queryStillExecuting
                    pgHoff.keepGoing(result.url, complete, pgHoff)

                pgHoff.renderResults(result.resultsets, pgHoff)
            .catch (err) ->
                pgHoff.resultsViewPanel.hide()
                atom.notifications.addError(err)
