PgHoffServerRequest = hrequire '/server-request'

module.exports = class Snippets
    @CachedSnippets: {}


    @Fetch = () ->
        return PgHoffServerRequest.Post('list_snippets', {})
            .then (snippets) ->
                Snippets.CachedSnippets = snippets.snippets

                return snippets

    @Get = () -> return Snippets.CachedSnippets

    @Set = (snippet) ->
        return PgHoffServerRequest.Post('set_snippet', snippet)
            .then () ->
                return Snippets.Fetch()
