from flask import Flask, request, jsonify
import random
import time
from prometheus_client import start_http_server, Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import threading

app = Flask(__name__)

# Prometheus metrics
fraud_predictions_total = Counter('fraud_predictions_total', 'Total fraud predictions', ['is_fraud', 'country'])
fraud_score = Histogram('fraud_score', 'Fraud prediction scores', buckets=[0, 0.3, 0.5, 0.7, 0.9, 1.0])
prediction_latency = Histogram('prediction_latency_seconds', 'Prediction latency')
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])

# Start metrics server in background
def start_metrics_server():
    start_http_server(8000)

# Start the metrics server
metrics_thread = threading.Thread(target=start_metrics_server, daemon=True)
metrics_thread.start()

@app.route('/')
def home():
    http_requests_total.labels(method='GET', endpoint='/', status='200').inc()
    return {"message": "Fraud Detection Service", "endpoints": ["/health", "/predict", "/metrics"]}, 200

@app.route('/health', methods=['GET'])
def health():
    http_requests_total.labels(method='GET', endpoint='/health', status='200').inc()
    return {"status": "healthy", "model": "fraud-v2.1"}, 200

@app.route('/metrics', methods=['GET'])
def metrics():
    http_requests_total.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/predict', methods=['POST'])
def predict():
    start_time = time.time()
    http_requests_total.labels(method='POST', endpoint='/predict', status='200').inc()
    
    try:
        data = request.json
        if not data:
            return {"error": "No JSON data provided"}, 400
            
        user_id = data.get('user_id', 'unknown')
        amount = data.get('amount', 0)
        country = data.get('country', 'US')
        
        # Simulate processing time
        process_time = random.uniform(0.05, 0.15)
        time.sleep(process_time)
        
        # Calculate risk score
        risk_score = 0.0
        
        # Rule 1: High amount
        if amount > 5000:
            risk_score += 0.6
            
        # Rule 2: Risky country
        risky_countries = ['RU', 'CN', 'NG', 'BR']
        if country in risky_countries:
            risk_score += 0.4
            
        # Add some randomness
        risk_score += random.uniform(-0.1, 0.1)
        risk_score = max(0, min(1, risk_score))
        
        # Determine fraud
        is_fraud = risk_score > 0.7
        reason = "high_amount" if amount > 5000 else "risk_country" if country in risky_countries else "low_risk"
        
        # Record metrics
        fraud_predictions_total.labels(is_fraud=str(is_fraud), country=country).inc()
        fraud_score.observe(risk_score)
        prediction_latency.observe(time.time() - start_time)
        
        return {
            "user_id": user_id,
            "risk_score": round(risk_score, 3),
            "is_fraud": is_fraud,
            "threshold": 0.7,
            "reason": reason,
            "model_version": "fraud-v2.1",
            "processing_time_ms": round(process_time * 1000, 2)
        }, 200
        
    except Exception as e:
        http_requests_total.labels(method='POST', endpoint='/predict', status='500').inc()
        return {"error": str(e)}, 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
