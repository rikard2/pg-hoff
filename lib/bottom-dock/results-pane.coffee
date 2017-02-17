{Emitter, CompositeDisposable}      = require 'atom'
{$}                                 = require 'space-pen'
parseInterval                       = require 'postgres-interval'
window.jQuery                       = require 'jquery'
{DockPaneView, TableView, Toolbar}  = require 'atom-bottom-dock'
TableView                           = require '../slickgrid/table-view'
OutputView                          = require './output-view'
SlickFormatting                     = require '../slickgrid/formatting'

class ResultsPaneView extends DockPaneView
    @table: null
    getId: () -> 'results'
    @content: ->
        @div class: 'gulp-pane', outlet: 'pane', style: 'overflow: auto !important; font-family:menlo', =>
        #@subview 'toolbar', new Toolbar()

    reset: () ->
        @empty()

    startLoadIndicator: () ->
        @indicator = document.createElement('div')
        @indicator.classList.add 'indicator'
        @prepend @indicator
        $('.indicator').slideDown 300

    stopLoadIndicator: () ->
        $('.indicator').slideUp 100, ->
            @remove()

    render: (resultset) ->
        @removeClass 'transpose'
        @removeClass 'row-numbers'
        return unless resultset.complete and resultset.columns
        options =
            enableCellNavigation: false
            enableColumnReorder: true
            multiColumnSort: false
            forceFitColumns: false
            fullWidthRows: false
            rowHeight:30
            headerRowHeight: 30
            asyncPostRenderDelay: 500
            syncColumnCellResize: true
            multiSelect:true
            cellFlashingCssClass: "flashcell"
            rowNumberColumn: true
            queryid: resultset['queryid']

        for c in resultset.columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            c["width"] = 200
            c["formatter"] = SlickFormatting.DefaultFormatter
            max = 0
            for d in resultset.rows
                if d[c["field"]] != null && d[c["field"]]?.toString().length > max
                    max = d[c["field"]].toString().length
            c["width"] = Math.min((Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))), 250)

        if resultset.rows.length <= 100 and not resultset.onlyOne
            height = ''.concat(resultset.rows.length * 30 + 30, 'px')
        else
            height = '100%'

        autoTranspose = atom.config.get('pg-hoff.autoTranspose')
        if autoTranspose and resultset.onlyOne and resultset.rows.length <= 2 and resultset.columns.length > 5
            @addClass 'transpose'
            options.transpose = true
            height = '100%'
        else if options.rowNumberColumn
            @addClass 'row-numbers'

        table = new TableView options, resultset.rows, resultset.columns , height
        @append table

    initialize: ->
        super()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()

    updateNotComplete: (newBatch, result, queryNumber, bufferRange) ->
        if newBatch
            query.marker.destroy() for query in @processedQueries?
            @processedQueries = []
        unless @processedQueries
            @processedQueries = []
        for query in @processedQueries
            if query.queryNumber == queryNumber
                return

        queryInfo = {
            queryNumber: queryNumber
            queryId: result.queryid
            range: null
            marker: null
        }

        if JSON.stringify bufferRange.start == JSON.stringify bufferRange.end
            bufferRange = atom.workspace.getActiveTextEditor().getBuffer().getRange()
        if queryNumber > 1
            bufferRange.start = @processedQueries[queryNumber-2].range.end

        atom.workspace.getActiveTextEditor().scanInBufferRange(new RegExp(@escapeRegExp(result.query)), bufferRange, (hit) => @queryHit(hit, queryInfo) )
    updateCompleted: (result) ->
        for query in @processedQueries
            if query.queryId == result.queryid
                setTimeout( () =>
                    query.marker.destroy()
                , 300)

    markQueryError: (result) ->
        editor = atom.workspace.getActiveTextEditor()
        for query in @processedQueries
            if query.queryId == result.queryid
                query.marker.destroy()
                if result.error.indexOf('canceling statement due to user request') != -1
                    classType = 'query-aborted'
                    timeout = 1000
                else
                    classType = 'query-error'
                    timeout = 5000
                marker = editor.markBufferRange(query.range, invalidate: 'overlap')
                editor.decorateMarker(marker, type: 'line-number', class: classType)
                setTimeout( () =>
                    marker.destroy()
                , timeout)

    clear: () ->
        query.marker.destroy() for query in @processedQueries

    queryHit: (hit, queryInfo) =>
        editor = atom.workspace.getActiveTextEditor()
        marker = editor.markBufferRange(hit.range, invalidate: 'overlap')
        queryInfo.range = hit.range
        queryInfo.marker = marker
        @processedQueries.push queryInfo

        editor.decorateMarker(marker, type: 'line-number', class: 'query-loading')
    escapeRegExp: (str) ->
        str = str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
        return str.replace(/(?:\r\n|\r|\n)/g, '[\\r?\\n]');


    refresh: =>
        @outputView.refresh()

    stop: =>
        @outputView.stop()

    clear: =>
        @outputView.clear()

    focusFirstResult: => $(".slick-cell.l0.r0").first().click()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = ResultsPaneView
