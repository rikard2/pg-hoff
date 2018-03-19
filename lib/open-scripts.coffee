{Directory} = require 'atom'
path = require 'path';
fs = require 'fs'

openScripts = (data) ->
    basePath = atom.project.getPaths()[0]
    for row in data
        filePath = path.join basePath, getPath(row)
        atom.open(pathsToOpen: filePath)

writeScripts = (data) ->
    basePath = atom.project.getPaths()[0]
    for row in data
        filePath = path.join basePath, getPath(row)
        script = getScript row
        fs.writeFileSync filePath, script

writeAndOpenScripts = (data) ->
    writeScripts data
    openScripts data

showWriteScripts = (data) ->
    (getKey data[0], /^filepath\d*$/i) and (getKey data[0], /^script\d*$/i)

showWriteAndOpenScripts = (data) ->
    (getKey data[0], /^filepath\d*$/i) and (getKey data[0], /^script\d*$/i)

showOpenScripts = (data) ->
    (getKey data[0], /^filepath\d*$/i) and not (getKey data[0], /^script\d*$/i)

getKey = (dict, keyRegex) ->
    Object.keys(dict).filter((k) -> k.match(keyRegex))[0]

getScript = (row) ->
    row[getKey row, /^script\d*$/i]

getPath = (row) ->
    row[getKey row, /^filepath\d*$/i]

module.exports =
    'openScripts': openScripts,
    'writeScripts': writeScripts,
    'writeAndOpenScripts': writeAndOpenScripts,
    'showOpenScripts': showOpenScripts,
    'showWriteScripts': showWriteScripts,
    'showWriteAndOpenScripts': showWriteAndOpenScripts
