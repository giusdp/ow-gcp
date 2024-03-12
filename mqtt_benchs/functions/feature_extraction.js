const http = require('http')

async function extractFromDB(host, port, user, pwd, name) {
    return new Promise((resolve, reject) => {
        // let url = `http://${user}:${pwd}@${host}:${port}/${name}/_bulk_docs`
        let body = { "docs": [] }
        let options = {
            host: `${host}`,
            auth: `${user}:${pwd}`,
            port: port,
            path: `/${name}/_all_docs`,
            method: 'GET',
            headers: {
                'Content-Type': 'application/json'
            },
            agent: false
        }
        let res = ""

        let req = http.request(options, (result) => {
            result.on('data', (chunk) => {
                res += chunk
            })
            result.on('end', () => {
                resolve({
                    "result": JSON.parse(res),
                })
            })
        })

        req.on('error', (e) => reject({ "req_error": e }))
        req.end()
    })
}

function extractFeatures(raw_data) {
    features = {}
    features["rows"] = raw_data["rows"].length
    return features
}

function main(params) {

    let db_host = params.db_host
    let db_port = params.db_port ? params.db_port : 5984
    let db_pwd = params.db_pwd ? params.db_pwd : 'password'
    let db_user = params.db_user ? params.db_user : 'admin'
    let db_name = params.db_name ? params.db_name : 'docs'

    return new Promise((resolve, reject) => {
        extractFromDB(db_host, db_port, db_user, db_pwd, db_name)
            .then(payload => resolve({ "payload": extractFeatures(payload["result"]) }))
            .catch(e => reject({ "error": e }))

    })
}

exports.main = main
