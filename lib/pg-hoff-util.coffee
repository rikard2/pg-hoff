Promise = require('promise')
{exec, execSync} = require('child_process')

maybeStartServer = ->
    return new Promise (fulfil, reject) ->
        if -1 == atom.config.get('pg-hoff.host').indexOf 'localhost'
            return fulfil()
        alreadyRunning = ->
            try
                res = execSync('pgrep -f pghoffserver')
            catch error
                return false
            return true
        if alreadyRunning()
            return fulfil()
        exec('pghoffserver')
        checkIfDone = (timer) =>
            if alreadyRunning()
                return fulfil()
            if timer > 1000
                return reject()
            setTimeout((() => checkIfDone(timer + 50)), 50)
        checkIfDone 0

module.exports =
    'maybeStartServer': maybeStartServer
