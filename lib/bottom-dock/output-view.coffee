{View, $}                           = require 'space-pen'
{Emitter, CompositeDisposable}      = require 'atom'
Converter                           = require 'ansi-to-html'
{Toolbar}                           = require 'atom-bottom-dock'
OutputView                          = require './output-view'

class OutputView extends View
  @content: ->
    @div class: 'output-view', style: 'display:flex;', =>
      @div class: 'content-container', =>
        @div outlet: 'outputContainer'

  initialize: (resultset) ->
    if resultset.transaction_status == 'idle'
        @outputContainer.empty()
    @append(resultset)

  append: (resultset) ->
      if resultset.statusmessage?.length > 0
          statusmessage = document.createElement('pre')
          statusmessage.classList.add 'statusmessage'
          statusmessage.setAttribute 'title', resultset.query
          message = document.createElement('span')
          message.classList.add 'message'
          message.textContent = resultset.statusmessage
          runtime = document.createElement('span')
          runtime.setAttribute 'title', 'execution start: ' + resultset.timestamp
          runtime.textContent = resultset.runtime_seconds + ' sec'
          if resultset.runtime_seconds > 15
              runtime.classList.add 'runtime_long'
          else if resultset.runtime_seconds > 5
              runtime.classList.add 'runtime_medium'
          else if resultset.runtime_seconds > 0
              runtime.classList.add 'runtime_short'
          else
              runtime.classList.add 'runtime_instant'
              runtime.textContent =  'instant'
          statusmessage.appendChild runtime
          statusmessage.appendChild message
          @outputContainer.append statusmessage
      if resultset.error
          error = document.createElement('pre')
          error.classList.add 'error'
          errorHeader = document.createElement('span')
          errorHeader.classList.add 'errorheader'
          errorHeader.textContent = 'error'
          errorMessage = document.createElement('span')
          errorMessage.classList.add 'errormessage'
          errorMessage.textContent = resultset.error
          errorMessage.setAttribute 'title', resultset.query
          error.appendChild errorHeader
          error.appendChild errorMessage
          @outputContainer.append error
      if resultset.notices?.length > 0
          for n in resultset.notices
              notice = document.createElement('pre')
              notice.classList.add 'notice'
              notice.textContent = n.substr(9)
              @outputContainer.append notice
      if resultset.messages?.length > 0
          for n in resultset.messages
              message = document.createElement('textarea')
              message.style.width = '200px';
              message.style.height = '200px';
              message.classList.add 'messages'
              message.textContent = n
              message.onkeydown = (key, x) ->
                  #key.preventDefault();
                  console.log('key', message.getSelection())
              @outputContainer.append message

  clear: ->
    @outputContainer.empty()

  destroy: ->

module.exports = OutputView
