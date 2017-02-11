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

        if resultset.rows.length <= 100
            height = ''.concat(resultset.rows.length * 30 + 30, 'px')
        else
            height = '100%'

        if resultset.onlyOne and resultset.rows.length <= 2 and resultset.columns.length > 5
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

    refresh: =>
        @outputView.refresh()

    stop: =>
        @outputView.stop()

    clear: =>
        @outputView.clear()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = ResultsPaneView
