module.exports = {
    one: {
            columns: [
                {
                    label: 'Nr',
                    width: 60
                },
                {
                    label: 'First Name',
                    width: 200
                },
                {
                    label: 'Last Name',
                    width: 200
                },
                {
                    label: 'Mark zuckerberg is a bitch',
                    width: 200
                },
                {
                    label: 'Weeeeeeeeeoooo',
                    width: 200
                },
                {
                    label: 'Weeeeeeeeeoooo',
                    width: 50
                },
                {
                    label: 'Weeeeeeeeeoooo',
                    width: 200
                }
            ],
            rows:
                Array.apply(null, {length: 5}).map(Number.call, Number).map(i => {
                    return [i, 'Jeff Brown', 'Tomte', 'asddasdsa iadsjdklsaj adsljk ads', 'asdlhdaslk asdlk daslkjadsk ljadsk alsd', '23',  'daslkjadsk ljadsk alsd']
                })
        },
        two: {
                columns: [
                    {
                        label: 'Nr',
                        width: 60
                    },
                    {
                        label: 'First Name',
                        width: 200
                    }
                ],
                rows:
                    Array.apply(null, {length: 100000}).map(Number.call, Number).map(i => {
                        return [i, 'Jeff Brown']
                    })
            }
};
