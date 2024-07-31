from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route('/', methods=['POST'])
def alert():
    data = request.json
    for alert in data['alerts']:
        if alert['labels']['severity'] == 'critical':
            # Restart service (example: restart Prometheus)
            subprocess.run(["sudo", "systemctl", "restart", "prometheus"])
    return '', 200

if __name__ == '__main__':
    app.run(port=5001)
