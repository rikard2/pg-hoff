{Emitter, CompositeDisposable}      = require 'atom'
{$}                                 = require 'space-pen'
parseInterval                       = require 'postgres-interval'
window.jQuery                       = require 'jquery'
{DockPaneView, TableView, Toolbar}  = require 'atom-bottom-dock'
TableView                           = require '../slickgrid/table-view'
OutputView                          = require './output-view'

class ResultsPaneView extends DockPaneView
    @table: null
    getId: () -> 'results'
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>
        #@subview 'toolbar', new Toolbar()

    reset: () ->
        @empty()

    formatter: (row, cell, value, columnDef, dataContext) ->
        if value == null
            return "<span style='color:#fcc81e;font-weight:bold;font-style:italic;'>NULL</span>";
        if columnDef.type == "boolean"
            if value == true
                return "<span style='color:#a2ff6d;font-weight:bold;'>true</span>";
            else
                return "<span style='color:#ff816d;font-weight:bold;'>false</span>";
        if columnDef.type in ['timestamp with time zone', 'timestamp without time zone']
            return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
        if columnDef.type in ['time with time zone', 'time without time zone']
            return new Date('2000-01-01 ' + value).toLocaleTimeString(atom.config.get('pg-hoff.locale'))
        if columnDef.type == 'json'
            return JSON.stringify(JSON.parse(value), null, '   ')
        return value

    startLoadIndicator: () ->
        @indicator = document.createElement('div')
        @indicator.classList.add 'indicator'
        @prepend @indicator
        $('.indicator').slideDown 300

    stopLoadIndicator: () ->
        $('.indicator').slideUp 100, ->
            @remove()

    render: (resultset) ->
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

        for c in resultset.columns
            c["sortable"] = true
            c["rerenderOnResize"] = true
            c["id"] = c["field"]
            c["width"] = 200
            c["formatter"] = @formatter
            max = 0
            for d in resultset.rows
                if d[c["field"]] != null && d[c["field"]]?.toString().length > max
                    max = d[c["field"]].toString().length
            c["width"] = Math.min((Math.max(max * 9, Math.round((c["name"].length * 8.4) + 12))), 250)

        if resultset.rows.length <= 100
            height = ''.concat(resultset.rows.length * 30 + 30, 'px')
        else
            height = '100%'

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
