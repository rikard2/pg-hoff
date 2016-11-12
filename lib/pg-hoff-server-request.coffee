Request = require('request')
Promise = require('promise')
PythonCommunication = require('./python-communication')

module.exports =
class PgHoffServerRequest
    constructor: () ->
    @Get: (path, isRelative) ->
        console.log 'GET', path
        if path == 'listservers'
            return PythonCommunication.Request 'listservers', {}
                .then (response) ->
                    console.log 'response', response
                    return response

        if not isRelative?
            isRelative = true

        return new Promise((fulfil, reject) ->
            if isRelative
                host = atom.config.get('pg-hoff.host')

                if (new RegExp('/$').test(host))
                    host = host + path
                else
                    host = host + '/' + path
            else
                if (!new RegExp('^http(s)?:\/\/').test(path))
                    host = 'http://' + path
                else
                    host = path

            options =
                method: 'GET',
                url: host,
                headers:
                    'cache-control': 'no-cache',
                    'content-type': 'multipart/form-data;'

            Request(options, (error, response, body) ->
                if error
                    reject(error)
                    atom.notifications.addError('HTTP: ' + error)
                else if response.statusCode != 200
                    reject('Unexpected status code: ' + response.statusCode)
                    atom.notifications.addError('Unexpected status code: ' + response.statusCode)
                else
                    json = null
                    try
                        json = JSON.parse(body)
                    catch err then ->
                        throw('Could not parse JSON')
                        atom.notifications.addError('Could not parse JSON: ' + json)

                    fulfil(json)
            )
        )

    @Post: (path, data, isJson) ->
        console.log 'POST', path, data
        if not isJson?
            isJson = true

        return new Promise((fulfil, reject) ->
            host = atom.config.get('pg-hoff.host')

            if (new RegExp('/$').test(host))
                host = host + path
            else
                host = host + '/' + path

            options =
                method: 'POST',
                url: host,
                headers:
                    'cache-control': 'no-cache',
                    'content-type': 'multipart/form-data;'
                formData:
                    data

            Request(options, (error, response, body) ->
                if error
                    reject(error)
                    atom.notifications.addError('HTTP: ' + error)
                else
                    if isJson
                        json = null
                        try
                            json = JSON.parse(body)
                        catch err then ->
                            throw('Could not parse JSON')
                            atom.notifications.addError('Could not parse JSON: ' + json)

                        fulfil(json)
                    else
                        fulfil(body)
            )
        )
