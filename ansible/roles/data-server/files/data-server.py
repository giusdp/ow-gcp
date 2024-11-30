import os
import json
from flask import Flask, jsonify, abort

app = Flask(__name__)

@app.route('/')
def handler():
	file_path = os.getenv("JSON_FILE")
	try:
		with open(file_path, 'r') as file:
			data = json.load(file)
	except FileNotFoundError:
		abort(500, description="Unable to read file")
	except json.JSONDecodeError:
		abort(500, description="Unable to parse JSON")

	return jsonify(data)

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=8080)
