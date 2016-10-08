Promise = require('promise')
PgHoffServerRequest     = require './pg-hoff-server-request'

class PgHoffListServersView
    fulfil: null
    reject: null

    constructor: (serializedState) ->
        @element = document.createElement('div')
        @element.classList.add 'pg-hoff-list-servers'

    escapeKeyCaptured: () ->
        if @reject
            @reject('Escape key captured')

    select: (panel) ->
        listServersView = @
        return PgHoffServerRequest.Get 'listservers'
            .then (servers) ->
                promise = listServersView.update(servers, listServersView.element)
                panel.show()

                return promise
            .then (selectedServer) ->
                request =
                    alias: selectedServer.alias,
                    authkey: ''

                return PgHoffServerRequest.Post 'connect', request
            .then (response) ->
                if response.errormessage
                    throw(response.errormessage)

                return response

    update: (servers, element) ->
        return new Promise( (resolve, reject) ->
            while (element.firstChild)
                element.removeChild(element.firstChild)

            for server of servers
                servers[server].alias = server
                container = element.appendChild document.createElement('div')
                container.classList.add 'server'

                container.onclick = ->
                    resolve(servers[server])

                title = container.appendChild document.createElement('div')
                title.classList.add 'title'
                title.textContent = server

                url = container.appendChild document.createElement('div')
                url.classList.add 'url'
                url.innerHTML = servers[server].url + ' &#10003;'
                if servers[server].connected
                    url.classList.add 'connected'
        )

    serialize: ->

    destroy: ->
        @element.remove()

    getElement: ->
        @element

module.exports = PgHoffListServersView
