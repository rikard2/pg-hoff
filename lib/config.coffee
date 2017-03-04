module.exports =
    host:
        type: 'string'
        default: 'http://unix:/tmp/pghoffserver.sock:/'
        order: 1
    pollInterval:
        type: 'integer',
        description: 'Poll interval in milliseconds.'
        minimum: 10
        maximum: 10000
        default: 100
        order: 2
    displayQueryExecutionTime:
        type: 'boolean'
        description: 'Display query execution time after the query is finished.'
        default: true
        order: 3
    autocompletionEnabled:
        type: 'boolean'
        default: true
        order: 4
    pascaliseAutocompletions:
        type: 'boolean'
        default: false
        description: 'user_name becomes User_Name'
        order: 5
    unQuoteFunctionNames:
        type: 'boolean'
        default: true
        description: '"sum"() becomes sum()'
        order: 6
    maximumCellValueLength:
        type: 'integer'
        minimum: 5
        maximum: 10000
        default: 40
        description: 'How long a cell value can be until you have to expand it.'
        order: 6
    locale:
        type: 'string'
        default: 'sv-SE'
        order: 7
    executeAllWhenNothingSelected:
        type: 'boolean'
        description: 'Execute all text in editor when no text is selected'
        default: true,
        order: 8
    formatColumns:
        type: 'boolean'
        description: 'This can possibly be slow'
        default: true
        order: 9
    defaultConnection:
        type: 'string'
        description: 'Alias of database connection to use for new tabs</br>Leave blank for no automatic connection'
        default: ''
        order: 10
    nullString:
        type: 'string'
        description: 'Representation of null values'
        default: 'NULL'
        order: 11
    autoTranspose:
        type: 'boolean'
        description: 'Auto transpose'
        default: true
        order: 12
    startServerAutomatically:
        type: 'boolean'
        description: 'Start server automatically'
        default: true
        order: 1
    hoffServerPath:
        type: 'string'
        default: ''
        order: 1
