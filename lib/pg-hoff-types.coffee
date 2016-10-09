class PgHoffTypes
    @Type:
        1184:
            name: 'Timestamp'
            format: (value) ->
                return value #new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
            compare: (left, right) ->
                return Date.parse(left) - Date.parse(right)
        23:
            name: 'Integer'
            compare: (left, right) ->
                return left - right
        25:
            name: 'Text'
            compare: (left, right) ->
                if left < right
                    return -1
                else if left > right
                    return 1
                else
                    return 0
        701:
            name: 'Numeric'
            compare: (left, right) ->
                return left - right
        114:
            name: 'JSON'
            format: (text) ->
                return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
