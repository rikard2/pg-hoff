{Emitter, CompositeDisposable}      = require 'atom'
{DockPaneView, TableView, Toolbar}  = require 'atom-bottom-dock'
{$}                                 = require 'space-pen'
window.jQuery                       = require 'jquery'
TableView                           = require '../slickgrid/table-view'

class AnalyzePaneView extends DockPaneView
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    load: (explain) ->
        @empty()
        @append explain

    initialize: () ->
        super()
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()

    refresh: =>
        @table.resize()
    stop: =>
        @outputView.stop()

    clear: =>
        @outputView.clear()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = AnalyzePaneView
