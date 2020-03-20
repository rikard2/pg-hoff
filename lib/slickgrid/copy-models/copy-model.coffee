ValuesCopyModel    = hrequire '/slickgrid/copy-models/values-copy-model'
JsonCopyModel      = hrequire '/slickgrid/copy-models/json-copy-model'
PlainTextCopyModel = hrequire '/slickgrid/copy-models/plaintext-copy-model'
PgHoffDialog       = hrequire('/dialog')

module.exports = class CopyModel
    constructor: () ->

    @CopyDefault: (selectedColumns, columns) =>
        model = new PlainTextCopyModel

        copy = model.onCopy(selectedColumns, columns)
        if copy?
            atom.clipboard.write(copy)
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
