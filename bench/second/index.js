function main(args) {
    const { uniqueOrderIdsCount } = args;

    return {
        body: `<h1>Unique Order IDs Count: ${uniqueOrderIdsCount}</h1>`
    }
}