{Emitter, CompositeDisposable} = require 'atom'
{$, View}                      = require 'space-pen'
window.jQuery                  = require 'jquery'
TableView                      = require '../slickgrid/table-view'

class AnalyzePaneItem extends View
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    load: (explain) ->
        @empty()
        @append explain

    initialize: () ->
        @emitter = new Emitter()
        @subscriptions = new CompositeDisposable()

    refresh: =>
        @table.resize()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = AnalyzePaneItem
