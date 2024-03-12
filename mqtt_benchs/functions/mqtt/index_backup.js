const http = require('http')

async function insertInDB(host, port, user, pwd, name, vals) {
	return new Promise((resolve, reject) => {
		// let url = `http://${user}:${pwd}@${host}:${port}/${name}/_bulk_docs`
		let body = { "docs": [] }
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
		let sizes = {}
		
		for (let k in vals) {
			sizes[k] = vals[k].length
			body["docs"].push({ "name": k, "value": vals[k] })
		}
		
		let res = ""
		
		let req = http.request(options, (result) => {
			result.on('data', (chunk) => {
				res += chunk
			})
			result.on('end', () => {
				resolve({
					"insert_result": JSON.parse(res),
					"sizes": sizes
				})
			})
		})
		
		req.on('error', (e) => reject({ "req_error": e }))
		req.write(JSON.stringify(body))
		req.end()
	})
}

function myAction(args) {
	const mqtt = require('mqtt')
	let host = args.host
	let port = args.port
	let sensors_amount = args.sensors_amount

	let db_host = args.db_host ? args.db_host : host
	let db_port = args.db_port ? args.db_port : 27017
	let db_pwd = args.db_pwd ? args.db_pwd : 'password'
	let db_user = args.db_user ? args.db_user : 'admin'
	let db_name = args.db_name ? args.db_name : 'docs'

	let topics = []
	let values = {
	}
	for (let i = 0; i < sensors_amount; i++) {
		topics.push(`sensor${i}`)
		values[`sensor${i}`] = null
	}

	let client = mqtt.connect(`mqtt://${host}:${port}`)

	return new Promise((resolve, reject) => {
		client.on('connect', function (err) {
			console.log("I HAVE CONNECTED")
			client.subscribe(topics, function (err) {
				console.log("I HAVE SUBSCRIBED")
				client.on('message', function (topic, message) {
					console.log("I HAVE RECEIVED A MESSAGE")

					if (topics.includes(topic)) {
						values[topic] = message
						client.unsubscribe(topic)
						let index = topics.indexOf(topic)
						topics.splice(index, 1)
						if (topics.length == 0) {
							client.end()
							console.log("I WILL TRY TO INSERT IN DB, THINGS MIGHT BREAK HERE")
							// insertInDB(db_host, db_port, db_user, db_pwd, db_name, values)
							// 	.then(payload => resolve({ "payload": payload }))
							// 	.catch(e => reject({ "error": e }))
						}
					}
				})
			})
		})
	})
}

exports.main = myAction;
