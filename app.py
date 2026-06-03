from flask import Flask, request, jsonify, send_from_directory, Response
from flask_cors import CORS
import requests
import os

app = Flask(__name__, static_folder='.')
CORS(app)

LLAMA_BASE = os.environ.get('LLAMA_SERVER_URL', 'http://127.0.0.1:8080')


@app.route('/')
def index():
    return send_from_directory('.', 'index.html')


@app.route('/<path:path>')
def static_proxy(path):
    # Serve any static file from the project root (index.html next to this file)
    return send_from_directory('.', path)


@app.route('/completion', methods=['POST'])
def completion():
    payload = request.get_json(silent=True)
    headers = {'Content-Type': 'application/json'}

    try:
        r = requests.post(f"{LLAMA_BASE}/completion", json=payload, headers=headers, timeout=120)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

    # Forward response (preserve content-type)
    content_type = r.headers.get('Content-Type', 'application/json')
    return Response(r.content, status=r.status_code, content_type=content_type)


@app.route('/health')
def health():
    try:
        r = requests.get(f"{LLAMA_BASE}/v1/health", timeout=3)
        return (r.text, r.status_code, {'Content-Type': r.headers.get('Content-Type', 'text/plain')})
    except Exception:
        return jsonify({'status': 'unreachable', 'llama_url': LLAMA_BASE}), 503


if __name__ == '__main__':
    host = os.environ.get('HOST', '0.0.0.0')
    port = int(os.environ.get('PORT', 5500))
    app.run(host=host, port=port)
