{CompositeDisposable, Disposable} = require 'atom'
{$}                               = require 'space-pen'
Config                            = require './config'
PgHoffServerRequest               = require './server-request'
PgHoffConnection                  = require './connection'
PgHoffQuery                       = require './query'
PgHoffGotoDeclaration             = require './goto-declaration'
PgHoffAutocompleteProvider        = require './autocomplete-provider'
PgHoffDialog                      = require './dialog'
PgHoffStatus                      = require './status'
Query                             = require './query'
DBQuery                           = require './dbquery'
PaneManager                       = require './pane-items/manager'
HoffEyePaneItem                   = require './pane-items/hoffeye'
HistoryPaneItem                   = require './pane-items/history'
AnalyzePaneItem                   = require './pane-items/analyze'
Helper                            = require './helper'

module.exports = PgHoff =
    provider: null
    subscriptions: null
    listServersView: null
    listServersViewPanel: null
    resultsPane: null
    paneManager: null
    config: Config

    activate: (state) ->
        console.debug 'Activating the greatest plugin ever..'
        @listServersView        = new PgHoffConnection(state.pgHoffViewState)
        @hoffEyes = {}
        editor = atom.workspace.getActiveTextEditor()
        @listServersViewPanel = atom.workspace.addModalPanel(item: @listServersView.getElement(), visible: false)

        @paneManager = new PaneManager()

        unless @provider?
            @provider = new PgHoffAutocompleteProvider()

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:goto-declaration': => @gotoDeclaration()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:perform-hoff-import': => @executeHoffImport()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:connect': => @connect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:search-history': => @searchHistoryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:stop-query': => @stopQuery()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:toggle-auto-alias': => @toggleAliases()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQueryWithConnect()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:new-hoffeye': => @newHoffEye()

        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-current-query': => @executeQueryWithConnect(true)
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:results': => @changeToResultsPane()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:output': => @changeToOutputPane()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:refresh-definitions': => @refreshDefinitions()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:kill-hoff-server': => PgHoffConnection.KillHoffServer(false)
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:restart-hoff-server': => PgHoffConnection.KillHoffServer(true)
        @subscriptions.add atom.commands.add 'body', 'core:cancel': => @cancel()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:cycle-results': => @cycleResults()

        atom.workspace.observeTextEditors((editor) =>
            markerLayer = editor.addMarkerLayer()
            editor.onDidStopChanging () =>
                markerLayer.clear()
                @fetchMetadata(editor, markerLayer)
            )

        atom.commands.add '[data-type="ResultsPaneItem"]', 'pg-hoff:keep-result-tab': (event) => @keepResultTab(event)

        atom.commands.add '.hamburgler', 'pg-hoff:pin-toggle-result': (event) => @pinToggleResult(event)
        atom.commands.add '.hamburgler', 'pg-hoff:transpose': (event) => @transpose(event)
        atom.commands.add '.hamburgler', 'pg-hoff:open-scripts': (event) => @openScripts(event)
        atom.commands.add '.hamburgler', 'pg-hoff:write-scripts': (event) => @writeScripts(event)
        atom.commands.add '.hamburgler', 'pg-hoff:write-and-open-scripts': (event) => @writeAndOpenScripts(event)
        atom.commands.add '.hamburgler', 'pg-hoff:create-dynamic-table': (event) => @createDynamicTable(event)
        atom.commands.add '.hamburgler', 'pg-hoff:export-to-csv': (event) => @exportToCSV(event)
        atom.commands.add '.hamburgler', 'pg-hoff:remove-result': (event) => @removeResult(event)
        atom.commands.add '.hamburgler', 'pg-hoff:expand-columns': (event) => @expandColumns(event)

        atom.contextMenu.add {
          '[data-type="ResultsPaneItem"]': [
              { label: 'Keep result', command: 'pg-hoff:keep-result-tab' }
          ],
          '.hamburgler': [
              { label: 'Pin', command: 'pg-hoff:pin-toggle-result', shouldDisplay: @pinVisible },
              { label: 'Unpin', command: 'pg-hoff:pin-toggle-result', shouldDisplay: @unpinVisible },
              { label: 'Toggle transpose', command: 'pg-hoff:transpose' },
              { label: 'Expand columns', command: 'pg-hoff:expand-columns' },
              { label: 'Create dynamic table', command: 'pg-hoff:create-dynamic-table' },
              { label: 'Export to CSV', command: 'pg-hoff:export-to-csv' },
              { label: 'Remove', command: 'pg-hoff:remove-result' },
              {
                  label: 'Open scripts',
                  command: 'pg-hoff:open-scripts',
                  shouldDisplay: (event) ->
                      uid = $(event.target).attr('uid')
                      grid = $(".#{uid}")[0];
                      grid.showOpenScripts()
              },
              {
                  label: 'Write scripts',
                  command: 'pg-hoff:write-scripts',
                  shouldDisplay: (event) ->
                      uid = $(event.target).attr('uid')
                      grid = $(".#{uid}")[0];
                      grid.showWriteScripts()
              },
              {
                  label: 'Write+open scripts',
                  command: 'pg-hoff:write-and-open-scripts',
                  shouldDisplay: (event) ->
                      uid = $(event.target).attr('uid')
                      grid = $(".#{uid}")[0];
                      grid.showWriteAndOpenScripts()
              }
          ]
        }

        packageFound = atom.packages.getAvailablePackageNames().indexOf('bottom-dock') != -1
        unless packageFound
            atom.notifications.addError 'Could not find Bottom-Dock',
                detail: 'Pg-Hoff: The bottom-dock package is a dependency. \n
                Learn more about bottom-dock here: https://atom.io/packages/bottom-dock'
                dismissable: true

    gotoDeclaration: PgHoffGotoDeclaration

    pinVisible: (event) ->
        if $(event.target).hasClass('pinned')
            return false
        return true

    unpinVisible: (event) ->
        if $(event.target).hasClass('pinned')
            return true
        return false

    cycleResults: () -> @paneManager.getResultsPane().cycleResults()

    fetchMetadata: (editor, markerLayer) ->
        return unless @getActiveAlias()
        PgHoffServerRequest
            .Post('get_metadata', { sql: editor.getText().trim() })
            .then (response) =>
                for table in response
                    editor.scan new RegExp(table.expression, 'i'), (hit) =>
                        marker = markerLayer.markBufferRange(hit.range)
            .finally () =>
                editor.decorateMarkerLayer(markerLayer, type: 'highlight', class: 'definition-underline')

    cancel: () ->
        @paneManager.hide()

    transpose: (event) ->
        uid = $(event.target).attr('uid')
        grid = $(".#{uid}")[0];
        grid.transpose() if grid?

    expandColumns: (event) ->
        queryid = $(event.target).attr('queryid')
        @paneManager.getResultsPane().expandColumns(queryid)

    changeToResultsPane: () -> @paneManager.switchToResultsPane()

    changeToOutputPane: () -> @paneManager.switchToOutputPane()

    consumeStatusBar: (statusBar) ->
        @statusBarTile = statusBar.addRightTile item: new PgHoffStatus , priority: 2
        @statusBarTile.item.alias = @getActiveAlias()
        @statusBarTile.item.renderText()

        atom.workspace.onDidChangeActivePaneItem((pane) =>
            alias = @getActiveAlias()
            @statusBarTile.item.alias = alias
            @statusBarTile.item.renderText()
        )

    getActiveAlias: () =>
        textEditor = atom.workspace.getActiveTextEditor()

        return textEditor.alias if textEditor?.alias?

    setActiveAlias: (alias) =>
        textEditor = atom.workspace.getActiveTextEditor()

        textEditor.alias = alias if textEditor?

    toggleAliases: ->
        alias = @getActiveAlias()
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
                .then (response) =>
                    if response.success
                        atom.notifications.addWarning('Execution aborted')
                .catch (error) ->
                    console.log 'error', error

    openDock: () -> @paneManager.openDock()

    add: (isInitial) ->
        return unless @bottomDock
        @historyPane = new HistoryPaneItem()
        @paneManager.getPanes().push @historyPane
        #pane = atom.workspace.getRightDock().getActivePane().splitDown({
        #    items: [@hoffEyePane]
        #})

    consumeBottomDock: (@bottomDock) ->
      @subscriptions.add @bottomDock.onDidFinishResizing =>
        pane.resize() for pane in @paneManager.getPanes()
      @add true

    searchHistoryWithConnect: () ->
        alias = @getActiveAlias()
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
            @paneManager.getResultsPane().unPinTable(queryid)
        else
            $(event.target).addClass('pinned')
            @paneManager.getResultsPane().pinTable(queryid)

    keepResultTab: (event) ->
        console.log($(event.target))

    createDynamicTable: (event) ->
        alias = @getActiveAlias()
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
                atom.notifications.addInfo('Dynamic table created with name ' + globalName + '.')
            .catch (err) ->
                console.debug 'user aborted prompt'

    exportToCSV: (event) ->
        PgHoffDialog
            .SaveAs()
            .then (path) ->
                req =
                    queryid: $(event.target).attr('queryid')
                    path: path
                return PgHoffServerRequest.Post('write_csv_file', req)
            .then (response) ->
                if response.success
                    atom.notifications.addInfo('Exporting to CSV.')
                else
                    atom.notifications.addWarning('There was a problem exporting to CSV')
            .catch (err) ->
                console.debug err

    connect: ->
        alias = @getActiveAlias()

        if @listServersViewPanel.isVisible()
            @listServersViewPanel.hide()
            return

        return @listServersView.connect(@listServersViewPanel)
            .then (server) =>
                if server.already_connected
                    atom.notifications.addInfo('Using ' + server.alias)
                else
                    atom.notifications.addSuccess('Connected to ' + server.alias)

                @setActiveAlias(server.alias)
                @statusBarTile.item.alias = @getActiveAlias()
                @statusBarTile.item.transactionStatus = null
                @statusBarTile.item.renderText()

                colorizeString = (str) ->
                    i = 0
                    hash = 0
                    while i < str.length
                        hash = str.charCodeAt(i++) + (hash << 5) - hash
                    color = Math.floor(Math.abs(Math.sin(hash) * 10000 % 1 * 16777216)).toString(16)
                    '#' + Array(6 - (color.length) + 1).join('0') + color
                tabItem = atom.views.getView(atom.workspace).querySelector "ul.tab-bar>li.tab[data-type='TextEditor'].active"
                tabMarker = (tabItem.querySelector "span.tab-marker") or document.createElement('span')
                $(tabMarker).attr('alias', server.alias)
                tabMarker.classList.add 'tab-marker'
                $(tabMarker).css('border-color', "transparent #{server.color or colorizeString(server.alias)} transparent transparent")
                tabItem.appendChild tabMarker

                return server.alias
            .catch (err) =>
                if err? and err != 'cancel'
                    atom.notifications.addError("Connect error: #{err}")
                    tabMarker.remove() for tabMarker in atom.views.getView(atom.workspace).querySelectorAll "ul.tab-bar>li.tab[data-type='TextEditor']>span.tab-marker"
                throw(err)
            .finally =>
                @listServersViewPanel.hide()

    renderResults: (resultset, complete) ->
        if not resultset.complete?
            throw 'WTF!? Resultset not complete'
        @paneManager.getResultsPane().render(resultset)
        if complete
            @paneManager.getOutputPane().render(resultset)

    openScripts: (event) ->
        uid = $(event.target).attr('uid')
        grid = $(".#{uid}")[0];
        grid.openScripts()

    writeScripts: (event) ->
        uid = $(event.target).attr('uid')
        grid = $(".#{uid}")[0];
        grid.writeScripts()

    writeAndOpenScripts: (event) ->
        uid = $(event.target).attr('uid')
        grid = $(".#{uid}")[0];
        grid.writeAndOpenScripts()

    refreshDefinitions: ->
        alias = @getActiveAlias()
        if alias?
            PgHoffServerRequest.Post('refresh_definitions', {alias:alias})
            .then (response) ->
                if response.success
                    atom.notifications.addInfo('Refreshing definitions for ' + alias)
                else
                    atom.notifications.addError(response.errormessage)
            .catch (err) =>
                atom.notifications.addError(err)



    startHoffEye: () ->
        alias = @getActiveAlias() unless alias?
        if @hoffEye? && @hoffEye == true
            return
        @hoffEye = true

        getResult = () =>
            request =
                alias: alias
            PgHoffServerRequest.Post('hoffeye_result', request)
                .then (response) =>
                    return response
                .then (response) =>
                    if response
                        for result in response
                            if result['result']['new_data']
                                r = [
                                     columns: result['result']['columns']
                                     rows: result['result']['rows']
                                     notices: result['result']['notices']
                                     queryid: result['id']
                                     complete: true
                                     rowcount: result['result']['rows'].length
                                     statusmessage: result['result']['statusmessage']
                                ]
                                for j in [0..r[0]['rows'].length-1]
                                    r[0]['rows']['rownr'] = j
                                if @hoffEyes[result['id']]
                                    @hoffEyes[result['id']].render(r[0])
                                    @hoffEyes[result['id']].new_data_flash()
                    return Helper.Timeout(1000)
                        .then () =>
                            if @hoffEye == true
                                return getResult()
                            else
                                return
        getResult()

    newHoffEye: () ->
        @connect()
            .then (alias) =>
                console.log 'got the alias', alias

                hoffEyePane = @paneManager.newHoffEyePane(alias)

                cursor_pos = null
                editor = atom.workspace.getActiveTextEditor()
                pos = editor.getCursorBufferPosition()
                cursor_pos = editor.getBuffer().characterIndexForPosition(pos)
                cursor_pos = cursor_pos - editor.getBuffer().getText(pos).substr(0, cursor_pos).split(/\r\n|\r|\n/).length

                selectedBufferRange = atom.workspace.getActiveTextEditor().getSelectedBufferRange()
                if not selectedText?
                    selectedText = atom.workspace.getActiveTextEditor().getSelectedText().trim()

                request =
                    alias: alias,
                    query: selectedText

                id = PgHoffServerRequest.Post('hoffeye_new', request)
                    .then (response) =>
                        if response.statusCode == 500
                            throw("/query status code 500")
                        else if not response.success && response.errormessage
                            throw(response.errormessage)
                        else if not response.success
                            throw("Lost connection. Try again!")
                        hoffEyePane.setId(alias, response['id'])
                        @hoffEyes[response['id']] = hoffEyePane

                        tabItem = atom.views.getView(atom.workspace).querySelector("ul.tab-bar>li.tab[data-type='HoffEyePaneItem'].active")
                        tabMarker = document.createElement('span')
                        $(tabMarker).attr('id', response['id'])
                        tabItem.append tabMarker
                        @startHoffEye()

    executeQueryWithConnect: (onlyCurrentQuery) ->
        alias = @getActiveAlias()
        cursor_pos = null
        if onlyCurrentQuery
            editor = atom.workspace.getActiveTextEditor()
            pos = editor.getCursorBufferPosition()
            cursor_pos = editor.getBuffer().characterIndexForPosition(pos)
            cursor_pos = cursor_pos - editor.getBuffer().getText(pos).substr(0, cursor_pos).split(/\r\n|\r|\n/).length
        if alias?
            @executeNewQuery(cursor_pos)
        else
            @connect()?.then => @executeNewQuery(cursor_pos)

    executeHoffImport: () ->
        editor = atom.workspace.getActivePaneItem()
        file = editor?.buffer.file
        request =
            hoffimportfile: file['path']
        #@executePost('hoff_import', request, null)

    executeNewQuery: (cursor_pos) ->
        if @processingBatch? and @processingBatch
            atom.notifications.addWarning('Execution in progress, hold on!')
            return
        @processingBatch = true

        @openDock()

        @paneManager.getOutputPane().clear() if @paneManager.getOutputPane() and @statusBarTile.item.transactionStatus == 'IDLE'

        selectedBufferRange = atom.workspace.getActiveTextEditor().getSelectedBufferRange()
        selectedText        = atom.workspace.getActiveTextEditor().getSelectedText().trim() unless selectedText?
        alias               = @getActiveAlias() unless alias?

        if selectedText.trim().length == 0
            if atom.config.get('pg-hoff.executeAllWhenNothingSelected')
                selectedText = atom.workspace.getActiveTextEditor().getText().trim()
            else
                return

        newBatch = true
        @paneManager.getResultsPane().clear()
        query = new DBQuery(selectedText, alias, {
            verbose: false
            onError: (error) =>
                console.error error
                atom.notifications.addError(error.errorCode)
            onPartialQueryStatus: (result) =>
                @paneManager.getResultsPane().updateNotComplete(
                    result.newBatch,
                    result.result,
                    result.queryNumber,
                    selectedBufferRange
                )
            onQueryStatus: (status) =>
                #unless status.hasQueryPlan
                    #@removeHoffPane(@analyzePane) if @analyzePane in @hoffPanes

                @paneManager.getResultsPane().updateRendering(status.result)
            onPartialResult: (partial) => @renderResults(partial.result, false)
            onQueryError: (result) =>
                @paneManager.getResultsPane().markQueryError(result)
            onResult: (result) =>
                if @statusBarTile.item.transactionStatus != result.result.transaction_status
                    @statusBarTile.item.transactionStatus = result.result.transaction_status.toUpperCase()
                    @statusBarTile.item.renderText()

                @paneManager.getResultsPane().updateCompleted(result.result)
                @renderQueryPlan(result.result.rows) if result.gotQueryplan

                @renderResults(result.result, true)
            onAllResults: (all) =>
                if all.gotErrors or not all.gotResults or (all.gotResults and all.gotNotices)
                    @changeToOutputPane()
                else if gotResults
                    @changeToResultsPane()
                    @paneManager.getResultsPane().focusFirstResult()
            onQuery: () =>
                clearTimeout(@paneManager.getResultsPane().loadingTimeout) if @paneManager.getResultsPane().loadingTimeout?
                @paneManager.getResultsPane().loadingTimeout = setTimeout(
                    () =>
                        @paneManager.getResultsPane().startLoadIndicator()
                , 1000)
            onCompletion: (completion) =>
                @processingBatch = false
                @paneManager.getResultsPane().stopLoadIndicator()
                clearTimeout(@paneManager.getResultsPane().loadingTimeout)
        })
        query.execute()

    renderQueryPlan: (queryplanrows) ->
        queryplan = (queryplanrows.map (row) -> row['QUERY PLAN1']).join('\n')
        request =
            plan: queryplan
            is_anon: 0
            title: ' '
            is_public:0
        return PgHoffServerRequest.hoffingtonPost('https://explain.depesz.com/', request)
            .then (response) =>
                div = document.createElement('div');
                div.innerHTML = response;
                explain = div.querySelector(".result-html");

                unless @analyzePane in @hoffPanes
                    @analyzePane = new AnalyzePaneItem()
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
