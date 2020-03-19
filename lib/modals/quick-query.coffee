TableView       = require('../slickgrid/table-view')
SlickFormatting = require('../slickgrid/formatting')
Helper          = require('../helper')
DBQuery         = require('../dbquery')
module.exports = class QuickQuery
    @Show: (sql, alias) ->
        console.log 'alias', alias
        d = new DBQuery(sql, alias)

        #if resultset.rowcount <= 100 and not resultset.onlyOne
        #    height = ''.concat(resultset.rowcount * 30 + 30, 'px')
        #else
        #    height = '100%'
        #autoTranspose = atom.config.get('pg-hoff.autoTranspose')

        #if autoTranspose and resultset.rowcount <= 2 and resultset.columns.length > 5
        #    @addClass 'transpose'
        #    options.transpose = true
        #    height = '100%'
        #else if options.rowNumberColumn
        #    @addClass 'row-numbers'

        #for table in @tables when table.pinned and table.nrrows <= 100
        #    $(table.table).height(''.concat(table.nrrows * 30 + 30, 'px'))

        d.executePromise()
            .then (r) ->
                return new Promise((fulfil, reject) ->
                    element = document.createElement('div')
                    element.classList.add('hoff-dialog')
                    element.classList.add('native-key-bindings')
                    #element.appendChild(table.element)
                    e = element.appendChild document.createElement('textarea')
                    e.classList.add('native-key-bindings')
                    e.style['overflow'] = 'auto'
                    e.style['width'] = '100%'
                    e.style['height'] = '1px'
                    e.style['font-family'] = 'Menlo'
                    e.style['border'] = 'none'
                    e.style['background'] = 'transparent'
                    e.style['white-space'] = 'pre'
                    e.style['overflow-wrap'] = 'normal'
                    e.style['overflow-x'] = 'scroll'
                    e.wrap = 'soft'
                    e.classList.add 'force-select'

                    options =
                        enableCellNavigation: false
                        enableColumnReorder: true
                        multiColumnSort: false
                        forceFitColumns: false
                        fullWidthRows: false
                        rowHeight:25
                        headerRowHeight: 30
                        asyncPostRenderDelay: 500
                        syncColumnCellResize: true
                        multiSelect:true
                        cellFlashingCssClass: "flashcell"
                        rowNumberColumn: true
                        queryid: Helper.GenerateUUID()
                        querynumber: @querynumber
                        gridid: Helper.GenerateUUID()
                        rowcount: r.result.rowcount
                        whitespace: "nowrap"
                    table = new TableView options, r.result.rows, r.result.columns, 100
                    table.element.style['height'] = '600px'

                    element.appendChild(table.element)

                    modal = atom.workspace.addModalPanel(item: element, visible: true)

                    atom.commands.add(e, {
                        'core:cancel': (event) =>
                            console.log 'cancel'
                            modal.destroy()
                            event.stopPropagation()
                    })
                    e.focus()
                    e.addEventListener 'blur', () ->
                        console.log 'blur'
                        modal.destroy()
                )
            .catch (x) ->
                console.log 'catch', x
