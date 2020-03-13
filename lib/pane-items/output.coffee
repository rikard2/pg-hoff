{Emitter, CompositeDisposable}      = require 'atom'
{$, View}                           = require 'space-pen'
window.jQuery                       = require 'jquery'
OutputPaneItemContent               = require './output-content'
TableView                           = require '../slickgrid/table-view'

class OutputPaneItem extends View
    @table: null
    id: null
    @content: ->
        @div class: 'gulp-pane', style: 'overflow: auto !important; font-family:menlo', =>

    getTitle: () => 'Output',
    getId: () => @id,
    getURI: () => 'atom://my-package/output-view',
    getDefaultLocation: () => 'left'

    initialize: () ->
        @id = @uuidv4()

    uuidv4: () ->
        'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
            r = Math.random() * 16 | 0
            v = if c == 'x' then r else r & 0x3 | 0x8
            v.toString 16

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
