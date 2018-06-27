{Point, Range, Directory} = require 'atom'

gotoDeclaration = ->
    gotoIdentifier identifier for identifier in getIdentifiers atom.workspace.getActiveTextEditor()

getIdentifier = (cursor) ->
    options = {wordRegex: /[.\w]+/}
    new Range(cursor.getPreviousWordBoundaryBufferPosition(options), cursor.getNextWordBoundaryBufferPosition(options))

getIdentifiers = (editor) ->
    editor.getTextInRange(getIdentifier cursor) for cursor in editor.getCursors()

gotoIdentifier = (identifier) ->
    words = identifier.split '.'
    name    = if words.length > 1 then words[1] else words[0]
    schema  = if words.length > 1 then words[0] else 'public'
    path = [schema, null, name + '.sql']
    openFile(new Directory(base), path) for base in atom.project.getPaths()

openFile = (base, path) ->
    [head, path...] = path
    checkName = (file) -> not head or file.getBaseName().toLowerCase() == head.toLowerCase()
    if path.length > 0
        openFile(dir, path) for dir in base.getEntriesSync() when dir.isDirectory() and checkName dir
    else
        atom.open(pathsToOpen:[file.getPath()]) for file in base.getEntriesSync() when file.isFile() and checkName file

module.exports = gotoDeclaration
