module.exports = class JSONModal
    @Show: (json) ->
        unless typeof(json) == 'object'
            try
                json = JSON.parse(json)
            catch
                json = "\"#{json}\""
                try
                    json = JSON.parse(json)
                catch
                    console.error 'could not parse json'
                    return

        return new Promise((fulfil, reject) ->
            element = document.createElement('div')
            element.classList.add('hoff-dialog')
            element.classList.add('native-key-bindings')
            jsonElement = element.appendChild document.createElement('pre')
            jsonElement.classList.add('native-key-bindings')
            jsonElement.style['overflow'] = 'auto'
            jsonElement.classList.add 'force-select'
            jsonElement.textContent = JSON.stringify json, null, '  '
            modal = atom.workspace.addModalPanel(item: element, visible: true)

            listener = (e) =>
                if e.keyCode == 27
                    document.body.removeEventListener 'keydown', listener
                    modal.destroy()

            document.body.addEventListener 'keydown', listener
        )
