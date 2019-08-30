module.exports = {
    display_columns         : true,
    display_row_numbers     : true,
    background: '#fff',
    numbers: {
        show: false,
        width: 60,
        distance: 2,
        height: 28,
        font_family     : 'menlo',
        font_size       : 14,
        font_weight     : 'normal',
        color           : '#333',
        background      : '#fff',
        style: {
            //'border-top': '1px solid #f3f3f3',
            //'border-right': '1px solid #f3f3f3',
            //'border-left': '1px solid #f3f3f3',
            //'border-bottom': '1px solid #f3f3f3'
        }
    },
    column: {
        height          : 28,
        padding_top     : 4,
        padding_left    : 5,
        border_style    : '1px solid #f0f0f0',
        font_family     : 'menlo',
        font_size       : 14,
        font_weight     : 'bold',
        background      : '#fff',
        color           : '#333',
        style : {
            'overflow': 'hidden'
        },
        cell: {
            style: {
                'text-align': 'left',
                'overflow': 'hidden'
            }
        }
    },
    row: {
        border_style    : '1px solid #f0f0f0',
        height          : 28,
        padding_top     : 4,
        padding_left    : 5,
        padding_right   : 5,
        font_family     : 'menlo',
        font_size       : 14,
        font_weight     : 'normal',
        color           : '#000',
        background      : '#fff',
        selected_color     : '#000',
        selected_background: 'rgb(210, 236, 255)',
        cell: {
            style: {
                'overflow': 'hidden',
                'white-space': 'nowrap'
            }
        }
        /*inside_div.style['font-family'] = 'menlo';
        inside_div.style['font-weight'] = 'normal';
        inside_div.style['padding-left'] = '4px';
        inside_div.style['padding-top'] = '4px';
        inside_div.style['font-size'] = '14px';
        inside_div.style['overflow'] = 'hidden';
        inside_div.style['white-space'] = 'nowrap';*/
    }
}
