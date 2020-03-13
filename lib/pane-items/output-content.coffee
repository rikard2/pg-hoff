{View, $}                           = require 'space-pen'
{Emitter, CompositeDisposable}      = require 'atom'
Converter                           = require 'ansi-to-html'

class OutputPaneItemContent extends View
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
          statusmessage.classList.add 'notice-bar'
          @listenCopy(statusmessage, resultset.statusmessage)
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
          message.style['min-width'] = '200px'
          statusmessage.appendChild runtime
          statusmessage.appendChild message
          @outputContainer.append statusmessage
      if resultset.error
          error = document.createElement('pre')
          @listenCopy(error, resultset.error)
          error.classList.add 'notice-bar'
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
              notice = @notice('notice', n.substr(9))

              @outputContainer.append notice
      if resultset.messages?.length > 0
          for n in resultset.messages
              message = @notice('messages', n)
              @outputContainer.append message

  listenCopy: (element, text) ->
      element.addEventListener 'click', () ->
          element.classList.add 'notice-bar-flash'
          setTimeout(
            () ->
                element.classList.remove 'notice-bar-flash',
            500
          )
          atom.clipboard.write(text)

  notice: (type, text) ->
      div = document.createElement('div')
      @listenCopy(div, text)
      div.classList.add 'notice-bar'
      notice = document.createElement('pre')
      notice.classList.add type
      notice.textContent = text
      notice.style['float'] = 'left'
      notice.style['min-width'] = '300px'

      clear = document.createElement('div')
      clear.style['clear'] = 'both'

      div.appendChild(notice)
      div.appendChild(clear)

      return div

  clear: ->
    @outputContainer.empty()

  destroy: ->

module.exports = OutputPaneItemContent
