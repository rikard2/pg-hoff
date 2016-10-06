PgHoffView = require './pg-hoff-view'
request = require('request')
Promise = require('promise')
AutocompleteProvider = require('pg-hoff-autocomplete-provider')

PgHoffResultsView = require './pg-hoff-results-view'
{CompositeDisposable} = require 'atom'

module.exports = PgHoff =
  pgHoffView: null
  modalPanel: null
  subscriptions: null
  resultsView: null
  provider: null
  config:
      pollInterval:
        type: 'integer',
        default: 100
      host:
        type: 'string'
        default: 'http://localhost:5000'

  activate: (state) ->
    console.log 'activate'
    @pgHoffView = new PgHoffView(state.pgHoffViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @pgHoffView.getElement(), visible: false)
    @resultsView = new PgHoffResultsView(state.pgHoffViewState)
    @runningQueries = []

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:toggle': => @toggle()

    unless @provider?
      AutocompleteProvider = require('./pg-hoff-autocomplete-provider')
      @provider = new AutocompleteProvider()

  provide: ->
    console.log 'provice', provide
    @provider

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @pgHoffView.destroy()

  serialize: ->
    pgHoffViewState: @pgHoffView.serialize()

  toggle: ->
    atom.workspace.addBottomPanel(item: @resultsView.getElement())

    poll = @poll
    update = @update
    pollResults = @pollResults
    resultsView = @resultsView
    if (!selectedText = atom.workspace.getActiveTextEditor())
      atom.notifications.addError('no editor selected')
      return

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
