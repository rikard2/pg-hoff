class PgHoffTypes
    @Type:
        'timestamp with time zone':
            format: (value)         -> return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
            compare: (left, right)  -> return Date.parse(left) - Date.parse(right)
        'timestamp':
            format: (value)         -> return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
            compare: (left, right)  -> return Date.parse(left) - Date.parse(right)
        'integer':
            compare: (left, right)  -> return left - right
        'text':
            compare: (left, right)  -> if left < right then -1 else ( if left > right then 1 else 0 )
        'character varying':
            compare: (left, right)  -> if left < right then -1 else ( if left > right then 1 else 0 )
        'numeric':
            compare: (left, right)  -> return left - right
        'bigint':
            compare: (left, right)  -> return left - right
        'json':
            format: (text)          -> return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
