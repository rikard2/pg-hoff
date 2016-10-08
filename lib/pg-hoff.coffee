PgHoffView              = require './pg-hoff-view'
PgHoffServerRequest     = require './pg-hoff-server-request'
PgHoffResultsView       = require './pg-hoff-results-view'
PgHoffListServersView   = require './pg-hoff-list-servers-view'

{CompositeDisposable, Disposable} = require 'atom'

module.exports = PgHoff =
    pgHoffView: null
    modalPanel: null
    subscriptions: null
    resultsView: null
    listServersView: null
    listServersViewPanel: null

    config:
        pollInterval:
            type: 'integer',
            default: 100
        host:
            type: 'string'
            default: 'http://localhost:5000'

    activate: (state) ->
        console.debug 'Activating the greatest plugin ever...'
        @pgHoffView             = new PgHoffView(state.pgHoffViewState)
        @resultsView            = new PgHoffResultsView(state.pgHoffViewState)
        @listServersView        = new PgHoffListServersView(state.pgHoffViewState)

        pgHoff = @

        editor = atom.workspace.getActiveTextEditor()
        editorView = atom.views.getView(editor).addEventListener 'keyup', (event) ->
            if (event.keyCode == 27)
                pgHoff.listServersView.escapeKeyCaptured()

        #@modalPanel = atom.workspace.addModalPanel(item: @pgHoffView.getElement(), visible: false)
        @listServersViewPanel = atom.workspace.addModalPanel(item: @listServersView.getElement(), visible: false)

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @listServers()
        #@subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:execute-query': => @executeQuery()

    deactivate: ->
        @modalPanel.destroy()
        @subscriptions.dispose()
        @pgHoffView.destroy()

    serialize: ->
        pgHoffViewState: @pgHoffView.serialize()

    listServers: ->
        pgHoff = @
        @listServersView.select(@listServersViewPanel)
            .then (server) ->
                atom.notifications.addSuccess('Connected to ' + server.alias)
            .catch (error) ->
                if error == 'Already connected to server.'
                    atom.notifications.addInfo(error)
                else
                    atom.notifications.addError(error)
            .finally ->
                pgHoff.listServersViewPanel.hide()

    executeQuery: ->
        console.log 'execute query'
###
    atom.workspace.addBottomPanel(item: @resultsView.getElement())

    poll = @poll
    update = @update
    pollResults = @pollResults
    resultsView = @resultsView
    selectedText = atom.workspace.getActiveTextEditor().getSelectedText()
    if selectedText
      selectedText = selectedText.trim()

    @query(selectedText)
      .then( (url) ->
        return poll(0, url, poll, update, resultsView, pollResults)
      ).then( () ->
        console.log 'ALL DONE!!!'
      )
      .catch( (error) ->
        atom.notifications.addError(error)
        console.log 'catch', error
      )

  update: (x, resultsView) ->
    resultsView.update(x)

  pollResults: (url) ->
    if (!new RegExp('^http(s)?:\/\/').test(url))
      url = 'http://' + url

    return new Promise((fulfil, reject) ->
      options =
        method: 'GET',
        url: url,
        headers:
          'cache-control': 'no-cache',
          'content-type': 'multipart/form-data;'

      request(options, (error, response, body) ->
        if error
          reject(error)
          atom.notifications.addError('pg-hoff error: ' + error)
          return

        fulfil(body)
      )
    )

  poll: (counter, url, poll, update, resultsView, pollResults, f, r) ->
    counter = counter + 1
    interval = atom.config.get('pg-hoff.pollInterval')

    if counter == 100
      if r
        r('To many iterations (100)')

      return

    return new Promise((fulfil, reject) ->
      setTimeout( () ->
        pollResults(url).then( (res) ->
          x = JSON.parse(res)[0]
          if !x
            reject('No result.')
            return
          update(x, resultsView)
          if x && x.executing
            # HERE IS WHERE YOU KEEP THE TIMEOUT LOOP GOING!
            return poll(counter, url, poll, update, resultsView, pollResults, fulfil, reject)
          else
            # IF NOT EXECUTING, HERE IS WHERE YOU END THE TIMEOUT LOOP!
            if f
              # HOW THE PROMISE NOT RESOLVE HERE???.... WTF
              f(x)
            else
              fulfil(x)
        ).catch( (err) ->
          console.log 'error___', err
          # ERROR, END THE TIMEOUT LOOP
          if r
            r(err)
          else
            reject(err)
        )

      , interval)
    )

  query: (sql) ->
    return new Promise((fulfil, reject) ->
      host = atom.config.get('pg-hoff.host')
      if (new RegExp('/$').test(host))
        host = host + 'query'
      else
        host = host + '/query'

      options =
        method: 'POST',
        url: host,
        headers:
          'cache-control': 'no-cache',
          'content-type': 'multipart/form-data;'
        formData:
          query: sql
      request(options, (error, response, body) ->
        if error
          reject(error)
          atom.notifications.addError('pg-hoff error: ' + error)
          return

        re = new RegExp("[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$")

        if re.test
          # Great
          fulfil(body)
        else
          reject(body)
          atom.notifications.addError('body ' + body + ' is not a valid response')
      )
    )
###
