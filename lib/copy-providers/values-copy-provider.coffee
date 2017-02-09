CopyProvider = require './copy-provider'

module.exports = class ValuesCopyProvider extends CopyProvider
    constructor: () ->
    onCopy: (selection) ->
        
        return "LENGTH #{selection.length}"

    getName: () -> 'Values'
