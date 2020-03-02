Promise = require('promise')
{exec, spawn} = require('child_process')
fs = require('fs')
path = require ('path')
os = require ('os')


cmd = (c) ->
    return new Promise((fulfil, reject) ->
        exec(c, (error, stdout, stderr) ->
            if error?
                reject(error)

            fulfil(stdout)
        )
    )

findTheHoff = (startPath, filter) ->
    files = fs.readdirSync(startPath).filter (x) -> x[0] != '.' and x != 'node_modules'
    for file in files
        filename = path.join(startPath, file)
        stat = fs.lstatSync(filename)
        if stat.isDirectory()
            try
                f = findTheHoff(filename, filter)
                return f if f?
            catch e
                console.error 'E', e
        else if path.parse(filename).base == filter
            return filename

    return null

spawnHoffServer = (command, args) ->
    resolved = false
    return new Promise((fulfil, reject) ->
        host = atom.config.get('pg-hoff.host')
        host = host.match('(?:http://)(.*)')[1]
        host = host.substr(0, host.lastIndexOf(':'))
        hoffpath = atom.config.get('pg-hoff.hoffServerPath')
        hoffServerPythonCommand = atom.config.get('pg-hoff.hoffServerPythonCommand')
        s = null

        if fs.existsSync(path.join hoffpath, 'pghoffserver.py')
            atom.config.set('pg-hoff.hoffServerPath', path.parse(hoffpath).dir)
            hoffpath = path.parse(hoffpath).dir
        else if fs.existsSync(path.join os.homedir(), '.pghoffserver', 'src', 'pg-hoffserver', 'pghoffserver', 'pghoffserver.py')
            atom.config.set('pg-hoff.hoffServerPath', path.join os.homedir(), '.pghoffserver', 'src', 'pg-hoffserver', 'pghoffserver')
            hoffpath = path.parse(path.join os.homedir(), '.pghoffserver', 'src', 'pg-hoffserver', 'pghoffserver').dir
        else if hoffpath.indexOf('pghoffserver.py') != -1 and fs.existsSync(hoffpath)
            atom.config.set('pg-hoff.hoffServerPath', path.parse(path.join hoffpath, '../').dir)
            hoffpath = path.parse(path.join hoffpath, '../').dir
        else if hoffpath? and not fs.existsSync(path.join hoffpath, 'pghoffserver', 'pghoffserver.py')
            atom.notifications.addWarning('Pg-Hoffserver not found, searching...')
            hoffpath = findTheHoff(os.homedir(), 'pghoffserver.py')
            if hoffpath?
                hoffpath = path.parse(path.join hoffpath, '../').dir
                atom.config.set('pg-hoff.hoffServerPath', hoffpath)
                atom.notifications.addInfo('Found the hoff!')
            else
                atom.notifications.addError('Could not find the hoff :(')
                return

        s = spawn(hoffServerPythonCommand, ['gunicorn_python.py', 'pghoffserver:app', '--bind', host], { env: process.env, detached: true, cwd: (path.join hoffpath, 'pghoffserver') })
        s.stdout.on 'data', (data)      -> fulfil(data.toString()) if not resolved
        s.stderr.on 'data', (data)      -> fulfil('stderr ' + data.toString()) if not resolved
        s.on 'close', (code)            -> reject('close ' + code) if not resolved
    )
        .then (data) ->
            resolved = true
            throw "Spawn, wrong output " + data unless /Starting gunicorn/.test(data)
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
                throw('Could not find domain socket.')
            return cmd 'lsof -t /tmp/pghoffserver.sock'
                .catch (err) ->
                    return checkPort(interval, tries)

killHoffServer = (restart) ->
    return cmd 'lsof -t /tmp/pghoffserver.sock'
        .then (pid) ->
            console.debug 'Killing PID', pid
            for p in pid.split '\n' when p.length > 0
                cmd "kill #{p}"
            return
        .then () ->
            console.debug 'Pg-hoff-server killed'
            if restart
                return maybeStartServer()
        .catch (err) ->
            console.debug 'Killing pg-hoffserver failed (probably not running)'
            if restart
                return maybeStartServer()
maybeStartServer = ->
    return cmd 'lsof -t /tmp/pghoffserver.sock'
        .then ->
            # Already running, great!
            console.debug 'Pghoffserver already running'
            return checkPort(50, 10)
        .catch (err) ->
            return true unless atom.config.get('pg-hoff.startServerAutomatically')

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
