Request = require('request')
Promise = require('promise')

module.exports =
class PgHoffServerRequest
    constructor: () ->
    @Get: (path, data) ->
        console.log 'going'
        return new Promise((fulfil, reject) ->
            host = atom.config.get('pg-hoff.host')

            if (new RegExp('/$').test(host))
                host = host + path
            else
                host = host + '/' + path

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
                else
                    json = null
                    try
                        json = JSON.parse(body)
                    catch err then ->
                        reject(err)
                        atom.notifications.addError('Could not parse JSON: ' + json)

                    fulfil(json)
            )
        )

    @Post: (path, data) ->
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
                    json = null
                    try
                        json = JSON.parse(body)
                    catch err then ->
                        reject(err)
                        atom.notifications.addError('Could not parse JSON: ' + json)

                    fulfil(json)
            )
        )
