from flask import Flask, render_template, jsonify
import os
import socket
from datetime import datetime

app = Flask(__name__)


@app.route('/')
def hello():
    host = socket.gethostname()
    return render_template('index.html', hostname=host)


@app.route('/health')
def health():
    return jsonify({"status": "ok", "app": "flask-lab3"})


@app.route('/api/info')
def info():
    return jsonify({
        "hostname": socket.gethostname(),
        "platform": os.name,
        "python_version": os.popen("python --version").read().strip(),
        "timestamp": datetime.now().isoformat()
    })


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
