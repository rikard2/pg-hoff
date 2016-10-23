class PgHoffTypes
    @Type:
        'timestamp with time zone':
            format: (value)         -> return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
        'timestamp':
            format: (value)         -> return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
        'json':
            format: (text)          -> return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
