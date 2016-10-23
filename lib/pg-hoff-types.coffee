timestamp =
    format: (value) -> new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
time =
    format: (value) -> new Date('2000-01-01 ' + value).toLocaleTimeString(atom.config.get('pg-hoff.locale'))
class PgHoffTypes
    @Type:
        'timestamp with time zone': timestamp
        'timestamp without time zone': timestamp
        'time with time zone': time
        'time without time zone': time
        'json':
            format: (text)          -> return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
