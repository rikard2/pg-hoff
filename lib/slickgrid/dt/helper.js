module.exports = {
    px: function(n) {
        return n + 'px';
    },
    apply: function(obj, properties) {
        for (var key in properties) {
            obj[key] = properties[key];
        }
    },
    noop: function() {},
    range: function(offset, n) { return Array.apply(null, {length: (n - offset)}).map(Number.call, Number).map(i => { return i + offset }) }
};
