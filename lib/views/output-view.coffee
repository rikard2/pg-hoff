{View, $} = require 'space-pen'
{Emitter, CompositeDisposable} = require 'atom'
GulpfileRunner = require '../gulpfile-runner'
Converter = require 'ansi-to-html'
{Toolbar} = require 'atom-bottom-dock'

class OutputView extends View
  @content: ->
    @div class: 'output-view', style: 'display:flex;', =>
      @div class: 'content-container', =>
        @div outlet: 'outputContainer', class: 'task-container'

  initialize: (@resultsets) ->
      if not @renderedResults
          @renderedResults = []
      @outputContainer.empty()
      for resultset in @resultsets
        if resultset.complete and !resultset.queryid in @renderedResults
          @renderedResults.push(resultset.queryid)
          el = $('<pre>')
          el.append resultset.queryid
          @outputContainer.append el
      console.log @renderedResults

  clear: ->
    @outputContainer.empty()

  destroy: ->

module.exports = OutputView
