CopyModel = hrequire '/slickgrid/copy-models/copy-model'

module.exports = class JsonCopyModel extends CopyModel
    constructor: () ->
    onCopy: (selection, columns) ->
        if selection.length != 1
            atom.notifications.addError('Only one cell should be selected')
            throw('Only one cell should be selected')
        try
            value = JSON.parse(selection[0].value)
            s = JSON.stringify(value, null, "    ")

            return s
        catch err
            return null
    getName: () -> 'Beautified JSON'
