SlickFormatting = hrequire '/slickgrid/formatting'

module.exports = class TransposeSlickData
    columns: []
    rows: []

    constructor: (columns, rows) ->
        @columns = columns
        @rows = rows
        @transpose()

    transpose: =>
        # UserID    UserName
        # 123       apitest
        # 325       mamamia

        # COLUMNS => ROWS
        newRows = @columns.map (column, index) =>
            obj = {}
            obj["column"] = column.name
            for row, rowIndex in @rows
                for key, value of row
                    obj["row_#{rowIndex}"] = row[key] if key == column.field
            return obj
        newColumns = [
            defaultSortAsc:true
            field:"column"
            headerCssClass:'row-number'
            id:"column"
            minWidth:30
            focusable: false
            selectable: false
            name:""
            rerenderOnResize :true
            resizable:false
            sortable:false
            type:"text"
            type_code: 20
            width: 175
        ].concat(@rows.map (row, index) =>
            defaultSortAsc:true
            field:"row_#{index}"
            headerCssClass:'row-number'
            id:"row_#{index}"
            minWidth:30
            name:""
            formatter: SlickFormatting.DefaultFormatter
            rerenderOnResize :true
            resizable:false
            sortable:false
            type:"text"
            type_code: 20
            width: 300
        )
        @columns = newColumns
        @rows = newRows
