PgHoffServerRequest = hrequire '/server-request'

module.exports = class Snippets
    @CachedSnippets: {}


    @List = () ->
        return PgHoffServerRequest.Post('list_snippets', {})
            .then (snippets) ->
                Snippets.CachedSnippets = snippets

                return snippets

    @GetCached = () -> return Snippets.CachedSnippets

    @Set = (snippet) ->
        return PgHoffServerRequest.Post('set_snippet', snippet)
            .then () ->
                return Snippets.List()
