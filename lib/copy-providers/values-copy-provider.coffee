CopyProvider = require './copy-provider'

module.exports = class ValuesCopyProvider extends CopyProvider
    constructor: () ->
    onCopy: (selection, columns) ->
        columnNames = []
        selectedColumns = {}
        for cell in selection
            selectedColumns[cell.x] = ( selectedColumns[cell.x] ? 0 ) + 1
        last = null
        for col, value of selectedColumns
            if last? and last != value
                atom.notifications.addError('All columns should have the same number of rows!')
                throw('All columns should have the same number of rows!')
            last = value
        arr = []
        rows = {}
        for col in Object.keys(selectedColumns)
            columnNames.push(columns[col].name)
            for row in selection
                if row.x == parseInt(col)
                    if not rows[row.y]?
                        rows[row.y] = []
                    rows[row.y].push(["'", row.value, "'"].join(''))
        for col in Object.keys(rows)
            arr.push(rows[col])
        z = arr.join("""),\n           (""")
        y = columnNames.join(', ')
        result = """SELECT *
FROM (
    VALUES (#{z})
) X (#{y})"""
        console.log 'result', result
        return result
        

    getName: () -> 'Values'
