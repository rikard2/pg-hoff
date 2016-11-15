PgHoffView                  = require './pg-hoff-view'
PgHoffServerRequest         = require './pg-hoff-server-request'
PgHoffResultsView           = require './pg-hoff-results-view'
PgHoffListServersView       = require './pg-hoff-list-servers-view'
PgHoffQuery                 = require './pg-hoff-query'
PgHoffGotoDeclaration       = require './pg-hoff-goto-declaration'
PgHoffAutocompleteProvider  = require('./pg-hoff-autocomplete-provider')
PgHoffDialog                = require('./pg-hoff-dialog')
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
            default: false
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
        defaultConnection:
            type: 'string'
            description: 'Alias of database connection to use for new tabs</br>Leave blank for no automatic connection'
            default: ''
            order: 10
        nullString:
            type: 'string'
            description: 'Representation of null values'
            default: 'NULL'
            order: 11
        startServerAutomatically:
            type: 'boolean'
            description: 'Start server automatically'
            default: true
            order: 1

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
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:goto-declaration': => @gotoDeclaration()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:connect': => @connect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:stop-query': => @stopQuery()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQueryWithConnect()
        @subscriptions.add atom.commands.add '.notices', 'pg-hoff:create-dynamic-table': => @createDynamicTable()

    gotoDeclaration: PgHoffGotoDeclaration

    stopQuery: ->
        alias = atom.workspace.getActivePaneItem().alias
        if alias?
            return PgHoffServerRequest
                .Post('cancel', { alias: alias })
                .then (response) ->
                    console.log 'cancel', response, alias

    createDynamicTable: ->
        alias = atom.workspace.getActivePaneItem().alias
        globalName = null
        PgHoffDialog
            .Prompt('Enter name')
            .then (name) ->
                req =
                    queryid: window.queryId
                    name: name
                globalName = name
                return PgHoffServerRequest.Post('create_dynamic_table', req)
            .then (response) ->
                atom.notifications.addSuccess 'Dynamic query created with name ' + globalName + '.'
            .catch (err) ->
                console.debug 'user aborted prompt'

    connect: ->
        paneItem = atom.workspace.getActivePaneItem()

        if @listServersViewPanel.isVisible()
            @listServersViewPanel.hide()
            return

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

    renderResults: (resultsets, newQuery) ->
        @resultsViewPanel.show();
        @resultsView.update(resultsets, newQuery)

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
        if selectedText.trim().length == 0
            if atom.config.get('pg-hoff.executeAllWhenNothingSelected')
                selectedText = atom.workspace.getActiveTextEditor().getText().trim()
            else
                resultsViewPanel.hide()
                return

        return PgHoffQuery.Execute(selectedText)
            .then (result) =>
                for resultset in result.resultsets
                    if resultset.error
                        atom.notifications.addError(resultset.error)

                allCompleted = result.resultsets.every (resultset) -> return resultset.completed or resultset.error or not resultset.executing
                if not allCompleted
                    @keepGoing(result.url)

                @renderResults(result.resultsets, true)
            .catch (err) =>
                atom.workspace.getActivePaneItem().alias = null
                @resultsViewPanel.hide()
                atom.notifications.addError(err)

    keepGoing: (url, complete) ->
        interval = setInterval( () =>
            return PgHoffServerRequest.Get(url, false)
                .then (resultsets) =>
                    for resultset, i in resultsets
                        if resultset.error
                            atom.notifications.addError(resultset.error)

                    count = resultsets.find (resultset) -> resultset.completed or resultset.error or not resultset.executing
                    if completedCount != count
                        @renderResults(resultsets)
                        completedCount = count

                    allCompleted = resultsets.every (resultset) -> resultset.completed or resultset.error or not resultset.executing
                    if allCompleted
                        clearInterval(interval)

                .catch (err) =>
                    console.error 'catch', err
                    clearInterval(interval)
                    atom.notifications.addError(err)
        , atom.config.get('pg-hoff.pollInterval'))

    deactivate: ->
        @subscriptions.dispose()
        @pgHoffView.destroy()
        @resultsView.destroy()
        @listServersView.destroy()

    serialize: ->
        pgHoffViewState: @pgHoffView.serialize()

    provide: ->
        @provider
