{Emitter, CompositeDisposable}      = require 'atom'
ResultsPaneItem                     = require './results'
OutputPaneItem                      = require './output'
HoffEyePaneItem                     = require './hoffeye'
Helper                              = require '../helper'

module.exports =
class PaneManager
    options     : {
        position: 'bottom',
        shouldExistInCertainDock: true
    }
    resultsPane : null
    outputPane  : null
    hoffEyePane : null
    panes       : []
    eyePanes    : []

    constructor: (options) ->
        @options = Object.assign(@options, options);
        atom.workspace.observePaneItems () ->
        atom.workspace.onDidAddPane () ->

        atom.workspace.onWillDestroyPaneItem((item) =>
            @removePane(item.item)
        )
        atom.workspace.onDidChangeActivePaneItem (pane) =>
            if pane?.constructor?.name == 'ResultsPaneItem'
                pane.refresh()

    removePane: (pane) =>
        index = @panes.indexOf pane
        @panes.splice index, 1 if index isnt -1
        @resultsPane = null if pane is @resultsPane
        @outputPane = null if pane is @outputPane
        pane = null

    addPane: (position) ->
        pane = atom.workspace.getRightDock().addPane()

    newHoffEyePane: (alias) ->
        hoffEyePane = new HoffEyePaneItem(alias)

        atom.workspace.getRightDock().getActivePane().addItem(hoffEyePane)
        atom.workspace.getRightDock().activate()
        atom.workspace.getRightDock().getActivePane().activateNextItem()

        return hoffEyePane

    getPreferredDock: () ->
        preferredDock = atom.config.get('pg-hoff.preferredDock')

        dock = atom.workspace.getBottomDock()

        if preferredDock == 'left'
            dock = atom.workspace.getLeftDock()
        else if preferredDock == 'right'
            dock = atom.workspace.getRightDock()

        return dock

    shouldAddResultsPane: (dock) ->
        dock = @getPreferredDock()

        return true unless @resultsPane?

        if atom.config.get('pg-hoff.shouldExistInCertainDock')
            for paneItem in dock.getPaneItems()
                if paneItem.constructor.name == 'ResultsPaneItem'
                    if @resultsPane && paneItem.getId() == @resultsPane.getId()
                        return false
        else
            if @resultsPane?
                return false

        return true

    shouldAddOutputPane: (dock) ->
        dock = @getPreferredDock()

        return true unless @outputPane?

        if atom.config.get('pg-hoff.shouldExistInCertainDock')
            for paneItem in dock.getPaneItems()
                if paneItem.constructor.name == 'OutputPaneItem'
                    if @outputPane && paneItem.getId() == @outputPane.getId()
                        return false
        else
            if @outputPane?
                return false

        return true

    createOutputItem: () ->
        index = @panes.indexOf @outputPane
        @panes.splice index, 1 if index isnt -1

        @outputPane = new OutputPaneItem()
        @panes.push @outputPane

    createResultsItem: () ->
        index = @panes.indexOf @resultsPane
        @panes.splice index, 1 if index isnt -1

        @resultsPane = new ResultsPaneItem()
        @panes.push @resultsPane

    openDock: () ->
        preferredDock = atom.config.get('pg-hoff.preferredDock')
        dock = @getPreferredDock()

        shouldAddResultsPane = @shouldAddResultsPane(dock)
        shouldAddOutputPane = @shouldAddOutputPane(dock)

        @resultsPane.reset() if !shouldAddResultsPane

        if atom.config.get('pg-hoff.outputAsPane')
            if shouldAddResultsPane
                @createResultsItem()

                if shouldAddOutputPane
                    dock.getActivePane().addItem(@resultsPane)
                else
                    if preferredDock in ['bottom', 'left']
                        pane = dock.getActivePane().splitRight({
                            items: [ @resultsPane ]
                        })
                    else if preferredDock == 'right'
                        pane = dock.getActivePane().splitDown({
                            items: [ @resultsPane ]
                        })
                    dock.getActivePane().setFlexScale(2.5)


            if shouldAddOutputPane
                @createOutputItem()

                if preferredDock in ['bottom', 'left']
                    pane = dock.getActivePane().splitLeft({
                        items: [@outputPane]
                    })
                else if preferredDock == 'right'
                    pane = dock.getActivePane().splitUp({
                        items: [ @outputPane ]
                    })
                dock.getActivePane().setFlexScale(0.4)
        else
            dock.getActivePane().setFlexScale(1)
            if shouldAddOutputPane
                @createOutputItem()
                dock.getActivePane().addItem(@outputPane)
            if shouldAddResultsPane
                @createResultsItem()
                dock.getActivePane().addItem(@resultsPane)

        resizeTimeout = null
        obs = new ResizeObserver (r) =>
            clearTimeout(resizeTimeout)
            resizeTimeout = setTimeout(() =>
                pane.resize() for pane in @panes
            , 50)
        obs.observe(@resultsPane.element)


    findPaneDock: (p) ->
        for pane in atom.workspace.getBottomDock().getPaneItems()
            if p is pane
                console.log 'p <> pane', p.getId(), pane.getId()
                return atom.workspace.getBottomDock()

        for pane in atom.workspace.getLeftDock().getPaneItems()
            if p is pane
                return atom.workspace.getLeftDock()

        for pane in atom.workspace.getRightDock().getPaneItems()
            if p is pane
                return atom.workspace.getRightDock()

    getPanes: () -> return @panes

    hide: () ->
        resultsDock = @findPaneDock(@resultsPane)
        outputDock = @findPaneDock(@outputPane)
        resultsDock.hide() if resultsDock?
        outputDock.hide() if outputDock?

    switchToResultsPane: () ->
        dock = @findPaneDock(@resultsPane)
        return unless dock?
        dock.activate()
        dock.getActivePane().activateItemForURI('atom://pg-hoff/result-view')
        dock.activate()
        dock.show()

    switchToOutputPane: () ->
        dock = @findPaneDock(@outputPane)
        return unless dock?
        dock.activate()
        dock.getActivePane().activateItemForURI('atom://pg-hoff/output-view')
        dock.activate()
        dock.show()

    getResultsPane: () -> return @resultsPane
    getOutputPane: () -> return @outputPane
    getHoffEyePane: () ->
        return @hoffEyePane
