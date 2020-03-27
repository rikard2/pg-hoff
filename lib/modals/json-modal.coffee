HoffWindow = hrequire '/windows/window'

module.exports = class JSONModal
    @Show: (json) ->
        unless typeof(json) == 'object'
            try
                json = JSON.stringify JSON.parse(json), null, '  '
            catch
                json = json

        return new Promise((fulfil, reject) ->
            w = new HoffWindow({
                title: 'JSON content'
            })
            jsonElement = document.createElement('textarea')
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

            w.show(jsonElement)
        )
