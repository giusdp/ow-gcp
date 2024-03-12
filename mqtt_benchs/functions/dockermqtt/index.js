const http = require('http')
const axios = require('axios')
let ret = {}

async function insertInDB(host, port, user, pwd, name, vals) {
    // let url = `http://${user}:${pwd}@${host}:${port}/${name}/_bulk_docs`
    let body = { "docs": [] }
    let sizes = {}

    for (let k in vals) {
        sizes[k] = vals[k].length
        body["docs"].push({ "name": k, "value": vals[k] })
    }

    console.log("body: ", body)

    let options = {
        host: `${host}`,
        auth: `${user}:${pwd}`,
        port: port,
        path: `/${name}/_bulk_docs`,
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        agent: false
    }


    let r = await axios.post(`http://${user}:${pwd}@${host}:${port}/${name}/_bulk_docs`, body)

    console.log("r: ", JSON.stringify(r))

    return true
}

async function myAction(args) {
    const mqtt = require('mqtt')
    let host = args.host
    let port = args.port
    let sensors_amount = args.sensors_amount || 6;

    let db_host = args.db_host ? args.db_host : host
    let db_port = args.db_port ? args.db_port : 5984
    let db_pwd = args.db_pwd ? args.db_pwd : 'password'
    let db_user = args.db_user ? args.db_user : 'admin'
    let db_name = args.db_name ? args.db_name : 'docs'

    let topics = []
    let values = {}
    for (let i = 0; i < sensors_amount; i++) {
        topics.push(`sensor${i}`)
        values[`sensor${i}`] = null
    }

    console.log("topics: ", topics)

    function mqtt_connect() {
        console.log('client has connected successfully');
        client.subscribe(topics, (err, granted) => {
            if (err) {
                console.log(err);
            }
            console.log("granted:", granted);
        });
        client.on('message', mqtt_messsageReceived);
        console.log(topics);
    };

    let res = {}

    async function mqtt_messsageReceived(topic, message) {
        console.log('message received from:', topic);

        if (topics.includes(topic)) {
            values[topic] = message
            client.unsubscribe(topic)
            let index = topics.indexOf(topic)
            topics.splice(index, 1)
            if (topics.length == 0) {
                console.log("I WILL TRY TO INSERT IN DB, THINGS MIGHT BREAK HERE")
                done = await insertInDB(db_host, db_port, db_user, db_pwd, db_name, values)
            }
        }
    }

    console.log("I WILL TRY TO CONNECT")
    let done = false
    let client = mqtt.connect(`mqtt://${host}:${port}`)
    client.on("connect", mqtt_connect)

    while (!done) {
        console.log("waiting for done")
        await new Promise(r => setTimeout(r, 1000))
    }

    if (!client.connected) {
        console.log("DID NOT CONNECT")
        throw new Error("client not connected")
    }

    if (ret.req_error) {
        console.log("couchdb error:", e)
        res = { "couchdb error": e }
    } else {
        console.log("couchdb inserted payload: ", ret)
        res = ret
    }

    client.end()
    return res;
}



exports.main = myAction;
