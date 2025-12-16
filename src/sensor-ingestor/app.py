from flask import Flask, request, jsonify
import logging
import random
import time

app = Flask(__name__)

# Configure logging (Crucial for SREs!)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SensorIngestor")

# 1. Health Check (Kubernetes uses this to know we are alive)
@app.route('/health')
def health():
    return jsonify({"status": "healthy", "version": "1.0.0"}), 200

# 2. The Smart Building Logic (Receiving Sensor Data)
@app.route('/ingest', methods=['POST'])
def ingest_data():
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
    
    sensor_id = data.get('sensor_id', 'unknown')
    temperature = data.get('temperature')
    
    # Simulate processing (SREs care about latency!)
    process_time = random.uniform(0.01, 0.05)
    time.sleep(process_time)
    
    logger.info(f"Received data from {sensor_id}: Temp={temperature}°C - Processed in {process_time:.3f}s")
    
    return jsonify({"status": "accepted", "processed_time": process_time}), 201

# 3. Metrics Endpoint (For Prometheus/Grafana)
@app.route('/metrics')
def metrics():
    # In a real app, we would export real Prometheus metrics here
    return "# HELP sensor_requests_total Total number of sensor readings\n# TYPE sensor_requests_total counter\nsensor_requests_total 42\n"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)