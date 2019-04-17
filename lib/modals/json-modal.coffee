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
            element.style['width'] = '100%'
            element.style['height'] = '600px'
            jsonElement = element.appendChild document.createElement('textarea')
            jsonElement.classList.add('native-key-bindings')
            jsonElement.style['overflow'] = 'auto'
            jsonElement.style['width'] = '100%'
            jsonElement.style['font-family'] = 'menlo'
            jsonElement.style['height'] = '100%'
            jsonElement.style['border'] = 'none'
            jsonElement.value = JSON.stringify json, null, '  '
            modal = atom.workspace.addModalPanel(item: element, visible: true)
            jsonElement.focus()
            listener = (e) =>
                if e.keyCode == 27
                    e.stopPropagation();
                    document.body.removeEventListener 'keydown', listener
                    modal.destroy()

            document.body.addEventListener 'keydown', listener
        )
