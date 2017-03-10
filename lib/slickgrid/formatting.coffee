module.exports = class SlickFormatting
    @DefaultFormatter: (row, cell, value, columnDef, dataContext) ->
        if value == null
            return "<span style='color:#fcc81e;font-weight:bold;font-style:normal;'>NULL</span>";
        if columnDef.type == "boolean"
            if value == true
                return "<span style='color:#a2ff6d;font-weight:bold;'>true</span>";
            else
                return "<span style='color:#ff816d;font-weight:bold;'>false</span>";
        if columnDef.type in ['timestamp with time zone', 'timestamp without time zone']
            return new Date(value).toLocaleString(atom.config.get('pg-hoff.locale'))
        if columnDef.type in ['time with time zone', 'time without time zone']
            return new Date('2000-01-01 ' + value).toLocaleTimeString(atom.config.get('pg-hoff.locale'))
        if columnDef.type == 'json'
            return JSON.stringify(JSON.parse(value), null, '   ')

        entityMap =
            '&': '&amp;'
            '<': '&lt;'
            '>': '&gt;'
            '"': '&quot;'
            '\'': '&#39;'
            '/': '&#x2F;'
            '`': '&#x60;'
            '=': '&#x3D;'

        escapeHtml = (string) ->
          String(string).replace /[&<>"'`=\/]/g, (s) ->
            entityMap[s]
        return escapeHtml(value)
