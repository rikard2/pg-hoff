{View} = require 'space-pen'

class DecorationView extends View
    contentElement: null
    interval: null
    startTime: null
    @content: ->
        @div '.', class: 'results-overlay-parent', style: 'width: 200px;', =>
            @div class: 'results-overlay-child', style: 'width: 200px; height: 100px;', =>
                @div 'time taken', class: 'cnt'

    initialize: () ->
    completed: () ->
        @stopTimer()

        now = new Date().getTime()
        diff = (now - @startTime) / 1000

        @contentElement.textContent = 'Done in  ' + diff.toFixed(2) + ' s'

    startTimer: () ->
        @startTime = new Date().getTime()
        @interval = setInterval( () =>
            now = new Date().getTime()
            diff = (now - @startTime) / 1000

            @contentElement.textContent = 'Elapsed: ' + diff.toFixed(2) + ' s'
        , 100)

    stopTimer: () ->
        clearInterval(@interval)
    attached: (a) ->
        elements = @element.getElementsByClassName('cnt')
        @contentElement = elements[0]

        @startTimer()

module.exports = DecorationView
