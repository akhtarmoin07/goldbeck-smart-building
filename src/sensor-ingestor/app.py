from flask import Flask, request, jsonify
import logging

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SensorIngestor")

# ---------------------------------------------------------------------------
# ENTERPRISE UPGRADE:
# We no longer verify passwords/tokens here.
# We trust the 'OAuth2-Proxy' (Ingress) to do that for us.
# ---------------------------------------------------------------------------

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "auth_mode": "Infrastructure-Offloaded"}), 200

@app.route('/ingest', methods=['POST'])
def ingest_data():
    # 1. READ THE STAMP
    # When OAuth2-Proxy approves a user, it adds this Header to the request.
    # If this Header is missing, it means the request skipped the security guard!
    user_email = request.headers.get('X-Auth-Request-Email')

    if not user_email:
        logger.warning("Security Breach Attempt: Request missing Identity Header")
        return jsonify({"error": "Unauthorized - Missing Identity Header"}), 401

    # 2. PROCESS DATA
    data = request.json
    sensor_id = data.get('sensor_id', 'unknown')
    
    logger.info(f"Authorized Request from: {user_email} | Sensor: {sensor_id}")
    
    return jsonify({
        "status": "accepted", 
        "verified_user": user_email,
        "auth_source": "Azure AD via Kubernetes Ingress"
    }), 201

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)