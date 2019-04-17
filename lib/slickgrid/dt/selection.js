class SelectionManager {
    constructor() {
        this.activeRange = null;
        this.ranges = [];
        this.lastCell = null;
        this.startCell = null;
        this.copy = false;
        this.onSelectedRangesChanged = function() {};
        this.onCellActive = function() {}
        this.onCopy = function() {}
    }
    selectFirst() {
        this.activeRange = {minX:0,maxX:0,minY:0,maxY:0};
        this.lastCell = { x: 0, y: 0 };
    }

    isAnyYCellSelected(y) {
        var ranges = this.ranges.concat(this.activeRange || []);
        for (var i = 0; i < ranges.length; i++) {
            var r = ranges[i];
            if (y >= r.minY && y <= r.maxY) return true;
        }

        return false;
    }

    expandRange(range) {
        var r = [];
        for (var x = range.minX; x <= range.maxX; x++) {
            for (var y = range.minY; y <= range.maxY; y++) {
                r.push([x, y]);
            }
        }
        return r;
    }
    getSelectedRange() {
        var cells = [];
        var ranges = this.ranges.concat(this.activeRange || []);
        for (var i = 0; i < ranges.length; i++) {
            var range = this.expandRange(ranges[i]);
            cells = cells.concat(range);
        }
        return cells;
    }

    isCellSelected(x, y, selectionRanges) {
        var ranges = this.ranges.concat(this.activeRange || []);
        if (ranges.length > 0) {
        }
        for (var i = 0; i < ranges.length; i++) {
            var r = ranges[i];
            if (x >= r.minX && x <= r.maxX && y >= r.minY && y <= r.maxY) return true;
        }

        return false;
    }
    increaseRange(x, y) {
        this.activeRange.minY = Math.min(this.startCell.y, y);
        this.activeRange.maxY = Math.max(this.startCell.y, y);

        this.activeRange.minX = Math.min(this.startCell.x, x);
        this.activeRange.maxX = Math.max(this.startCell.x, x);
    }

    onMouseDown(x, y, e) {
        this.lastCell = { x: x, y: y };

        if (e.shiftKey || e.metaKey) {
        } else {
            this.activeRange = null;
            this.ranges = [];
        }

        if (e.metaKey && this.activeRange) {
            this.ranges.push(this.activeRange);
            this.activeRange = null;
        }

        if (!this.activeRange) {
            this.startCell = {
                x: x,
                y: y
            };
            this.activeRange = {
                minX: x, maxX: x,
                minY: y, maxY: y
            };
        } else if (e.shiftKey && this.startCell) {
            this.increaseRange(x, y);
        } else {
            this.startCell = {
                x: x,
                y: y
            };
            this.activeRange = {
                minX: x, maxX: x,
                minY: y, maxY: y
            };
        }

        this.onSelectedRangesChanged();
    }
    onMouseEnter(x, y) {
        //this.selectCell(x, y);
    }
    onKeyDown(e) {
        var change = false;
        if (this.lastCell && ( [ 37, 38, 39, 40 ].indexOf(e.keyCode) ) >= 0) {
            var deltaX = 0;
            var deltaY = 0;
            if (e.keyCode == 37) { // LEFT
                deltaX = -1;
            }
            else if (e.keyCode == 38) { // UP
                deltaY = -1;
            } else if (e.keyCode == 39) { // RIGHT
                deltaX = 1;
            } else if (e.keyCode == 40) { // DOWN
                deltaY = 1;
            }
            var newX = this.lastCell.x + deltaX;
            var newY = this.lastCell.y + deltaY;
            if (newX <= 0) newX = 0;
            if (newY <= 0) newY = 0;
            if (newX >= this.columns) newX = this.columns - 1;
            if (newY >= this.rows) newY = this.rows - 1;
            if (e.shiftKey && !e.metaKey) {
                this.increaseRange(newX, newY);
                this.lastCell = { x: newX, y: newY };
            } else if (this.lastCell && (!e.metaKey && !e.shiftKey)) {
                this.ranges = [];
                this.activeRange = { minX: newX,
                                     maxX: newX,
                                     minY: newY,
                                     maxY: newY };
                this.lastCell = this.startCell = { x: newX, y: newY };
                this.onCellActive(newX, newY);
            } else if (this.lastCell && (e.metaKey || e.shiftKey)) {
                if (e.keyCode == 37) {
                    newX = 0;
                    newY = this.lastCell.y;
                } else if (e.keyCode == 38) {
                    newY = 0;
                    newX = this.lastCell.x;
                } else if (e.keyCode == 39) {
                    newX = this.columns - 1;
                    newY = this.lastCell.y;
                } else if (e.keyCode == 40) {
                    newY = this.rows - 1;
                    newX = this.lastCell.x;
                }
                if (e.shiftKey && e.shiftKey) {
                    this.increaseRange(newX, newY);
                    this.lastCell = { x: newX, y: newY };
                } else {
                    this.ranges = [];
                    this.activeRange = { minX: newX,
                                         maxX: newX,
                                         minY: newY,
                                         maxY: newY };
                    this.lastCell = this.startCell = { x: newX, y: newY };
                }
                this.onCellActive(newX, newY);
            } else {
                console.log('WTF');
            }

        }
        if (e.metaKey && e.key == 'c') {
            this.copy = true;
            this.onSelectedRangesChanged();
            this.copy = false;
            this.onCopy(this.getSelectedRange());
        } else if (e.metaKey && e.key == 'a') {
            console.log('cmd+a');
            this.ranges = [{ minX: 0,
                             maxX: this.columns - 1,
                             minY: 0,
                             maxY: this.rows - 1 }];
            this.activeRange = null;
            console.log('ranges', this.ranges);
            this.onSelectedRangesChanged();
        } else {
            this.onSelectedRangesChanged();
        }
    }

    onMouseUp(x, y) {

    }

    selectCell(x, y) {
        this.ranges.push({
            minX: x, maxX: x,
            minY: y, maxY: y
        });
    }
}
module.exports = SelectionManager;
