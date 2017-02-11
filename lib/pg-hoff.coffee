PgHoffView                  = require './pg-hoff-view'
PgHoffServerRequest         = require './pg-hoff-server-request'
PgHoffListServersView       = require './pg-hoff-list-servers-view'
PgHoffQuery                 = require './pg-hoff-query'
PgHoffGotoDeclaration       = require './pg-hoff-goto-declaration'
PgHoffAutocompleteProvider  = require('./pg-hoff-autocomplete-provider')
PgHoffDialog                = require('./pg-hoff-dialog')
PgHoffStatus                = require('./pg-hoff-status')
{CompositeDisposable, Disposable} = require 'atom'
{BasicTabButton} = require 'atom-bottom-dock'
ResultsPaneView = require './views/results-pane'
OutputPaneView = require './views/output-pane'
HistoryPaneView = require './views/history-pane'

module.exports = PgHoff =
    provider: null
    pgHoffView: null
    subscriptions: null
    listServersView: null
    listServersViewPanel: null
    resultsPane: null

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
        maximumCellValueLength:
            type: 'integer'
            minimum: 5
            maximum: 10000
            default: 40
            description: 'How long a cell value can be until you have to expand it.'
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
        hoffServerPath:
            type: 'string'
            default: 'pghoffserver'
            order: 1

    activate: (state) ->
        console.debug 'Activating the greatest plugin ever..'
        @pgHoffView             = new PgHoffView(state.pgHoffViewState)
        @listServersView        = new PgHoffListServersView(state.pgHoffViewState)
        @hoffPanes = []

        editor = atom.workspace.getActiveTextEditor()
        @listServersViewPanel = atom.workspace.addModalPanel(item: @listServersView.getElement(), visible: false)

        unless @provider?
            @provider = new PgHoffAutocompleteProvider()

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:goto-declaration': => @gotoDeclaration()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:connect': => @connect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:search-history': => @searchHistoryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:stop-query': => @stopQuery()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:toggle-auto-alias': => @toggleAliases()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQueryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:results': => @changeToResultsPane()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:output': => @changeToOutputPane()
        @subscriptions.add atom.commands.add '.notices', 'pg-hoff:create-dynamic-table': => @createDynamicTable()

        packageFound = atom.packages.getAvailablePackageNames()
            .indexOf('bottom-dock') != -1

        unless packageFound
            atom.notifications.addError 'Could not find Bottom-Dock',
                detail: 'Gulp-Manager: The bottom-dock package is a dependency. \n
                Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
                dismissable: true

    gotoDeclaration: PgHoffGotoDeclaration

    changeToResultsPane: () -> @bottomDock.changePane('results') if @bottomDock
    changeToOutputPane: () -> @bottomDock.changePane('output') if @bottomDock

    onDidChangeActivePane: () ->
        console.log 'onDidChangeActivePane'
    consumeStatusBar: (statusBar) ->
        @statusBarTile = statusBar.addRightTile item: new PgHoffStatus , priority: 2
        @statusBarTile.item.alias = @getAliasForPane()
        @statusBarTile.item.renderText()

        atom.workspace.onDidChangeActivePaneItem((pane) =>
            alias = @getAliasForPane(pane)
            @statusBarTile.item.alias = alias
            @statusBarTile.item.renderText()
        )

        @subscriptions.add @statusBarTile.item.onDidToggle =>
            console.log 'toggle?'

    getAliasForPane: (pane) =>
        if not pane?
            pane = atom.workspace.getActivePaneItem()
        return unless pane?
        if pane?.alias?
            return pane.alias

        return null

    toggleAliases: ->
        alias = @getAliasForPane()
        if alias? or true
            return PgHoffServerRequest
                .Post('get_settings', { alias: alias })
                .then (response) ->
                    response.generate_aliases = !response.generate_aliases
                    settings = response
                    return PgHoffServerRequest
                        .Post('update_settings', { alias: alias,  settings: settings })
                        .then (response) ->
                            if response.success
                                atom.notifications.addSuccess 'Auto alias: ' + if settings.generate_aliases == true then 'ON' else 'OFF'
                            else
                                atom.notifications.addError response.errormessage
                        .catch (err) ->
                            console.error 'catch', err

    stopQuery: ->
        alias = atom.workspace.getActivePaneItem().alias
        if alias?
            return PgHoffServerRequest
                .Post('cancel', { alias: alias })
                .then (response) ->
                    # console.log 'cancel', response, alias

    add: (isInitial) ->
        return unless @bottomDock

        @resultsPane = new ResultsPaneView()
        @outputPane = new OutputPaneView()
        @historyPane = new HistoryPaneView()
        @hoffPanes.push @resultsPane
        @hoffPanes.push @outputPane
        @hoffPanes.push @historyPane

        config =
          name: 'YOLOPANE'
          id: @resultsPane.getId()
          active: true

        @bottomDock.addPane @outputPane, 'Output', isInitial
        @bottomDock.addPane @resultsPane, 'Results', isInitial
        @bottomDock.addPane @historyPane, 'History', isInitial

        @bottomDock.onDidToggle =>
            @resultsPane.resize() if @resultsPane.active && @bottomDock.isActive()

    consumeBottomDock: (@bottomDock) ->
      @subscriptions.add @bottomDock.onDidFinishResizing =>
        pane.resize() for pane in @hoffPanes
      @add true

    searchHistoryWithConnect: () ->
        alias = @getAliasForPane()
        if alias?
            @searchHistory()
        else
            return @connect()?.then =>
                    @searchHistory()
                .catch (err) ->
                    console.error 'Connect error', err
                    atom.notifications.addError('Connect error')

    searchHistory: () ->
        return PgHoffDialog.Prompt("Search")
        .then (searchstring) =>
            request =
                q: searchstring
            return PgHoffServerRequest.Post('search', request)
                    .then (response) =>
                        @historyPane.reset()
                        @historyPane.render response
                        if not @bottomDock?.isActive()
                            @bottomDock.toggle()
                        @bottomDock.changePane(@historyPane.getId())
                        @historyPane.refresh()

    createDynamicTable: ->
        alias = @getAliasForPane()
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
                @statusBarTile.item.alias = @getAliasForPane(paneItem)
                @statusBarTile.item.transactionStatus = null
                @statusBarTile.item.renderText()
            .catch (error) =>
                atom.notifications.addError(error)
            .finally =>
                @listServersViewPanel.hide()

    renderResults: (resultset, newQuery) ->
        if not resultset.complete?
            throw 'WTF!? Resultset not complete'

        @resultsPane.render(resultset)

        if resultset.rows?.length > 1
            @bigResults = true

        @outputPane.render(resultset, newQuery)

    removeHoffPane: (pane) ->
        index = @hoffPanes.indexOf(pane);
        if index >= 0
          @hoffPanes.splice( index, 1 );

    executeQueryWithConnect: ->
        alias = @getAliasForPane()

        if alias?
            @executeQuery()
        else
            return @connect()?.then =>
                    @executeQuery()
                .catch (err) ->
                    console.error 'Connect error', err
                    atom.notifications.addError('Connect error')

    executeQuery: (selectedText, alias) ->
        @resultsPane.reset()
        if @outputPane and @statusBarTile.item.transactionStatus == 'IDLE'
            @outputPane.clear()

        if not @bottomDock?.isActive()
            @bottomDock.toggle()

        if not selectedText?
            selectedText = atom.workspace.getActiveTextEditor().getSelectedText().trim()
        if not alias?
            alias = atom.workspace.getActivePaneItem().alias

        if selectedText.trim().length == 0
            if atom.config.get('pg-hoff.executeAllWhenNothingSelected')
                selectedText = atom.workspace.getActiveTextEditor().getText().trim()
            else
                return

        request =
            query: selectedText
            alias: alias

        @bottomDock.changePane(@resultsPane.getId())
        return PgHoffServerRequest.Post('query', request)
            .then (response) ->
                if response.statusCode == 500
                    throw("/query status code 500")
                else if not response.success && response.errormessage
                    throw(response.errormessage)
                else if not response.success
                    throw("Lost connection. Try again!")

                return response
            .then (response) =>
                timeout = (ms) ->
                    return new Promise((fulfil) ->
                        setTimeout(() ->
                            fulfil()
                        , ms)
                    )
                promises = []
                first = true
                gotResults = false
                gotErrors = false
                gotNotices = false
                return unless response.queryids.length >= 1
                getResult = (queryid) =>
                    if not queryid?
                        queryid = response.queryids.shift()
                    url = 'result/' + queryid
                    return PgHoffServerRequest.Get(url, true)
                        .then (result) =>
                            if result.errormessage?
                                throw("#{result.errormessage}")
                            if result.error?
                                if result.error == 'connection already closed'
                                    atom.editor.getActivePaneItem().alias = null
                                    throw("#{result.error}")
                            if not result.complete
                                return timeout(100)
                                    .then () ->
                                        return getResult(queryid)
                            else
                                return result
                boom = () =>
                    return getResult()
                        .then (result) =>
                            if @statusBarTile.item.transactionStatus != result.transaction_status
                                @statusBarTile.item.transactionStatus = result.transaction_status.toUpperCase()
                                @statusBarTile.item.renderText()

                            if result.columns
                                gotResults = true
                            if result.notices?[0]
                                gotNotices = true
                            if result.error
                                gotErrors = true
                            @renderResults(result, first)
                            first = false

                            if response.queryids.length > 0
                                return boom()

                            return result

                clearTimeout(@resultsPane.loadingTimeout) if @resultsPane.loadingTimeout?
                @resultsPane.loadingTimeout = setTimeout(
                    () =>
                        @resultsPane.startLoadIndicator()
                , 1000)
                boom()
                    .then () =>
                        if gotErrors or not gotResults or (gotResults and gotNotices) # and !@bigResults)
                            @bottomDock.changePane(@outputPane.getId())
                        else if gotResults
                            @bottomDock.changePane(@resultsPane.getId())
                    .finally () =>
                        @resultsPane.stopLoadIndicator()
                        clearTimeout(@resultsPane.loadingTimeout)
            .catch (err) =>
                atom.workspace.getActivePaneItem().alias = null
                atom.notifications.addError(err)
    deactivate: ->
        @subscriptions.dispose()
        @pgHoffView.destroy()
        @listServersView.destroy()
        @bottomDock.deletePane pane.getId() for pane in @hoffPanes

    serialize: ->
        pgHoffViewState: @pgHoffView.serialize()

    provide: ->
        @provider
