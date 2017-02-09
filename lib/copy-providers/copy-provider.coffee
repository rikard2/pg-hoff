ValuesCopyProvider = require './values-copy-provider'
JsonCopyProvider = require './json-copy-provider'
PgHoffDialog       = require('../pg-hoff-dialog')
module.exports = class CopyProvider
    constructor: () ->
    @PromptCopy: (selectedColumns, columns) =>
        providers = []
        providers.push new ValuesCopyProvider
        providers.push new JsonCopyProvider
        for provider in providers
            provider.name = provider.getName()
            provider.value = provider

        return PgHoffDialog.PromptList(providers)
            .then (provider) =>
                if provider?
                    return provider.onCopy(selectedColumns, columns)
                return null
            .then (copy) =>
                if copy?
                    atom.clipboard.write(copy)
                return selectedColumns
    getName: () -> 'SET NAME HERE'
