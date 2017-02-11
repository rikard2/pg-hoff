parseInterval = require 'postgres-interval'
intervalSize = (i) ->
    if i is null then return Infinity
    interval = parseInterval i
    days = (interval.days || 0) + 30 * (interval.months || 0) + 365 * (interval.years || 0)
    hours = (interval.hours || 0) + 24 * days
    minutes = (interval.minutes || 0) + 60 * hours
    seconds = (interval.seconds || 0) + 60 * minutes
timestamp =
    format: (value) ->
        if value is null then null
        else new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
time =
    format: (value) ->
        if value is null then null
        else new Date('2000-01-01 ' + value).toLocaleTimeString(atom.config.get('pg-hoff.locale'))
interval =
    compare: (left, right) ->
        intervalSize(left) - intervalSize(right)

class PgHoffTypes
    @Type:
        'timestamp with time zone': timestamp
        'timestamp without time zone': timestamp
        'time with time zone': time
        'time without time zone': time
        'interval': interval
        'json':
            format: (text)          -> return JSON.stringify(JSON.parse(text), null, '  ')

module.exports = PgHoffTypes
