CopyModel = require './copy-model'

module.exports = class JsonCopyModel extends CopyModel
    constructor: () ->
    onCopy: (selection, columns) ->
        #console.log 'seleciton', selection
        if selection.length != 1
            atom.notifications.addError('Only one cell should be selected')
            throw('Only one cell should be selected')
        try
            value = JSON.parse(selection[0].value)
            s = JSON.stringify(value, null, "    ")
            #console.log 'parsed', s
            return s
        catch err
            #console.log 'err', err
            return null
    getName: () -> 'Beautified JSON'
