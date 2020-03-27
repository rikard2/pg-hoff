{CompositeDisposable, Disposable}   = require 'atom'
SlickGrid                           = hrequire '/../extlib/bd-slickgrid/grid'
CopyModel                           = hrequire '/slickgrid/copy-models/copy-model'
PgHoffConnection                    = hrequire '/connection'
QuickQuery                          = hrequire '/modals/quick-query'
Helper                              = hrequire '/helper'
PgHoffServerRequest                 = hrequire '/server-request'
SnippetModal                        = hrequire '/modals/snippet-modal'
PgHoffDialog                        = hrequire '/dialog'
PgHoffSnippets                      = hrequire '/snippets'

class WinningSelectionModel
    onSelectedRangesChanged: null
    activeRange: null
    activeRangeComplete: false
    ranges: []
    grid : null
    lastCell: {}
    startCell: {}
    subscriptions: null
    init: (grid) =>
        @grid = grid
        @grid.onClick.subscribe(@handleGridClick)
        @grid.onDblClick.subscribe(@onDoubleClick)
        @grid.onMouseEnter.subscribe(@onMouseEnter)
        @grid.onKeyDown.subscribe(@onKeyDown)
        @grid.onMouseDown.subscribe(@onMouseDown)
        @grid.onAnimationEnd.subscribe(@onAnimationEnd)
        @grid.onContextMenu.subscribe(@onContextMenu)
        @subscriptions = new CompositeDisposable
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:copy': => @onCopyCommand()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:local-query': => @onLocalQuery()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:new-snippet': => @newSnippet()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:edit-snippet': => @editSnippet()
        @subscriptions.add atom.commands.add 'atom-workspace', 'pg-hoff:snippet-query': => @snippetQuery()

        @contextMenuCommands = []
        @contextMenuItems = []
        @onSelectedRangesChanged = new Slick.Event

    chooseSnippet: (column) =>
        PgHoffServerRequest.Post('list_snippets', {})
            .then (r) ->
                snippets = r.snippets
                presentSnippets = []
                cols = Object.keys(snippets)
                for col in cols
                    sn = Object.keys(snippets[col])
                    for s in sn
                        if (column? and snippets[col][s]['column'] == column.toLowerCase()) or not column?
                            presentSnippets.push({
                                name: snippets[col][s]['name'],
                                value: snippets[col][s]
                            })
                return PgHoffDialog.PromptList(null, presentSnippets)
            .catch (err) ->
                console.log 'err', err

    editSnippet: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid
        column = @getSelectedColumn().name?.toLowerCase()
        @chooseSnippet(column)
            .then (chosen) =>
                return unless chosen.value
                chosen.value.replace = @getIds()

                SnippetModal.Edit(chosen.value)
                    .then (snippet) ->
                        return PgHoffServerRequest.Post('set_snippet', snippet)
                    .then () ->
                        atom.notifications.addSuccess('Snippet added for column ' + column)
                    .catch (err) ->
                        console.error(err)
                        atom.notifications.addError('Failed to add snippet')

    getSelectedColumn: () =>
        columns = @grid.getColumns()
        selectedColumns = @getSelectedColumns()
        count = Helper.CountDistinctKey(selectedColumns, 'x')
        if count != 1
            #atom.notifications.addError('Only one column is allowed')
            return

        return columns[selectedColumns[0].x]

    getIds: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid

        column = @getSelectedColumn().name.toLowerCase()

        columns = @grid.getColumns()
        selectedColumns = @getSelectedColumns()

        vals = selectedColumns.flatMap (x) -> x['value']
        return {} unless vals? and vals.length > 0

        ids = vals.join(',')

        return {
            ids: ids,
            id: vals[0]
        }

    newSnippet: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid
        column = @getSelectedColumn().name.toLowerCase()

        SnippetModal.Edit({ name: '#Snippet name#', column: column, sql: 'SELECT 1', replace: @getIds()})
            .then (done) ->
                newSnippet = {
                    id: Helper.GenerateUUID(),
                    column: column,
                    name: done.name,
                    sql: done.sql
                }
                return PgHoffServerRequest.Post('set_snippet', newSnippet)
            .then () ->
                atom.notifications.addSuccess('Snippet added for column ' + column)
            .catch (err) ->
                console.error(err)
                atom.notifications.addError('Failed to add snippet')

    snippetQuery: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid

        column = @getSelectedColumn().name.toLowerCase()

        columns = @grid.getColumns()
        selectedColumns = @getSelectedColumns()

        count = Helper.CountDistinctKey(selectedColumns, 'x')
        if count != 1
            atom.notifications.addError('Only one column is allowed')
            return

        @chooseSnippet(column)
            .then (snippet) ->
                vals = selectedColumns.flatMap (x) -> x['value']
                ids = vals.join(',')

                query = snippet.value.sql
                query = query.replace('$IDS$', vals)
                if vals.length > 0
                    query = query.replace('$ID$', vals[0])

                alias = atom.workspace.getActiveTextEditor()?.alias
                if alias?
                    QuickQuery.Show(query, alias)
                else
                    PgHoffConnection.CompleteConnect()
                        .then (r) =>
                            if r.alias?
                                QuickQuery.Show(query, r.alias)

    onCoreCopy: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid
        columns = @grid.getColumns()
        selectedColumns = CopyModel.CopyDefault(@getSelectedColumns(), columns)
        if selectedColumns
            obj1 = {}
            obj2 = {}
            for cell in selectedColumns
                obj1[columns[cell.x]["field"]] = "copyFlash"
                obj2[cell.y] = obj1
            @grid.setCellCssStyles("copy_Flash", obj2)
            atom.workspace.getActivePane().activate()

        atom.workspace.getActivePane().activate()

    onCopyCommand: () =>
        return unless WinningSelectionModel.ActiveGrid == @grid

        columns = @grid.getColumns()
        CopyModel.PromptCopy(@getSelectedColumns(), columns)
            .then (selectedColumns) =>
                obj1 = {}
                obj2 = {}
                for cell in selectedColumns
                    obj1[columns[cell.x]["field"]] = "copyFlash"
                    obj2[cell.y] = obj1
                @grid.setCellCssStyles("copy_Flash", obj2)
                atom.workspace.getActivePane().activate()
            .catch (reason) ->
    onMouseDown: (e, args, local) =>
        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)
        @lastCell = x: cell.cell, y: cell.row
        @dragCell = cell

        return unless cell?
        if not (@activeRange and
        @activeRange.fromRow == @activeRange.toRow and
        @activeRange.fromCell == @activeRange.toCell and
        @activeRange.fromRow == cell.row and
        @activeRange.fromCell == cell.cell)
            @deSelect = false

        unless e.shiftKey or e.metaKey
            @activeRange = null
            @ranges = []

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        unless @activeRange?
            @startCell = x: cell.cell, y: cell.row
            @activeRange = new Slick.Range(cell.row, cell.cell, cell.row, cell.cell)

        else if not local?
            @increaseRange cell.cell, cell.row

         @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    increaseRange: (x, y) =>
        @activeRange.fromRow = Math.min(@startCell.y, y)
        @activeRange.toRow = Math.max(@startCell.y, y)

        @activeRange.fromCell = Math.min(@startCell.x, x)
        @activeRange.toCell = Math.max(@startCell.x, x)

    handleGridClick: (e, args) =>
        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)

        if @activeRange and
        @activeRange.fromRow == @activeRange.toRow and
        @activeRange.fromCell == @activeRange.toCell and
        @activeRange.fromRow == cell.row and
        @activeRange.fromCell == cell.cell and
        @deSelect == false
            @deSelect = true
            return
        else if @deSelect == true
            @deSelect = false
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
            return
        else
            @onMouseDown(e, args, true)

    @ActiveGrid: null # STATIC
    onKeyDown: (e, args) =>
        WinningSelectionModel.ActiveGrid = @grid
        data = @grid.getData()
        columns = @grid.getColumns()
        if @lastCell? and ( [ 37, 38, 39, 40 ].indexOf e.keyCode ) >= 0
            deltaX = 0
            deltaY = 0
            if e.keyCode == 37 and @lastCell? # LEFT
                deltaX = -1
            else if e.keyCode == 38 and @lastCell? # UP
                deltaY = -1
            else if e.keyCode == 39 and @lastCell? # RIGHT
                deltaX = 1
            else if e.keyCode == 40 and @lastCell? # DOWN
                deltaY = 1

            unless @lastCell.x
                @lastCell = {x:1, y:0}
                @startCell = {x:1, y:0}
                @activeRange = new Slick.Range 0, 1, 0, 1
                @onSelectedRangesChanged.notify [ @activeRange ]
                return

            cellCanBeSelected = @grid.canCellBeSelected(@lastCell.y + deltaY, @lastCell.x + deltaX)
            outOfBounds = true
            unless cellCanBeSelected == false or @lastCell.x + deltaX < 0 or @lastCell.x + deltaX >= columns.length
                @lastCell.x = @lastCell.x + deltaX
                outOfBounds = false

            unless cellCanBeSelected == false or @lastCell.y + deltaY < 0 or @lastCell.y + deltaY >= data.length
                @lastCell.y = @lastCell.y + deltaY
                outOfBounds = false

            unless outOfBounds
                if e.shiftKey
                    @increaseRange @lastCell.x, @lastCell.y
                else
                    @startCell = x: @lastCell.x, y: @lastCell.y
                    @activeRange = new Slick.Range @lastCell.y, @lastCell.x, @lastCell.y, @lastCell.x

                @onSelectedRangesChanged.notify [ @activeRange ]
        if e.keyCode == 27
            @ranges = []
            @activeRange = null
            @onSelectedRangesChanged.notify @ranges
        if e.keyCode == 65 and e.metaKey and data.length > 0
            @ranges = []
            firstColumn = 0
            firstColumn = 1 unless @grid.canCellBeSelected(0, 0)
            @activeRange = new Slick.Range 0, firstColumn, data.length - 1, columns.length - 1
            @onSelectedRangesChanged.notify [ @activeRange ]
        if (e.metaKey or e.ctrlKey) and e.keyCode == 67
            @.onCoreCopy()
            e.stopPropagation()

    getSelectedColumns: () =>
        selectedColumns = []
        data = @grid.getData()
        columns = @grid.getColumns()
        for range in @ranges.concat( [ @activeRange ] )
            continue unless range?
            for x in [range.fromCell..range.toCell]
                for y in [range.fromRow..range.toRow]
                    selectedColumns.push({x: x, y:y}) if @grid.canCellBeSelected(y, x)
        for cell in selectedColumns
            cell.value = data[cell.y][columns[cell.x]["field"]]
        return selectedColumns

    formatCell: (columnType, cellValue) ->
        if cellValue == null
            return 'NULL'
        else if atom.config.get('pg-hoff.quoteValues') and columnType not in ['integer', 'bigint', 'numeric', 'real']
            return "'" + cellValue + "'"
        else
            return cellValue

    onAnimationEnd: (e, args) =>
        @grid.removeCellCssStyles("copy_Flash")

    onDoubleClick: (e, args) =>


    onMouseEnter: (e, args) =>
        return unless e.buttons == 1 and e.button == 0

        cell = @grid.getCellFromEvent(e)
        return unless cell? and @grid.canCellBeSelected(cell.row, cell.cell)
        @lastCell = x: cell.cell, y: cell.row

        @activeRange = null

        if e.metaKey and @activeRange
            @ranges.push @activeRange
            @activeRange = null

        return unless @dragCell?
        @activeRange = new Slick.Range(@dragCell.row, @dragCell.cell, @dragCell.row, @dragCell.cell)

        @activeRange.fromRow = Math.min(@activeRange.fromRow, cell.row)
        @activeRange.toRow = Math.max(@activeRange.toRow, cell.row)

        @activeRange.fromCell = Math.min(@activeRange.fromCell, cell.cell)
        @activeRange.toCell = Math.max(@activeRange.toCell, cell.cell)
        @activeRangeComplete = true

        @onSelectedRangesChanged.notify @ranges.concat( [ @activeRange ] )

    onContextMenu: (e) =>
        e.preventDefault()
        cell = @grid.getCellFromEvent(e)
        columns = @grid.getColumns()
        columnname = columns[cell.cell]['name']
        target = '.' + e.target.classList[0] + '.' + e.target.classList[1]
        value = @grid.getData()[cell.row][columns[cell.cell]["field"]]
        column = @getSelectedColumn()?.name?.toLowerCase()
        columns = @grid.getColumns()
        selectedColumns = @getSelectedColumns()
        count = Helper.CountDistinctKey(selectedColumns, 'x')
        if count != 1
            return
        snippets = PgHoffSnippets.Get()
        command.dispose() for command in @contextMenuCommands
        item.dispose() for item in @contextMenuItems
        @contextMenuCommands = []
        @contextMenuItems = []
        presentSnippets = []
        menu = {}
        cols = Object.keys(snippets)
        for col in cols
            sn = Object.keys(snippets[col])
            for s in sn
                if (column? and snippets[col][s]['column'] == column.toLowerCase()) or not column?
                    presentSnippets.push({
                        name: snippets[col][s]['name'],
                        value: snippets[col][s]
                    })
                    snippet = snippets[col][s]
                    commandparams = {}
                    commandparams['pg-hoff:snippet-query-table-' + snippet.name] = (event) => @snippetQueryInline(snippet, selectedColumns)
                    command = atom.commands.add 'atom-workspace', commandparams
                    @contextMenuCommands.push(command)
                    menu[target] = [{
                        'label': 'Get ' + snippet.name + ' for ' + columnname + (if /\$IDS\$/.test(snippet.sql) then 's' else ''),
                        'command':'pg-hoff:snippet-query-table-' + snippet.name
                        }]
                    menuitem = atom.contextMenu.add menu
                    @contextMenuItems.push(menuitem)
        return


    snippetQueryInline: (snippet, selectedColumns) ->
        vals = selectedColumns.flatMap (x) -> x['value']
        ids = vals.join(',')

        query = snippet.sql
        query = query.replace('$IDS$', vals)
        if vals.length > 0
            query = query.replace('$ID$', vals[0])

        alias = atom.workspace.getActiveTextEditor()?.alias
        if alias?
            QuickQuery.Show(query, alias)
        else
            PgHoffConnection.CompleteConnect()
                .then (r) =>
                    if r.alias?
                        QuickQuery.Show(query, r.alias)
        command.dispose() for command in @contextMenuCommands
        item.dispose() for item in @contextMenuItems

    destroy: =>

module.exports = WinningSelectionModel
