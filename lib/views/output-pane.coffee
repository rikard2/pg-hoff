{DockPaneView, TableView, Toolbar} = require 'atom-bottom-dock'
TableView = require './hoff-table-view'
{Emitter, CompositeDisposable} = require 'atom'
OutputView = require './output-view'
{$} = require 'space-pen'
window.jQuery = require 'jquery'

class OutputPaneView extends DockPaneView
    @table: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>
            #@subview 'toolbar', new Toolbar()
            #@subview 'outputView', new OutputView()

    getId: () -> 'output'

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
