{View, $} = require 'space-pen'
{Emitter, CompositeDisposable} = require 'atom'
GulpfileRunner = require '../gulpfile-runner'
Converter = require 'ansi-to-html'
{Toolbar} = require 'atom-bottom-dock'

class OutputView extends View
  @content: ->
    @div class: 'output-view', style: 'display:flex;', =>
      @div class: 'content-container', =>
        @div outlet: 'outputContainer' #, class: 'task-container'

  initialize: (resultset) ->
    @outputContainer.empty()
    @append(resultset)


  append: (resultset) ->
      if resultset.statusmessage?.length > 0
          notice = document.createElement('pre')
          notice.classList.add 'statusmessage'
          notice.textContent = resultset.statusmessage
          @outputContainer.append notice
      if resultset.error
          error = document.createElement('pre')
          error.classList.add 'error'
          error.textContent = resultset.error
          @outputContainer.append error
      if resultset.notices?.length > 0
          for n in resultset.notices
              notice = document.createElement('pre')
              notice.classList.add 'notice'
              notice.textContent = n
              @outputContainer.append notice

  clear: ->
    @outputContainer.empty()

  destroy: ->

module.exports = OutputView
