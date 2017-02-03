SlickGrid = require 'bd-slickgrid/grid'

class SlickG extends SlickGrid
    constructor: ->
        super()
        @autosizeColumns = ->
          updateCanvasWidth(true)
          widths = []
          shrinkLeeway = 0
          total = 0
          prevTotal = 0
          availWidth = canvasWidth
          for i in [0...columns.length]
            c = columns[i];
            widths.push(c.width);
            total += c.width;
            if c.resizable
              shrinkLeeway += c.width - Math.max(c.minWidth, absoluteColumnMinWidth);

          # grow
          prevTotal = total;
          while total < availWidth
            growProportion = availWidth / total;
            c = columns[columns.length -1];
            if !c.resizable || c.maxWidth <= c.width
                continue;

            growSize = Math.min(Math.floor(growProportion * c.width) - c.width, (c.maxWidth - c.width) || 1000000) || 1;
            total += growSize;
            widths[columns.length -1] += growSize;
            if prevTotal == total
              break;

            prevTotal = total;

          reRender = false;
          for i in [0...columns.length]
            if columns[i].rerenderOnResize && columns[i].width != widths[i]
              reRender = true;

            columns[i].width = widths[i];


    # function autosizeColumns() {
    #   updateCanvasWidth(true)
    #   var i, c,
    #       widths = [],
    #       shrinkLeeway = 0,
    #       total = 0,
    #       prevTotal,
    #       availWidth = canvasWidth // viewportHasVScroll ? viewportW - scrollbarDimensions.width : viewportW;
    #   for (i = 0; i < columns.length; i++) {
    #     c = columns[i];
    #     widths.push(c.width);
    #     total += c.width;
    #     if (c.resizable) {
    #       shrinkLeeway += c.width - Math.max(c.minWidth, absoluteColumnMinWidth);
    #     }
    #   }
    #
    #   // grow
    #   prevTotal = total;
    #   while (total < availWidth) {
    #     var growProportion = availWidth / total;
    #     c = columns[columns.length -1];
    #     if (!c.resizable || c.maxWidth <= c.width) {
    #         continue;
    #     }
    #     var growSize = Math.min(Math.floor(growProportion * c.width) - c.width, (c.maxWidth - c.width) || 1000000) || 1;
    #     total += growSize;
    #     widths[columns.length -1] += growSize;
    #     if (prevTotal == total) {  // avoid infinite loop
    #       break;
    #     }
    #     prevTotal = total;
    #   }
    #
    #   var reRender = false;
    #   for (i = 0; i < columns.length; i++) {
    #     if (columns[i].rerenderOnResize && columns[i].width != widths[i]) {
    #       reRender = true;
    #     }
    #     columns[i].width = widths[i];
    #   }
    #
    #   applyColumnHeaderWidths();
    #   updateCanvasWidth(true);
    #   if (reRender) {
    #     invalidateAllRows();
    #     render();
    #   }
    # }
