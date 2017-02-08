{Emitter} = require 'atom'
{View, $} = require 'space-pen'

class PgHoffStatus extends View
    alias: null
    transactionStatus: null
    @content: (config) ->
        @div class: 'bottom-dock-status-container inline-block', style: 'text-decoration: none;cursor:default;display: inline-block', =>
            @span outlet: 'span'

    initialize: (config) ->
        @emitter = new Emitter
        @span.textContent = 'PgHoff'

        @on 'click', @toggleClicked
        
    renderText: () =>
        alias = @alias ? 'NO_CONN'
        tran = @transactionStatus
        if tran?
            tran = ' - ' + tran
        else
            tran = ''

        @span[0].textContent = "Pg-hoff #{alias}#{tran}" 

    setVisiblity: (value) =>
        if value
            @show()
        else
            @hide()

    toggleClicked: =>
        @emitter.emit 'status:toggled'

    onDidToggle: (callback) ->
        @emitter.on 'status:toggled', callback

module.exports = PgHoffStatus
