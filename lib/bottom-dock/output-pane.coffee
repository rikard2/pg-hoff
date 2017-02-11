{Emitter, CompositeDisposable}      = require 'atom'
{$}                                 = require 'space-pen'
window.jQuery                       = require 'jquery'
{DockPaneView, TableView, Toolbar}  = require 'atom-bottom-dock'
OutputView                          = require './output-view'
TableView                           = require '../slickgrid/table-view'

class OutputPaneView extends DockPaneView
    @table: null
    getId: () -> 'output'

    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    render: (resultset) ->
        if not @outputView
            @outputView = new OutputView resultset
            @append @outputView
        else
            @outputView.append(resultset)

    initialize: ->
        super()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()

    refresh: =>
        @outputView.refresh()

    stop: =>
        @outputView.stop()

    clear: =>
        if @outputView
            @outputView.clear()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = OutputPaneView
