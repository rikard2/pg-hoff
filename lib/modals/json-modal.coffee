module.exports = class JSONModal
    @Show: (json) ->
        unless typeof(json) == 'object'
            try
                json = JSON.stringify JSON.parse(json), null, '  '
            catch
                json = json

        return new Promise((fulfil, reject) ->
            element = document.createElement('div')
            element.classList.add('hoff-dialog')
            element.classList.add('native-key-bindings')
            jsonElement = element.appendChild document.createElement('textarea')
            jsonElement.classList.add('native-key-bindings')
            jsonElement.style['overflow'] = 'auto'
            jsonElement.style['width'] = '100%'
            jsonElement.style['height'] = '600px'
            jsonElement.style['font-family'] = 'Menlo'
            jsonElement.style['border'] = 'none'
            jsonElement.style['background'] = 'transparent'
            jsonElement.style['white-space'] = 'pre'
            jsonElement.style['overflow-wrap'] = 'normal'
            jsonElement.style['overflow-x'] = 'scroll'
            jsonElement.wrap = 'soft'
            jsonElement.classList.add 'force-select'
            jsonElement.value = json
            modal = atom.workspace.addModalPanel(item: element, visible: true)

            atom.commands.add(jsonElement, {
                'core:cancel': (event) =>
                    modal.destroy()
                    event.stopPropagation()
            })
            jsonElement.focus()
            jsonElement.addEventListener 'blur', () ->
                console.log 'blur'
                #modal.destroy()
        )
