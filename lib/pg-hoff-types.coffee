class PgHoffTypes
    @Type:
        1184:
            name: 'Timestamptz'
            format: (value) ->
                if value == 'None'
                  return null
                return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
            compare: (left, right) ->
                return Date.parse(left) - Date.parse(right)
        1114:
            name: 'Timestamp'
            format: (value) ->
                if value == 'None'
                  return null
                return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
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
        1043:
            name: 'Character Varying'
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
        20:
            name: 'Bigint'
            compare: (left, right) ->
                return left - right
        114:
            name: 'JSON'
            format: (text) ->
                return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
