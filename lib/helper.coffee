module.exports = class Helper
    @GenerateUUID: () ->
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
            r = Math.random() * 16 | 0
            v = if c == 'x' then r else r & 0x3 | 0x8
            return v.toString 16

    @Timeout: (ms) ->
        return new Promise((fulfil) ->
            setTimeout(() ->
                fulfil()
            , ms)
        )

    @CountDistinctKey: (arr, key) -> new Set(arr.flatMap (x) -> x[key]).size
