CopyProvider = require './copy-provider'

module.exports = class JsonCopyProvider extends CopyProvider
    constructor: () ->
    onCopy: (selection, columns) ->
        console.log 'seleciton', selection
        if selection.length != 1
            atom.notifications.addError('Only one cell should be selected')
            throw('Only one cell should be selected')
        try
            value = JSON.parse(selection[0].value)
            s = JSON.stringify(value, null, "    ")
            console.log 'parsed', s
            return s
        catch err
            console.log 'err', err
            return null
    getName: () -> 'Beautified JSON'
