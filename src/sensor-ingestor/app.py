from flask import Flask, request, jsonify
import logging
import jwt  # <--- The OIDC Library
import datetime

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SensorIngestor")

# SECRET KEY (In real life, this comes from Azure/Google. Here we make our own).
# We use this to "Sign" and "Verify" the passports.
OIDC_SECRET_KEY = "goldbeck-master-secret-key"

def verify_oidc_token(request):
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith("Bearer "):
        return False, "Missing or Invalid Token Format"
    
    token = auth_header.split(" ")[1]
    
    try:
        # --- OIDC MAGIC HAPPENS HERE ---
        # 1. Decode the token
        # 2. Verify the signature (Did WE sign it? Or a hacker?)
        # 3. Check 'exp' (Is it expired?)
        payload = jwt.decode(token, OIDC_SECRET_KEY, algorithms=["HS256"])
        
        # 4. Extract Identity (Who is this?)
        user_id = payload.get("sub") # 'sub' is standard OIDC for 'Subject' (User)
        return True, user_id
        
    except jwt.ExpiredSignatureError:
        return False, "Token has Expired"
    except jwt.InvalidTokenError:
        return False, "Invalid Token (Fake Signature)"

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "auth_type": "OIDC-JWT"}), 200

@app.route('/ingest', methods=['POST'])
def ingest_data():
    # 1. Verify Identity (OIDC)
    is_valid, user_identity = verify_oidc_token(request)
    
    if not is_valid:
        # user_identity contains the error message here
        logger.warning(f"Auth Failed: {user_identity}")
        return jsonify({"error": user_identity}), 401

    # 2. Process Data
    data = request.json
    sensor_id = data.get('sensor_id', 'unknown')
    logger.info(f"Authorized Request from User: {user_identity} | Sensor: {sensor_id}")
    
    return jsonify({"status": "accepted", "verified_user": user_identity}), 201

# --- LOGIN ENDPOINT (SIMULATING AUTH0/GOOGLE) ---
# In real life, this happens on a separate server (Identity Provider)
# We put it here just so you can GENERATE a token to test with.
@app.route('/login', methods=['POST'])
def login():
    # Simulate a user logging in
    username = request.json.get('username')
    
    # Create the Passport (JWT)
    token_payload = {
        "sub": username, # Subject (Identity)
        "iss": "goldbeck-auth-server", # Issuer
        "exp": datetime.datetime.utcnow() + datetime.timedelta(minutes=30) # Expires in 30m
    }
    
    # Sign it cryptographically
    token = jwt.encode(token_payload, OIDC_SECRET_KEY, algorithm="HS256")
    return jsonify({"access_token": token})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)