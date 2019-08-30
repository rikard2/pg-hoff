class DataTable {
    constructor(rootElement) {
        this.config = require('./config.js');
        this.helper = require('./helper.js');
        var selectionmanager = require('./selection.js');
        this.selection = new selectionmanager();
        this.keyDownListener = null;

        this.escape = function() {};
        this.onFocus = function() {};

        this.rootElement = rootElement;
        this.create();
        var dis = this;
        this.selection.onSelectedRangesChanged = function(ranges) {
            dis.invalidateSoft(ranges);
            if (dis.selection.lastCell) {
                dis.onCellActive.apply(dis, [dis.selection.lastCell.x, dis.selection.lastCell.y]);
            }
        }
        this.selection.onCopy = function(ranges) {
            dis.onCopy.apply(dis, [ranges]);
        }
    }

    destroy() {
        document.removeEventListener("keydown", this.keyDownListener);
    }

    create() {
        this.rootElement.innerHTML = '';
        this.holders = this.createHolders()
        this.rootElement.append(this.holders.outerContainer);
        this.focus();
    }

    onCellActive(x, y) {
        var w = 0;
        for (var i = 0; i < x + 1; i++) {
            w += this.getColumn(i).width;
        }
        var h = (y + 1) * this.config.row.height;
        if (w >= (this.holders.viewport.clientWidth + this.holders.viewport.scrollLeft)) {
            this.holders.viewport.scrollLeft = w - this.holders.viewport.clientWidth;
        } else {
            var l = w - this.getColumn(x).width;
            if (this.holders.viewport.scrollLeft > l) {
                this.holders.viewport.scrollLeft = l;
            }
        }
        if (h >= (this.holders.viewport.clientHeight + this.holders.viewport.scrollTop)) {
            this.holders.viewport.scrollTop = h - this.holders.viewport.clientHeight;
        }
        h -= this.config.row.height;

        if (h <= (this.holders.viewport.scrollTop)) {
            this.holders.viewport.scrollTop = h;
        }
        this.focus();
    }

    onKeyDown(e) {
    }
    onMouseEnter(e) {
    }

    getCellValue(x, y) {
        return this.data.rows[y][x];
    }

    getCellValues(cells) {
        var str = '';
        str = cells.map(x => {
            return this.getCellValue(x[0], x[1]);
        }).join(',');
        return str;
    }

    onCopy(ranges) {
        const {clipboard} = require('electron')
        var str = '';
        str = ranges.map(x => {
            return this.getCellValue(x[0], x[1]);
        }).join(',');
        clipboard.writeText(str);
    }

    setData(data) {
        this.data = data;
        for (var i = 0; i < this.data.columns.length; i++) {
            this.data.columns[i].width = this.getColumnWidth(i);
        }
        this.selection.columns = this.data.columns.length;
        this.selection.rows = this.data.rows.length;
        this.selection.selectFirst();
        this.holders.numbers_inner.style.height = this.helper.px(this.config.row.height * this.data.rows.length);
        this.holders.viewport_content.style.height = this.helper.px(this.config.row.height * this.data.rows.length);
        this.invalidate();
    }

    invalidateSoft(selectionRanges) {
        this.focus();
        this.renderVisible(selectionRanges);
        this.renderColumns();
        if (this.selection.lastCell) {
            this.onViewportScroll();
        }
    }

    invalidate(selectionRanges) {
        this.holders.numbers_inner.innerHTML = '';
        this.holders.viewport_content.innerHTML = '';
        this.rowCache = {};
        this.renderVisible(selectionRanges);
        this.renderColumns();
    }

    focus() {
        this.holders.focustextbox.focus();
        this.onFocus();
    }
    createHolders() {
        var holders = {};
        holders.outerContainer = document.createElement('div')
        holders.focustextbox = document.createElement('input')
        holders.focustextbox.type = 'text';
        holders.focustextbox.style.position = 'absolute';
        holders.focustextbox.style.left = '-10000px';
        var dis = this;
        this.keyDownListener = function(e) {
            if (e.key == 'Escape') {
                dis.escape();
            } else {
                dis.selection.onKeyDown.apply(dis.selection, [e]);
            }
        };
        holders.focustextbox.addEventListener("keydown", this.keyDownListener);
        holders.outerContainer.appendChild(holders.focustextbox);
        holders.outerContainer.style.width = holders.outerContainer.style.height = '100%';
        holders.outerContainer.style.padding = '5px';
        holders.outerContainer.style['user-select'] = 'none';

        var css = `.col-resize:hover { cursor: col-resize; }
        .flashcell {
            background: #007a99;
            color: #333333;
            border: 5px solid #FFF;
        }
        .copyFlash {
            animation: fadeinout 800ms linear forwards;
        }
        @keyframes fadeinout {
          0% { background: #007a99; opacity: 0.7; }
          100% { opacity: 1;  }
          50% { opacity: 1; }
        }
        `;
        var style = document.createElement('style');
        style.appendChild(document.createTextNode(css));
        document.getElementsByTagName('head')[0].appendChild(style);


        holders.innerContainer = document.createElement('div')
        holders.innerContainer.style.display = 'flex';
        holders.innerContainer.className = 'dataview-inner_container';
        holders.innerContainer.style['flex-direction'] = 'column';
        holders.innerContainer.style['cursor'] = 'default';
        holders.innerContainer.style.width = holders.innerContainer.style.height = '100%';
        holders.outerContainer.appendChild(holders.innerContainer);

        holders.columns = document.createElement('div')
        holders.columns.className = 'dataview-columns';
        holders.columns.style['flex-basis'] = this.helper.px(this.config.column.height)
        holders.columns.style['position'] = 'relative';
        holders.columns.style['flex-grow'] = holders.columns.style['flex-shrink'] = '0'
        holders.columns.style['margin-left'] = this.helper.px(this.config.numbers.width + this.config.numbers.distance)
        holders.columns.style['border'] = this.config.column.border_style;
        this.helper.apply(holders.columns.style, this.config.column.style);

        holders.columns_inner = document.createElement('div')
        holders.columns_inner.style['position'] = 'absolute';
        holders.columns_inner.style['top'] = '0px';
        holders.columns_inner.className = 'dataview-columns_inner';
        holders.columns_inner.style['left'] = '0px';
        holders.columns_inner.style['height'] = '100%';
        holders.columns.appendChild(holders.columns_inner);

        holders.innerContainer.appendChild(holders.columns);

        holders.belowcolumns = document.createElement('div')
        holders.belowcolumns.style.flex = '1 auto';
        holders.belowcolumns.className = 'dataview-below_columns';
        holders.belowcolumns.style.display = 'flex';
        holders.belowcolumns.style['flex-direction'] = 'row';
        holders.belowcolumns.style['margin-top'] = this.helper.px(this.config.numbers.distance)
        holders.belowcolumns.style.height = '100%';
        holders.innerContainer.appendChild(holders.belowcolumns);

        holders.numbers = document.createElement('div')
        holders.numbers.style.height = '100%';
        holders.numbers.style.overflow = 'hidden';
        holders.numbers.className = 'dataview-numbers';
        holders.numbers.style['flex-basis'] = this.helper.px(this.config.numbers.width);
        holders.numbers.style['flex-grow'] = holders.numbers.style['flex-shrink'] = '0'
        holders.numbers.style.float = 'left';
        holders.numbers.style['margin-right'] = 'left';
        holders.numbers.style['position'] = 'relative';
        holders.numbers.style['border'] = this.config.row.border_style;
        this.helper.apply(holders.numbers.style, this.config.numbers.style);
        holders.belowcolumns.appendChild(holders.numbers);

        holders.numbers_inner = document.createElement('div')
        //holders.numbers_inner.style.width = holders.numbers_inner.style.height = '100%';
        holders.numbers_inner.className = 'dataview-numbers_inner';
        holders.numbers_inner.style.position = 'relative';
        holders.numbers_inner.style.width = '100%';
        holders.numbers_inner.style.top = holders.numbers_inner.style.left = '0px';

        holders.numbers.appendChild(holders.numbers_inner);

        holders.viewport = document.createElement('div')
        holders.viewport.style.width = '50px';
        holders.viewport.className = 'dataview-viewport';
        holders.viewport.style.height = '100%';
        holders.viewport.style['margin-left'] = this.helper.px(this.config.numbers.distance);
        holders.viewport.style.flex = '1 auto';
        holders.viewport.style.overflow = 'scroll';
        holders.viewport.style.border = this.config.row.border_style;

        holders.viewport_content = document.createElement('div')
        holders.viewport_content.style.position = 'relative';

        holders.viewport.appendChild(holders.viewport_content);

        var dis = this;
        holders.viewport.onscroll = function(e) {
            dis.onViewportScroll.apply(dis);
        };
        holders.belowcolumns.appendChild(holders.viewport);

        return holders;
    }

    renderColumns() {
        this.holders.columns_inner.innerHTML = '';
        var width = 0;
        this.data.columns.forEach((c, i) => {
            c.index = i;
            width += c.width;
            var el = this.createColumn(c);

            this.holders.columns_inner.appendChild(el);
        });
        this.holders.columns_inner.style['width'] = this.helper.px(width);
    }

    getColumn(n) {
        return this.data.columns[n];
    }

    onViewportScroll() {
        this.scrolls = this.scrolls || 0;
        var left = this.helper.px(this.holders.viewport.scrollLeft * -1);
        var top = this.helper.px(this.holders.viewport.scrollTop * -1);

        this.holders.columns.scrollLeft = this.holders.viewport.scrollLeft;
        this.holders.numbers.scrollTop = this.holders.viewport.scrollTop;

        if (!this.renderTimer) {
            this.renderTimer = setTimeout(() => {
                this.renderVisible();
                this.renderTimer = null;
            }, 10);
        }
    }

    renderNumber(rowIndex) {
        var rowContainer = document.createElement('div');
        rowContainer.style.top      = (rowIndex * this.config.row.height) + 'px';
        rowContainer.style.position = 'absolute';
        rowContainer.style.height   = this.helper.px(this.config.row.height);
        rowContainer.style['border-bottom'] = this.config.row.border_style;
        rowContainer.style['width'] = '100%';
        rowContainer.style['background'] = this.config.numbers.background;

        var inside_div = document.createElement('div');
        inside_div.innerText = rowIndex + 1;
        inside_div.style['text-align'] = 'left';
        inside_div.style['font-family'] = this.config.numbers.font_family;
        inside_div.style['font-size'] = this.helper.px(this.config.numbers.font_size);
        inside_div.style['font-weight'] = this.config.numbers.font_weight;
        inside_div.style['padding-left'] = this.helper.px(this.config.row.padding_left);
        inside_div.style['padding-top'] = this.helper.px(this.config.row.padding_top);
        inside_div.style['color'] = this.config.numbers.color;

        rowContainer.appendChild(inside_div);

        this.holders.numbers_inner.appendChild(rowContainer);
        return rowContainer;
    }

    getVisibleRange() {
        var visibleBox = {};
        visibleBox.top = 0;
        visibleBox.width = this.holders.viewport.clientWidth;

        return visibleBox;
    }

    renderVisible(selectionRanges) {
        var visbleBox = {
            top: this.holders.viewport.scrollTop,
            left: this.holders.viewport.scrollLeft,
            width: this.holders.viewport.clientWidth,
            height: this.holders.viewport.clientHeight
        };
        var buffer = 100;
        var first = Math.floor(visbleBox.top / this.config.row.height) - 5;
        var last = Math.ceil((visbleBox.top + visbleBox.height) / this.config.row.height) + 5;
        if (first < 0) first = 0;
        if (last >= this.data.rows.length) last = this.data.rows.length;

        this.rowCache = this.rowCache || {};
        this.numbersCache = this.numbersCache || {};

        var range = this.helper.range(first, last);
        for (var x in this.rowCache) {
            if (x < first || x > last || this.selection.isAnyYCellSelected(x)) {
                this.holders.viewport_content.removeChild(this.rowCache[x]);
                this.holders.numbers_inner.removeChild(this.numbersCache[x]);
                delete this.rowCache[x];
                delete this.numbersCache[x];
            } else {
                for (var i = 0; i < this.rowCache[x].children.length; i++) {
                    this.rowCache[x].children[i].style.background = this.config.row.background;
                }
            }
        }
            range.forEach(n => {
            if (!this.rowCache[n]) {
                var nel = this.renderNumber(n);
                this.numbersCache[n] = nel;
                var el = this.renderRow(this.data.rows[n], n, selectionRanges);
                this.rowCache[n] = el;
            }
        });
    }

    createResizeHandle(index) {
        var handle = document.createElement('div');
        handle.className = 'handle';
        handle.style.position = 'absolute';
        handle.style.right = '0px';
        handle.style.top = '0px';
        handle.style.width = '4px';
        handle.style.height = '100%';
        handle.className = 'col-resize';

        var columns = this.data.columns;

        var offsetLeft = null;
        var initialClientX = null;
        var initalWidth = null;
        var dis = this;
        var mouseDown = function(e) {
            if (e.buttons == 1) {
                dis.holders.viewport.onscroll = null;
                offsetLeft = handle.offsetLeft;
                initialClientX = e.clientX;
                initalWidth = columns[index].width;
                document.onmousemove = mouseMove;
            }
        };

        var mouseMove = function(e) {
            var c = columns[index];
            var change = e.clientX - initialClientX;
            e.preventDefault();
            dis.data.columns[index].width = initalWidth + change;

            if (e.buttons !== 1) {
                document.onmousemove = null;
                dis.holders.viewport.onscroll = function(e) {
                    dis.onViewportScroll.apply(dis);
                };
            }
            dis.rowCache = {};
            var b = dis.holders.viewport.scrollLeft;
            dis.invalidate();
            dis.holders.viewport.scrollLeft = b;
        };
        handle.onmousedown = mouseDown;

        return handle;
    }
    formatCell(value, column) {
        if (column.type == 'TIMESTAMP_TZ') {
            return new Date(value).toLocaleString('sv-SE');
        }
        return value;
    }

    getColumnWidth(columnIndex) {
        var col = this.getColumn(columnIndex);
        if (col.type == 'TIMESTAMP_TZ') return 155;
        if (this.data.rows.length > 5000) return 200;
        var max = 0;
        for (var i = 0; i < this.data.rows.length; i++) {
            var len = (this.data.rows[i][columnIndex] || '').toString().length;
            if (len > max) max = len;
        }
        var width = max * 10;
        if (width > 200) return 300;
        if (width < 50) return 100;
        return width;
    }

    renderRow(row, rowIndex, selectionRanges) {
        var rowContainer = document.createElement('div');
        rowContainer.style.top     = (rowIndex * this.config.row.height) + 'px';
        rowContainer.style.height  = this.helper.px(this.config.row.height);
        rowContainer.style['position'] = 'absolute';
        rowContainer.style.height  = this.config.row.height + 'px';
        var dis = this;
        var totalWidth = 0;
        row.map((value, colIndex) => {
            var column = this.getColumn(colIndex);
            var outer_div           = document.createElement('div');
            outer_div.onmousedown = function(e) {
                e.preventDefault();
                dis.selection.onMouseDown.apply(dis.selection, [colIndex, rowIndex, e]);
                dis.invalidateSoft();
                dis.focus();
            };
            outer_div.addEventListener("mouseenter", function(e) {
                dis.selection.onMouseEnter.apply(dis.selection, [colIndex, rowIndex, e]);
            }, false);
            outer_div.style.top     = (rowIndex * this.config.row.height) + 'px';
            outer_div.style.height  = this.helper.px(this.config.row.height);

            outer_div.style.float   = 'left';
            outer_div.style.overflow   = 'hidden';
            outer_div.style['border-right']   = this.config.row.border_style;
            outer_div.style['border-bottom'] = this.config.row.border_style;
            outer_div.style['text-align']   = 'left';
            outer_div.style['color'] = this.config.row.color;
            outer_div.style['background'] = this.config.row.background;
            var selected = dis.selection.isCellSelected(colIndex, rowIndex, selectionRanges);
            if (selected) {
                if (dis.selection.copy) {
                    outer_div.className = 'copyFlash';
                } else {
                    outer_div.className = '';
                }
                outer_div.style['background'] = this.config.row.selected_background;
                outer_div.style['color'] = this.config.row.selected_color;
            } else {
            }
            var w = this.data.columns[colIndex].width;
            outer_div.style.width   = this.helper.px(w);
            totalWidth += w;

            var inside_div = document.createElement('div');
            inside_div.innerText = dis.formatCell(row[colIndex], column);
            inside_div.style['padding-left']  = this.helper.px(this.config.row.padding_left);
            inside_div.style['padding-right']  = this.helper.px(this.config.row.padding_right);
            inside_div.style['padding-top']  = this.helper.px(this.config.row.padding_top);
            inside_div.style['font-family'] = this.config.row.font_family;
            inside_div.style['font-size'] = this.helper.px(this.config.row.font_size);
            inside_div.style['font-weight'] = this.config.row.font_weight;

            /*inside_div.style['font-family'] = 'menlo';
            inside_div.style['font-weight'] = 'normal';
            inside_div.style['padding-left'] = '4px';
            inside_div.style['padding-top'] = '4px';
            inside_div.style['font-size'] = '14px';
            inside_div.style['overflow'] = 'hidden';
            inside_div.style['white-space'] = 'nowrap';*/
            this.helper.apply(inside_div.style, this.config.row.cell.style);

            outer_div.appendChild(inside_div);

            return outer_div;
        }).forEach(el => {
            rowContainer.appendChild(el);
        });
        rowContainer.style.width   = this.helper.px(totalWidth);
        var clear = document.createElement('div');
        clear.style.clear = 'both';
        rowContainer.appendChild(clear);

        this.holders.viewport_content.appendChild(rowContainer);
        return rowContainer;
    }

    createColumn(c) {
        var div = document.createElement('div');
        var e = document.createElement('div');
        e.style.position = 'relative';
        var inside = document.createElement('div');

        var handle = this.createResizeHandle(c.index);
        e.appendChild(handle);

        inside.innerText = c.label;
        inside.style['padding-left'] =  this.helper.px(this.config.column.padding_left);
        inside.style['padding-top'] = this.helper.px(this.config.column.padding_top);
        inside.style['overflow'] = 'hidden';
        inside.style['white-space'] = 'nowrap';
        inside.style['font-family'] = this.config.column.font_family;
        inside.style['font-size'] = this.helper.px(this.config.column.font_size);
        inside.style['font-weight'] = this.config.column.font_weight;
        e.style.position = 'relative';
        e.style.float = 'left';
        e.style['border-right'] = this.config.column.border_style;
        e.style['border-bottom'] = this.config.column.border_style;
        e.style['background'] = this.config.column.background;
        e.style['color'] = this.config.column.color;
        this.helper.apply(e.style, this.config.column.cell.style);
        e.style.width = this.helper.px(c.width);
        e.style.height = this.helper.px(this.config.column.height);
        e.appendChild(inside);

        return e;
    }

    render() {
        this.renderColumns();
        this.holders.numbers_inner.style.height = this.helper.px(this.config.row.height * this.data.rows.length);
        this.holders.viewport_content.style.height = this.helper.px(this.config.row.height * this.data.rows.length);
        this.renderVisible();
    }
};

module.exports = DataTable;
