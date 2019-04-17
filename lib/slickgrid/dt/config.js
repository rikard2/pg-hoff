module.exports = {
    display_columns         : true,
    display_row_numbers     : true,
    numbers: {
        show: false,
        width: 60,
        distance: 2,
        style: {
            'background': '#fafafa',
            'border-top': '1px solid #f3f3f3',
            'border-right': '1px solid #f3f3f3',
            'border-left': '1px solid #f3f3f3',
            'border-bottom': '1px solid #f3f3f3'
        }
    },
    column: {
        height          : 23,
        padding_top     : 4,
        padding_left    : 5,
        style : {
            'background': '#fafafa',
            'border': '1px solid #f3f3f3',
            'overflow': 'hidden'
        },
        cell: {
            style: {
                'font-family': 'helvetica',
                'font-weight': 'normal',
                'font-size': '12px',
                'text-align': 'left',
                'overflow': 'hidden',
                'border-right': '1px solid #f0f0f0'
            }
        }
    },
    row: {
        height          : 23,
        padding_top     : 5,
        padding_left    : 5
    }
}
