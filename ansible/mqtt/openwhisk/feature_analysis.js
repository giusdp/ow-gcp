function main(params) {
    features = params.features
    return new Promise(resolve => {
        setTimeout(
            () => resolve(
                {
                    'payload': features
                }
            ), 3000
        )
    })
}

exports.main = main