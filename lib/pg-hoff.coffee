{CompositeDisposable, Disposable} = require 'atom'
PgHoffServerRequest         = require './server-request'
PgHoffConnection            = require './connection'
PgHoffQuery                 = require './query'
PgHoffGotoDeclaration       = require './goto-declaration'
PgHoffAutocompleteProvider  = require('./autocomplete-provider')
PgHoffDialog                = require('./dialog')
PgHoffStatus                = require('./status')
{BasicTabButton}            = require 'atom-bottom-dock'
ResultsPaneView             = require './bottom-dock/results-pane'
OutputPaneView              = require './bottom-dock/output-pane'
HistoryPaneView             = require './bottom-dock/history-pane'
AnalyzePaneView             = require './bottom-dock/analyze-pane'
{$}                         = require 'space-pen'

module.exports = PgHoff =
    provider: null
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
        autoTranspose:
            type: 'boolean'
            description: 'Auto transpose'
            default: true
            order: 12
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
        @listServersView        = new PgHoffConnection(state.pgHoffViewState)
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
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:refresh-definitions': => @refreshDefinitions()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:kill-hoff-server': => PgHoffConnection.KillHoffServer(false)
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:restart-hoff-server': => PgHoffConnection.KillHoffServer(true)
        @subscriptions.add atom.commands.add 'body', 'core:cancel': => @cancel()

        #@subscriptions.add atom.commands.add '.hamburgler', 'pg-hoff:create-dynamic-table': => @createDynamicTable(event)
        atom.commands.add '.hamburgler',
            'pg-hoff:create-dynamic-table': (event) => @createDynamicTable(event)
        atom.commands.add '.hamburgler',
            'pg-hoff:pin-toggle-result': (event) => @pinToggleResult(event)

        packageFound = atom.packages.getAvailablePackageNames()
            .indexOf('bottom-dock') != -1

        unless packageFound
            atom.notifications.addError 'Could not find Bottom-Dock',
                detail: 'Pg-Hoff: The bottom-dock package is a dependency. \n
                Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
                dismissable: true

    gotoDeclaration: PgHoffGotoDeclaration

    cancel: () ->
        if @bottomDock.isActive()
            @bottomDock.toggle() if @bottomDock
            atom.workspace.getActivePane().activate()

    changeToResultsPane: () ->
        return unless @bottomDock
        if @bottomDock.isActive()
            if @bottomDock.getCurrentPane().getId() == 'results'
                @bottomDock.toggle()
                atom.workspace.getActivePane().activate()
            else
                @bottomDock.changePane('results')
                @resultsPane.focusFirstResult()
        else
            @bottomDock.toggle()
            @bottomDock.changePane('results')
            @resultsPane.focusFirstResult()

    changeToOutputPane: () ->
        return unless @bottomDock
        if @bottomDock.isActive()
            if @bottomDock.getCurrentPane().getId() == 'output'
                @bottomDock.toggle()
                atom.workspace.getActivePane().activate()
            else
                @bottomDock.changePane('output')
        else
            @bottomDock.toggle()
            @bottomDock.changePane('output')
            @resultsPane.focusFirstResult()

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
                    @resultsPane.markQueryAborted()
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

    pinToggleResult: (event) ->
        queryid = $(event.target).attr('queryid')
        if $(event.target).hasClass('pinned')
            $(event.target).removeClass('pinned')
            @resultsPane.unPinTable(queryid)
        else
            $(event.target).addClass('pinned')
            @resultsPane.pinTable(queryid)

    createDynamicTable: (event) ->
        alias = @getAliasForPane()
        globalName = null
        PgHoffDialog
            .Prompt('Enter name')
            .then (name) ->
                req =
                    queryid: $(event.target).attr('queryid')
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
            .catch (err) =>
                if err? and err != 'cancel'
                    atom.notifications.addError("Connect error: #{err}")
                throw(err)
            .finally =>
                @listServersViewPanel.hide()

    renderResults: (resultset, newQuery) ->
        if not resultset.complete?
            throw 'WTF!? Resultset not complete'

        @resultsPane.render(resultset)

        if resultset.rows?.length > 1
            @bigResults = true

        @outputPane.render(resultset, newQuery)

    refreshDefinitions: ->
        alias = @getAliasForPane()
        if alias?
            PgHoffServerRequest.Post('refresh_definitions', {alias:alias})
            .then (response) ->
                if response.success
                    atom.notifications.addInfo('Refreshing definitions for ' + alias)
                else
                    atom.notifications.addError(response.errormessage)
            .catch (err) =>
                atom.notifications.addError(err)

    removeHoffPane: (pane) ->
        index = @hoffPanes.indexOf(pane);
        if index >= 0
          @hoffPanes.splice( index, 1 );
         @bottomDock.deletePane pane.getId()
         pane = null


    executeQueryWithConnect: ->
        alias = @getAliasForPane()
        if alias?
            @executeQuery()
        else
            @connect()?.then => @executeQuery()

    executeQuery: (selectedText, alias) ->
        @resultsPane.reset()
        if @outputPane and @statusBarTile.item.transactionStatus == 'IDLE'
            @outputPane.clear()

        if not @bottomDock?.isActive()
            @bottomDock.toggle()

        selectedBufferRange = atom.workspace.getActiveTextEditor().getSelectedBufferRange()

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
                newBatch = true
                NumberOfQueries = response.queryids.length
                return unless response.queryids.length >= 1
                queryCount = response.queryids.length
                getResult = (queryid) =>
                    if not queryid?
                        queryid = response.queryids.shift()
                    url = 'result/' + queryid
                    return PgHoffServerRequest.Get(url, true)
                        .then (result) =>
                            @resultsPane.updateNotComplete(newBatch, result, NumberOfQueries - response.queryids.length, selectedBufferRange)
                            if result.errormessage?
                                throw("#{result.errormessage}")
                            if result.error?
                                @resultsPane.markQueryError(result)
                                if result.error == 'connection already closed'
                                    atom.editor.getActivePaneItem().alias = null
                                    throw("#{result.error}")
                            if not result.complete
                                newBatch = false
                                return timeout(100)
                                    .then () ->
                                        return getResult(queryid)
                                return timeout(100)
                                    .then () ->
                                        return getResult(queryid)
                            else
                                @resultsPane.updateCompleted(result)
                                newBatch = false
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
                            if queryCount == 1
                                result.onlyOne = true

                            if queryCount == 1 and result.columns?.length == 1 and result.columns?[0]['name'] == 'QUERY PLAN' and result.query.substring(0, 7) == 'EXPLAIN'
                                @renderQueryPlan(result.rows)
                            else
                                if @analyzePane in @hoffPanes
                                    @removeHoffPane(@analyzePane)

                                @renderResults(result)

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
                            @resultsPane.focusFirstResult()
                    .finally () =>
                        @resultsPane.stopLoadIndicator()
                        clearTimeout(@resultsPane.loadingTimeout)
            .catch (err) =>
                atom.workspace.getActivePaneItem().alias = null
                atom.notifications.addError(err)

    renderQueryPlan: (queryplanrows) ->
        queryplan = (queryplanrows.map (row) -> row['QUERY PLAN1']).join('\n')
        request =
            plan: queryplan
            is_anon: 1
            title: ' '
            is_public:0
        return PgHoffServerRequest.hoffingtonPost('https://explain.depesz.com/', request)
            .then (response) =>
                div = document.createElement('div');
                div.innerHTML = response;
                explain = div.querySelector(".result-html");

                unless @analyzePane in @hoffPanes
                    @analyzePane = new AnalyzePaneView()
                    @hoffPanes.push @analyzePane
                    @bottomDock.addPane @analyzePane, 'Analyze', true

                @analyzePane.load(explain)
                @bottomDock.changePane(@analyzePane.getId())
            .catch (r) ->
                console.error r
    deactivate: ->
        @subscriptions.dispose()
        @listServersView.destroy()
        @bottomDock.deletePane pane.getId() for pane in @hoffPanes

    serialize: ->

    provide: ->
        @provider
