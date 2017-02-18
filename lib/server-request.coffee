Request = require('request')
Promise = require('promise')

module.exports =
class PgHoffServerRequest
    constructor: () ->
    @Get: (path, isRelative) ->
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
                    console.debug 'Error GET Request', error, response, body
                    reject(error)
                    atom.notifications.addError('HTTP: ' + error)
                else if response.statusCode != 200
                    console.debug 'Error GET Request', error, response, body
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
        if not isJson?
            isJson = true

        return new Promise((fulfil, reject) ->
            host = atom.config.get('pg-hoff.host')

            if (new RegExp('/$').test(host))
                host = host + path
            else
                host = host + '/' + path

            for key, value of data
                if not value?
                    data[key] = ''
                else if typeof value is 'object'
                    data[key] = JSON.stringify(value)


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
                    console.debug 'Error POST Request', error, response, body
                    reject(error)
                    atom.notifications.addError('HTTP: ' + error)
                else
                    if isJson
                        json = null
                        try
                            json = JSON.parse(body)
                        catch err then ->
                            throw('Could not parse JSON')
                            console.error 'Could not parse JSON';
                            atom.notifications.addError('Could not parse JSON: ' + json)

                        fulfil(json)
                    else
                        fulfil(body)
            )
        )

    @hoffingtonPost: (host, data) ->
        return new Promise((fulfil, reject) ->

            for key, value of data
                if not value?
                    data[key] = ''
                else if typeof value is 'object'
                    data[key] = JSON.stringify(value)

            options =
                method: 'POST'
                followAllRedirects: true
                url: host
                headers:
                    'cache-control': 'no-cache',
                    'content-type': 'x-www-form-urlencoded;'
                 form:
                    data
            #console.log options
            Request(options, (error, response, body) ->
                #console.log response
                if error
                    console.debug 'Error POST Request', error, response, body
                    reject(error)
                    atom.notifications.addError('HTTP: ' + error)
                else
                    fulfil(body)
            )
        )
