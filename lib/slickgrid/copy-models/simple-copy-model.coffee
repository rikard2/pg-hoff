CopyModel = hrequire '/slickgrid/copy-models/copy-model'

module.exports = class SimpleCopyModel extends CopyModel
    constructor: () ->
    onCopy: (selection, columns) ->
        console.log 'yeah boy', selection, columns


        cols = {}
        rows = {}
        for n in selection
            cols[n.x] = true
            rows[n.y] = {} unless rows[n.y]

            rows[n.y][n.x] = n.value

        if Object.keys(cols).length == 1 or Object.keys(rows).length == 1
            return selection.map( (x) -> return x.value).join(', ')

        output = ''
        for row in Object.keys(rows)
            r = ''
            for col, i in Object.keys(cols)
                r += ', ' if i > 0
                if rows[row][col]?
                    r += rows[row][col]
                else
                    r += '?'
            output += r + '\n'
        return output


    getName: () -> 'Simple'

    formatCell: (columnType, cellValue) ->
        if cellValue == null
            return 'NULL'
        return cellValue.toString()

        if columnType not in ['integer', 'bigint', 'numeric', 'real']
            return "'" + cellValue + "'"
        else
            return cellValue
