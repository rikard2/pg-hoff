Promise = require('promise')

class PythonCommunication

    @GetEnvironment: () ->
        env = process.env

    @GetProcess: () ->
        env = process.env

        pythonProcess = require('child_process').spawn(
            'python', [__dirname + '/../node_modules/pg-hoffserver/pghoffserver/node_interface.py'], env: env
        )

        return pythonProcess

    @Request: (method, parameters) ->
        return new Promise((fulfill, reject) ->
            req =
                method: method
                parameters: parameters
            base64 = Buffer.from(JSON.stringify(req))
            pythonProcess = PythonCommunication.GetProcess()

            pythonProcess.stdin.write(base64);
            pythonProcess.stdin.end()

            output = null
            pythonProcess.stdout.on 'data', (data) =>
                output = JSON.parse(data.toString())

            pythonProcess.on 'exit', (code) ->
                if code == 0
                    fulfill output
                else
                    throw 'Invalid exit code: #{code}'
        )

module.exports = PythonCommunication
