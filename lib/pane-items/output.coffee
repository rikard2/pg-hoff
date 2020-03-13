{Emitter, CompositeDisposable}      = require 'atom'
{$, View}                           = require 'space-pen'
window.jQuery                       = require 'jquery'
OutputPaneItemContent               = require './output-content'
TableView                           = require '../slickgrid/table-view'

class OutputPaneItem extends View
    @table: null

    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    getTitle: () => 'Output',
    getURI: () => 'atom://my-package/output-view',
    getDefaultLocation: () => 'left'

    render: (resultset) ->
        if not @outputView
            @outputView = new OutputPaneItemContent resultset
            @append @outputView
        else
            @outputView.append(resultset)

    clear: =>
        if @outputView
            @outputView.clear()

    destroy: ->
        @subscriptions.dispose()
        @remove()

module.exports = OutputPaneItem
