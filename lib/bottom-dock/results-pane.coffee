{Point, Range, Emitter, CompositeDisposable}      = require 'atom'
{$}                                 = require 'space-pen'
parseInterval                       = require 'postgres-interval'
window.jQuery                       = require 'jquery'
{DockPaneView, TableView, Toolbar}  = require 'atom-bottom-dock'
TableView                           = require '../slickgrid/table-view'
OutputView                          = require './output-view'
SlickFormatting                     = require '../slickgrid/formatting'

class ResultsPaneView extends DockPaneView
    @table: null
    processedQueries: []
    getId: () -> 'results'
    @content: ->
        @div class: 'gulp-pane', outlet: 'pane', style: 'overflow: auto !important; font-family:menlo', =>

    reset: () ->
        marker.destroy() for marker in @errorMarkers
        table.table.remove() for table in @tables when not table.pinned
        @tables = (x for x in @tables when x.pinned)
        unless @tables.length > 0
            @querynumber = 0
            @selectedquery = 0

    removeResult: (queryid) ->
        table.table.remove() for table in @tables when table.queryid == queryid
        @tables = (table for table in @tables when table.queryid != queryid)

    pinTable: (queryid) ->
        x.pinned = true for x in @tables when x.queryid == queryid
    unPinTable: (queryid) ->
        x.pinned = false for x in @tables when x.queryid == queryid

    expandColumns: (queryid) ->
        x.table.expandColumns() for x in @tables when x.queryid == queryid

    cycleResults: ->
        if @selectedquery < @tables.length - 1
            @selectedquery += 1
        else
            @selectedquery = 0
        number = @tables[@selectedquery].querynumber
        $(@).animate { scrollTop: $('#slickgrid_' + number + 'rownr').offset().top - $(@).offset().top + $(@).scrollTop() }, 650


    startLoadIndicator: () ->
        @indicator = document.createElement('div')
        @indicator.classList.add 'indicator'
        @prepend @indicator
        $('.indicator').slideDown 300

    stopLoadIndicator: () ->
        $('.indicator').slideUp 100, ->
            @remove()

    render: (resultset) ->
        for x in @tables when x.queryid == resultset.queryid
            x.table.appendData(resultset.rows)
            return

        @querynumber += 1
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
            querynumber:@querynumber
            rowcount: resultset.rowcount
            whitespace: "nowrap"
        for c in resultset.columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            c["width"] = 200
            c["formatter"] = SlickFormatting.DefaultFormatter
            max = 0
            for d in resultset.rows?
                if d[c["field"]] != null && d[c["field"]]?.toString()?.length > max
                    max = d[c["field"]].toString().length
            max = Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))
            c["width"] = if resultset.columns.length > 1 then Math.min(max, 250) else max
        if resultset.rowcount <= 100 and not resultset.onlyOne
            height = ''.concat(resultset.rowcount * 30 + 30, 'px')
        else
            height = '100%'
        autoTranspose = atom.config.get('pg-hoff.autoTranspose')
        if autoTranspose and resultset.onlyOne and resultset.rowcount <= 2 and resultset.columns.length > 5
            @addClass 'transpose'
            options.transpose = true
            height = '100%'
        else if options.rowNumberColumn
            @addClass 'row-numbers'

        for table in @tables when table.pinned and table.nrrows <= 100
            $(table.table).height(''.concat(table.nrrows * 30 + 30, 'px'))
        table = new TableView options, resultset.rows, resultset.columns , height
        @tables.push {table:table, queryid:resultset['queryid'], nrrows: resultset.rowcount, pinned:false, querynumber: @querynumber}
        @append table

    initialize: ->
        super()
        @errorMarkers = []
        @tables = []
        @querynumber = 0
        @selectedquery = 0
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()
        @subscriptions.add atom.commands.add 'body', 'core:cancel': => @clear()

    updateNotComplete: (newBatch, result, queryNumber, bufferRange) ->
        if newBatch
            query.marker.destroy() for query in @processedQueries?
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

        if (JSON.stringify bufferRange.start).toString() == (JSON.stringify bufferRange.end).toString()
            bufferRange = atom.workspace.getActiveTextEditor().getBuffer().getRange()
        if queryNumber > 1
            bufferRange.start = @processedQueries[queryNumber-2].range.end

        atom.workspace.getActiveTextEditor().scanInBufferRange(new RegExp(@escapeRegExp(result.query)), bufferRange, (hit) => @queryHit(hit, queryInfo) )

    updateRendering: (result) ->
        for query in @processedQueries
            if query.queryId == result.queryid
                setTimeout( () =>
                    unless query.marker.isDestroyed() or query.marker? == false
                        try
                            atom.workspace.getActiveTextEditor().decorateMarker(query.marker, type: 'line-number', class: 'query-rendering')
                        catch err
                            console.error 'Could not decorate marker', query.marker
                , 300)

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
                editor.decorateMarker(marker, type: 'line-number', class: classType) if marker?

                @setErrorMarker(result, query)

                setTimeout( () =>
                    marker.destroy()
                , timeout)

    clear: () ->
        query.marker.destroy() for query in @processedQueries
        marker.destroy() for marker in @errorMarkers

    queryHit: (hit, queryInfo) =>
        editor = atom.workspace.getActiveTextEditor()
        marker = editor.markBufferRange(hit.range, invalidate: 'overlap')
        queryInfo.range = hit.range
        queryInfo.marker = marker
        @processedQueries.push queryInfo

        editor.decorateMarker(marker, type: 'line-number', class: 'query-loading') if marker?
    escapeRegExp: (str) ->
        str = str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
        return str.replace(/(?:\r\n|\r|\n)/g, '[\\r?\\n]');

    setErrorMarker: (result, query) ->
        unless /LINE [0-9]+:/.test(result.error)
            return
        matches = result.error.match('^(.+)\n((LINE ([0-9]+): )(.+))\n([ ]+\\^)')
        pointAt = matches[6].length - matches[3].length
        description = matches[1]
        line = matches[4]
        part = matches[5]
        #part may contain "..." before and after, strip and move point
        if /^\.\.\..*\.\.\.$/.test(part)
            part = part.substring(3, part.length-3)
            pointAt -= 3
        else if /^\.\.\..*$/.test(part)
            part = part.substring(3, part.length)
            pointAt -= 3
        else if /^.*\.\.\.$/.test(part)
            part = part.substring(0, part.length-3)

        range = new Range(new Point(query.range.start.row + parseInt(line) - 1,0), new Point(query.range.start.row + parseInt(line),0))
        queryPart = atom.workspace.getActiveTextEditor().getTextInRange(range)
        errorStart = queryPart.indexOf(part)
        rangeY = errorStart + pointAt - 1

        markerRange = new Range(new Point(query.range.start.row + parseInt(line) - 1, rangeY), new Point(query.range.start.row + parseInt(line) - 1,rangeY + 1))
        m = atom.workspace.getActiveTextEditor().markBufferRange(markerRange, invalidate: 'touch')
        lineCount = atom.workspace.getActiveTextEditor().getLineCount()
        item = document.createElement('div')
        item.classList.add 'arrow_box'
        if query.range.start.row + parseInt(line) == lineCount
            item.classList.add 'bottom'
        else
            item.classList.add 'top'
        item.textContent = description
        atom.workspace.getActiveTextEditor().decorateMarker(m, {class: 'query-error-overlay', type:'overlay', item}, position:'head') if m?

        @errorMarkers.push(m)


    focusFirstResult: => $(".slick-cell.l0.r0").first().click()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = ResultsPaneView
