{Emitter, CompositeDisposable}      = require 'atom'
{$, View}                           = require 'space-pen'
window.jQuery                       = require 'jquery'
OutputPaneItemContent               = hrequire '/pane-items/output-content'
TableView                           = hrequire '/slickgrid/table-view'
Helper                              = hrequire '/helper'

class OutputPaneItem extends View
    @table: null
    id: null
    @content: ->
        @div
            class: 'gulp-pane'
            style: 'overflow: auto !important; font-family:menlo'

    getTitle            : () => 'Output',
    getId               : () => @id,
    getURI              : () => 'atom://pg-hoff/output-view',
    getDefaultLocation  : () => 'left'

    initialize: () ->
        @id = Helper.GenerateUUID()

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
        @remove()

module.exports = OutputPaneItem
