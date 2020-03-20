CopyModel = hrequire '/slickgrid/copy-models/copy-model'

module.exports = class PlainTextCopyModel extends CopyModel
    constructor: () ->
    onCopy: (selection, columns) ->

        lens = selection.reduce(((acc, curr) ->
            len = (curr.value or '').toString().length
            acc[curr.x] = Math.max(acc[curr.x] or 0, columns[curr.x].name.length, len)
            return acc
        ), {})

        reallengths = []
        for row in Object.keys(lens)
            reallengths.push(lens[row])

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
                    rows[row.y].push(@formatCell(columns[col].type, row.value))
        for col in Object.keys(rows)
            arr.push(rows[col])

        z = arr.join("""),\n           (""")
        y = columnNames.join(', ')
        output = ""

        for i in [0..columnNames.length-1]
            if i > 0
                output += ' | '
            output += columnNames[i].padEnd(reallengths[i], ' ')
        output += '\n'

        for i in [0..columnNames.length-1]
            if i > 0
                output += '-+-'
            output += ''.padEnd(reallengths[i], '-')
        output += '\n'

        for row in arr
            for i in [0..row.length-1]
                if i > 0
                    output += ' | '
                output += row[i].padEnd(reallengths[i], ' ')

            output += '\n'

        return output


    getName: () -> 'PlainText'

    formatCell: (columnType, cellValue) ->
        if cellValue == null
            return 'NULL'
        return cellValue.toString()

        if columnType not in ['integer', 'bigint', 'numeric', 'real']
            return "'" + cellValue + "'"
        else
            return cellValue
