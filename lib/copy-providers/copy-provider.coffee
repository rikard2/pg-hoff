ValuesCopyProvider = require './values-copy-provider'
PgHoffDialog       = require('../pg-hoff-dialog')
module.exports = class CopyProvider
    constructor: () ->
    @PromptCopy: (selectedColumns) =>
        providers = []
        providers.push new ValuesCopyProvider
        for provider in providers
            provider.name = provider.getName()
            provider.value = provider

        return PgHoffDialog.PromptList(providers)
            .then (provider) =>
                if provider?
                    return provider.onCopy(selectedColumns)
                    
                return null
            .then (copy) =>
                if copy?
                    atom.clipboard.write(copy)
                return selectedColumns
    getName: () -> 'SET NAME HERE'
