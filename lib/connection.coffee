Promise = require('promise')
PgHoffDialog = require('./dialog')
PgHoffServerRequest     = require './server-request'
{maybeStartServer}      = require './util'
{CompositeDisposable, Disposable} = require 'atom'

class PgHoffConnection
    fulfil: null
    reject: null

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add 'pg-hoff-list-servers'

        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add '.connected', 'pg-hoff:disconnect': (event) => @disconnect(event)

    connect: (panel) ->
        listServersView = @
        selectedServer = null
        maybeStartServer()
            .then (servers) ->
                return PgHoffServerRequest.Get 'listservers'
            .then (servers) =>
                items = []
                for server of servers
                    servers[server].alias = server
                    items.push name: server, value: servers[server], connected: servers[server].connected

                return PgHoffDialog.PromptList(items, @createServerElement)
                    .then (item) ->
                        return item.value
            .then (server) ->
                selectedServer = server
                requiresAuthKey = selectedServer.requiresauthkey == 'True' || selectedServer.requiresauthkey == '"True"'
                if not server.connected
                    if requiresAuthKey
                        return PgHoffDialog.PromptPassword('Enter Password')

                return ''
            .then (password) ->
                request =
                    alias: selectedServer.alias,
                    authkey: password

                if not selectedServer.connected
                    return PgHoffServerRequest.Post 'connect', request
                else
                    return { 'alias': selectedServer.alias }
            .then (response) ->
                if response.errormessage == 'Already connected to server.'
                    response.already_connected = true
                    return response
                else if response.errormessage?
                    throw(response.errormessage)

                return response

    disconnect: (event) ->
        alias = event.target.getAttribute('alias')
        return PgHoffServerRequest.Post 'disconnect', { alias: alias }
            .then (servers) ->
                atom.notifications.addSuccess('Successfully disconnected from ' + alias)
            .catch (err) ->
                atom.notifications.addError('Could not disconnect ' + err)

    createServerElement: (item) ->
        server = item.value
        container = document.createElement('li')
        container.classList.add 'server'

        title = container.appendChild document.createElement('div')
        title.classList.add 'title'
        title.textContent = server.alias

        if server.connected
            connected = container.appendChild document.createElement('div')
            connected.classList.add 'connected'
            connected.innerHTML = 'Connected'

        clear = container.appendChild document.createElement('div')
        clear.classList.add 'clear'

        return container

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffConnection
