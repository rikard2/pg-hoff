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
    subscriptions: null
    resultsView: null
    resultsViewPanel: null
    listServersView: null
    listServersViewPanel: null

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
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQueryWithConnect()

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
        paneItem = atom.workspace.getActivePaneItem()

        if @listServersViewPanel.isVisible()
            @listServersViewPanel.hide()
            return

        pgHoff = @
        return @listServersView.connect(@listServersViewPanel)
            .then (server) =>
                if server.already_connected
                    atom.notifications.addInfo('Using ' + server.alias)
                else
                    atom.notifications.addSuccess('Connected to ' + server.alias)

                paneItem.alias = server.alias
            .catch (error) =>
                atom.notifications.addError(error)
            .finally =>
                @listServersViewPanel.hide()

    renderResults: (resultsets, pgHoff) ->
        @resultsViewPanel.show();
        @resultsView.update(resultsets)

    keepGoing: (url, complete, pgHoff) ->
        interval = setInterval( () =>
            return PgHoffServerRequest.Get(url, false)
                .then (resultsets) =>
                    for resultset, i in resultsets
                        if resultset.error
                            complete[i] = true
                            atom.notifications.addError(resultset.error)
                        else
                            if resultset.executing
                                complete[i] = false
                            else
                                if complete[i] == false
                                    complete[i] = true

                    @renderResults(resultsets, pgHoff)
                    if !complete.some( (val) -> return val == false )
                        clearInterval(interval)

                .catch (err) =>
                    console.error 'catch', err
                    clearInterval(interval)
                    atom.notifications.addError(err)
        , atom.config.get('pg-hoff.pollInterval'))

    executeQueryWithConnect: ->
        if atom.workspace.getActivePaneItem().alias?
            @executeQuery()
        else
            return @connect()?.then =>
                    @executeQuery()
                .catch (err) ->
                    console.error 'Connect error', err
                    atom.notifications.addError('Connect error')

    executeQuery: ->
        selectedText = atom.workspace.getActiveTextEditor().getSelectedText().trim()
        pgHoff = @
        if selectedText.trim().length == 0
            if atom.config.get('pg-hoff.executeAllWhenNothingSelected')
                selectedText = atom.workspace.getActiveTextEditor().getText().trim()
            else
                resultsViewPanel.hide()
                return

        return PgHoffQuery.Execute(selectedText)
            .then (result) =>
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
                    @keepGoing(result.url, complete)

                @renderResults(result.resultsets)
            .catch (err) =>
                atom.workspace.getActivePaneItem().alias = null
                @resultsViewPanel.hide()
                atom.notifications.addError(err)
