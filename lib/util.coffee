Promise = require('promise')
{exec, spawn} = require('child_process')

cmd = (c) ->
    return new Promise((fulfil, reject) ->
        exec(c, (error, stdout, stderr) ->
            if error?
                reject(error)

            fulfil(stdout)
        )
    )
spawnHoffServer = (command, args) ->
    resolved = false
    return new Promise((fulfil, reject) ->
        hoffpath = atom.config.get('pg-hoff.hoffServerPath')
        s = null
        if hoffpath == 'pghoffserver'
            s = spawn(hoffpath, [''], { env: process.env, detached: true })
        else
            s = spawn('python', [ hoffpath ], { env: process.env, detached: true })

        s.stdout.on 'data', (data)      -> fulfil(data.toString()) if not resolved
        s.stderr.on 'data', (data)      -> fulfil('stderr ' + data.toString()) if not resolved
        s.on 'close', (code)            -> reject('close ' + code) if not resolved
    )
        .then (data) ->
            resolved = true
            throw 'Spawn, wrong output' unless /Running on/.test(data)
            return data

timeout = (ms) ->
    return new Promise((fulfil) ->
        setTimeout(() ->
            fulfil()
        , ms)
    )


checkPort = (interval, tries) ->
    tries = 10 unless tries?
    return timeout interval
        .then ->
            tries = tries - 1
            if tries <= 0
                throw('Could not find open port (5000).')
            return cmd 'lsof -i :5000'
                .catch (err) ->
                    return checkPort(interval, tries)
killHoffServer = (restart) ->
    return cmd 'lsof -i :5000 | grep Python | lsof -ti :5000'
        .then (pid) ->
            console.debug 'Killing PID', pid
            return cmd "kill #{pid}"
        .then () ->
            console.debug 'Pg-hoff-server killed'
            if restart
                return maybeStartServer()
        .catch (err) ->
            console.debug 'Killing pg-hoffserver failed (probably not running)'
            if restart
                return maybeStartServer()
maybeStartServer = ->
    return cmd 'pgrep -f pghoffserver'
        .then ->
            # Already running, great!
            console.debug 'Pghoffserver already running'
            return checkPort(50, 10)
        .catch (err) ->
            return true unless atom.config.get('pg-hoff.startServerAutomatically')
            return true unless /localhost|127\.0\.0\.1/.test atom.config.get('pg-hoff.host')

            # Could not find process, try to start
            console.debug 'Starting up pghoffserver'
            return spawnHoffServer()
                .catch (err) ->
                    console.debug 'Failed to start pghoffserver', err
                    throw 'Could not start pghoffserver!'
                .then () ->
                    # Successfully started pghoffserver, wait for port to open
                    console.debug 'Successfully started pghoffserver'
                    return checkPort(50, 10) # 50ms interval, 10 tries

module.exports =
    'maybeStartServer': maybeStartServer,
    'killHoffServer': killHoffServer
