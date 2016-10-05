module.exports =
class PgHoffResultsView
  constructor: (serializedState) ->
    @element = document.createElement('div')
    @element.classList.add('pg-hoff-results-view')

  createTable: (x) ->
    console.log 'creating table from', x
    container = document.createElement('div')
    container.classList.add('table')

    if x.executing
      pre = document.createElement('pre')
      pre.textContent = x.query
      container.classList.add('executing')
      container.appendChild(pre)
      return container

    table = document.createElement('table')

    col_tr = document.createElement('tr')
    for c in x.columns
      col_tr.appendChild(@createTh(c.name))
      table.appendChild(col_tr)

    for r in x.rows
      row_tr = document.createElement('tr')
      i = 0
      for c in r
        row_tr.appendChild(@createTd(c, x.columns[i].type_code))
        i = i + 1
      table.appendChild(row_tr)

    container.appendChild(table)
    return container

  createTh: (text) ->
    th = document.createElement('th')
    th.textContent = text
    return th

  createTd: (text, typeCode) ->
    td = document.createElement('td')
    td.textContent = text
    if (typeCode == 114)
      pre = document.createElement('pre')
      pre.textContent = JSON.stringify(JSON.parse(text), null, '  ')
      td.textContent = ""
      td.appendChild(pre)
    return td

  serialize: ->

  update: (x) ->
    console.log('UPDATING...', @element)
    while (@element.firstChild)
      @element.removeChild(@element.firstChild)

    @element.appendChild(@createTable(x))

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
