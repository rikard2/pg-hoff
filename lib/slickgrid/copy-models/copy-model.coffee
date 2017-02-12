ValuesCopyModel                 = require './values-copy-model'
JsonCopyModel                   = require './json-copy-model'
PgHoffDialog                    = require('../../dialog')

module.exports = class CopyModel
    constructor: () ->
    @PromptCopy: (selectedColumns, columns) =>
        models = []
        models.push new ValuesCopyModel
        models.push new JsonCopyModel
        for model in models
            model.name = model.getName()
            model.value = model

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
