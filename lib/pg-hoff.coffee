{CompositeDisposable, Disposable} = require 'atom'
{$}                               = require 'space-pen'
{BasicTabButton}                  = require 'atom-bottom-dock'
PgHoffServerRequest               = require './server-request'
PgHoffConnection                  = require './connection'
PgHoffQuery                       = require './query'
PgHoffGotoDeclaration             = require './goto-declaration'
PgHoffAutocompleteProvider        = require './autocomplete-provider'
PgHoffDialog                      = require './dialog'
PgHoffStatus                      = require './status'
ResultsPaneView                   = require './bottom-dock/results-pane'
OutputPaneView                    = require './bottom-dock/output-pane'
HistoryPaneView                   = require './bottom-dock/history-pane'
AnalyzePaneView                   = require './bottom-dock/analyze-pane'
util                              = (require './util')

module.exports = PgHoff =
    config        : require './config'
    provider      : null
    subscriptions : null
    resultsPane   : null
    hoffPanes     : []

    activate: (state) ->
        console.debug 'Activating the greatest plugin ever..'
        @connection = new PgHoffConnection(state.pgHoffViewState)
        @provider = new PgHoffAutocompleteProvider() unless @provider?

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:goto-declaration': => PgHoffGotoDeclaration()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:connect': => @connect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:search-history': => @searchHistoryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:stop-query': => @stopQuery()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:toggle-auto-alias': => @toggleAliases()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQueryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-current-query': => @executeQueryWithConnect(true)
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:results': => @changeToResultsPane()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:output': => @changeToOutputPane()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:refresh-definitions': => @refreshDefinitions()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:kill-hoff-server': => PgHoffConnection.KillHoffServer(false)
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:restart-hoff-server': => PgHoffConnection.KillHoffServer(true)
        @subscriptions.add atom.commands.add 'body', 'core:cancel': => @cancel()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:cycle-results': => @cycleResults()

        @setupHamburgler()

        packageFound = atom.packages.getAvailablePackageNames()
            .indexOf('bottom-dock') != -1

        unless packageFound
            atom.notifications.addError 'Could not find Bottom-Dock',
                detail: 'Pg-Hoff: The bottom-dock package is a dependency. \n
                Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
                dismissable: true

    pinVisible: (event) ->
        if $(event.target).hasClass('pinned')
            return false
        return true

    unpinVisible: (event) ->
        if $(event.target).hasClass('pinned')
            return true
        return false

    cycleResults: () ->
        @resultsPane.cycleResults()

    removeResult: (event) ->
        queryid = $(event.target).attr('queryid')
        @resultsPane.removeResult(queryid)

    cancel: () ->
        if @bottomDock.isActive()
            @bottomDock.toggle() if @bottomDock
            atom.workspace.getActivePane().activate()

    transpose: (event) ->
        uid = $(event.target).attr('uid')
        grid = $(".#{uid}")[0];
        grid.transpose() if grid?

    expandColumns: (event) ->
        queryid = $(event.target).attr('queryid')
        @resultsPane.expandColumns(queryid)

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
            #console.log 'toggle?

    getAliasForPane: (pane) =>
        return atom.workspace.getActivePaneItem()?.alias? or null unless pane?
        return pane.alias? or null

    toggleAliases: ->
        alias = @getAliasForPane()
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
                .then (response) =>
                    if response.success
                        atom.notifications.addWarning('Execution aborted')
                .catch (error) ->
                    console.log 'error', error

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

        return @connection.connect()
            .then (server) =>
                if server.already_connected
                    atom.notifications.addInfo('Using ' + server.alias)
                else
                    atom.notifications.addSuccess('Connected to ' + server.alias)

                paneItem.alias = server.alias
                @statusBarTile.item.alias = @getAliasForPane(paneItem)
                @statusBarTile.item.transactionStatus = null
                @statusBarTile.item.renderText()

                tabItem = atom.views.getView(atom.workspace).querySelector "ul.tab-bar>li.tab[data-type='TextEditor'].active"
                tabMarker = (tabItem.querySelector "span.tab-marker") or document.createElement('span')
                $(tabMarker).attr('alias', server.alias)
                tabMarker.classList.add 'tab-marker'
                $(tabMarker).css('border-color', "transparent #{server.color or util.colorizeString(server.alias)} transparent transparent")
                tabItem.appendChild tabMarker
            .catch (err) =>
                if err? and err != 'cancel'
                    atom.notifications.addError("Connect error: #{err}")
                    tabMarker.remove() for tabMarker in atom.views.getView(atom.workspace).querySelectorAll "ul.tab-bar>li.tab[data-type='TextEditor']>span.tab-marker"
                throw(err)

    renderResults: (resultset, complete) ->
        throw 'WTF!? Resultset not complete' unless resultset.complete?
        @resultsPane.render(resultset)
        @outputPane.render(resultset) if complete

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

    executeQueryWithConnect: (onlyCurrentQuery) ->
        alias = @getAliasForPane()
        cursor_pos = if onlyCurrentQuery then util.getCursorPosInCurrentTextEditor else null
        if alias?
            @executeQuery(cursor_pos)
        else
            @connect()?.then => @executeQuery(cursor_pos)

    executeQuery: (cursor_pos) ->
        if @processingBatch? and @processingBatch
            atom.notifications.addWarning('Execution in progress, hold on!')
            return
        @processingBatch = true
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
        if cursor_pos
            request.cursor_pos = cursor_pos

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
                promises = []
                first = true
                gotResults = false
                gotErrors = false
                gotNotices = false
                newBatch = true
                NumberOfQueries = response.queryids.length
                return unless response.queryids.length >= 1
                queryCount = response.queryids.length
                pollInterval = atom.config.get('pg-hoff.pollInterval')
                getResult = (queryid) =>
                    if not queryid?
                        queryid = response.queryids.shift()
                    url = 'query_status/' + queryid
                    return PgHoffServerRequest.Get(url, true)
                        .then (result) =>
                            @resultsPane.updateNotComplete(newBatch, result, NumberOfQueries - response.queryids.length, selectedBufferRange)
                            if not result.complete
                                newBatch = false
                                return util.timeout(pollInterval).then () -> getResult(queryid)
                            return result
                boom = () =>
                    return getResult()
                        .then (result) =>
                            gotResults = result.has_result
                            gotNotices = result.has_notices
                            gotErrors = result.has_error
                            if queryCount == 1 and result.has_queryplan
                                gotQueryplan = true
                            else
                                if @analyzePane in @hoffPanes
                                    @removeHoffPane(@analyzePane)

                            currentpage = 0
                            pagesize = 10000
                            @resultsPane.updateRendering(result)
                            url = 'result/' + result.queryid + '/'
                            fetchPartialResult = () =>
                                return PgHoffServerRequest.Get(url + currentpage + '/' + (currentpage + pagesize), true)
                                .then (result) =>
                                    if result.errormessage?
                                        throw("#{result.errormessage}")
                                    if result.error?
                                        @resultsPane.markQueryError(result)
                                        if result.error == 'connection already closed'
                                            atom.editor.getActivePaneItem().alias = null
                                            throw("#{result.error}")
                                    if queryCount == 1
                                        result.onlyOne = true
                                    if  result.rowcount > 0 and currentpage + pagesize < result.rowcount
                                        @renderResults(result, false)
                                        currentpage += pagesize
                                        return fetchPartialResult()
                                    else
                                        if @statusBarTile.item.transactionStatus != result.transaction_status
                                            @statusBarTile.item.transactionStatus = result.transaction_status.toUpperCase()
                                            @statusBarTile.item.renderText()
                                        @resultsPane.updateCompleted(result)
                                        if gotQueryplan
                                            @renderQueryPlan(result.rows)
                                        @renderResults(result, true)
                                        if response.queryids.length > 0
                                            return boom()
                                        return result
                                .catch (err) ->
                                    console.log err
                                    throw err
                            first = false
                            return fetchPartialResult()

                clearTimeout(@resultsPane.loadingTimeout) if @resultsPane.loadingTimeout?
                @resultsPane.loadingTimeout = setTimeout(
                    () =>
                        @resultsPane.startLoadIndicator()
                , 1000)
                return boom()
                    .then () =>
                        if gotErrors or not gotResults or (gotResults and gotNotices)
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
            .finally =>
                @processingBatch = false

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
    setupHamburgler: ->
        atom.commands.add '.hamburgler', 'pg-hoff:pin-toggle-result': (event) => @pinToggleResult(event)
        atom.commands.add '.hamburgler', 'pg-hoff:transpose': (event) => @transpose(event)
        atom.commands.add '.hamburgler', 'pg-hoff:create-dynamic-table': (event) => @createDynamicTable(event)
        atom.commands.add '.hamburgler', 'pg-hoff:remove-result': (event) => @removeResult(event)
        atom.commands.add '.hamburgler', 'pg-hoff:expand-columns': (event) => @expandColumns(event)

        atom.contextMenu.add {
          '.hamburgler': [{label: 'Pin', command: 'pg-hoff:pin-toggle-result', shouldDisplay: @pinVisible}]
        }
        atom.contextMenu.add {
          '.hamburgler': [{label: 'Unpin', command: 'pg-hoff:pin-toggle-result', shouldDisplay: @unpinVisible}]
        }

        atom.contextMenu.add {
          '.hamburgler': [{label: 'Toggle transpose', command: 'pg-hoff:transpose'}]
        }
        atom.contextMenu.add {
          '.hamburgler': [{label: 'Expand columns', command: 'pg-hoff:expand-columns'}]
        }
        atom.contextMenu.add {
          '.hamburgler': [{label: 'Create dynamic table', command: 'pg-hoff:create-dynamic-table'}]
        }
        atom.contextMenu.add {
          '.hamburgler': [{label: 'Remove', command: 'pg-hoff:remove-result'}]
        }

    deactivate: ->
        @subscriptions.dispose()
        @connection.destroy()
        @bottomDock.deletePane pane.getId() for pane in @hoffPanes

    serialize: ->
    provide: -> @provider
