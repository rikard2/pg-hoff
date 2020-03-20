ValuesCopyModel                 = require './values-copy-model'
JsonCopyModel                   = require './json-copy-model'
PlainTextCopyModel               = require './plaintext-copy-model'

PgHoffDialog                    = require('../../dialog')

module.exports = class CopyModel
    constructor: () ->

    @CopyDefault: (selectedColumns, columns) =>
        model = new PlainTextCopyModel

        copy = model.onCopy(selectedColumns, columns)
        if copy?
            atom.clipboard.write(copy)
            console.log 'copy!', copy, atom.clipboard.read()
            return selectedColumns

        return null

    @PromptCopy: (selectedColumns, columns) =>

        models = []
        models.push new ValuesCopyModel
        models.push new JsonCopyModel
        models.push new PlainTextCopyModel
        for model in models
            model.name = model.getName()
            model.value = model
        console.log 'prompting', models
        return PgHoffDialog.PromptList(null, models)
            .then (model) =>
                if model?
                    return model.onCopy(selectedColumns, columns)
                return null
            .then (copy) =>
                if copy?
                    atom.clipboard.write(copy)
                return selectedColumns

    getName: () -> ''
