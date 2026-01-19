from flask import Flask, request, jsonify
import requests
import random
import time
import os
from prometheus_client import start_http_server, Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
import threading

app = Flask(__name__)

# Prometheus metrics
orders_total = Counter('orders_total', 'Total orders processed', ['status', 'country'])
order_amount = Histogram('order_amount', 'Order amount distribution', buckets=[100, 500, 1000, 5000, 10000])
http_requests_total = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
order_processing_time = Histogram('order_processing_time_seconds', 'Order processing time')

# Start metrics server in background
def start_metrics_server():
    start_http_server(8000)

# Start the metrics server
metrics_thread = threading.Thread(target=start_metrics_server, daemon=True)
metrics_thread.start()

orders_db = {}
fraud_service_url = os.getenv("FRAUD_SERVICE_URL", "http://fraud-detector:5000")

@app.route('/')
def home():
    http_requests_total.labels(method='GET', endpoint='/', status='200').inc()
    return {"message": "Order Service", "endpoints": ["/health", "/order", "/orders", "/metrics"]}, 200

@app.route('/health', methods=['GET'])
def health():
    http_requests_total.labels(method='GET', endpoint='/health', status='200').inc()
    return {"status": "healthy", "service": "order-service"}, 200

@app.route('/metrics', methods=['GET'])
def metrics():
    http_requests_total.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/order', methods=['POST'])
def create_order():
    start_time = time.time()
    http_requests_total.labels(method='POST', endpoint='/order', status='200').inc()
    
    try:
        data = request.json
        if not data:
            http_requests_total.labels(method='POST', endpoint='/order', status='400').inc()
            return {"error": "No JSON data provided"}, 400
            
        user_id = data.get('user_id')
        amount = data.get('amount', 0)
        country = data.get('country', 'US')
        
        # Validate
        if not user_id or amount <= 0:
            http_requests_total.labels(method='POST', endpoint='/order', status='400').inc()
            orders_total.labels(status='invalid', country=country).inc()
            return {"error": "Invalid order data"}, 400
        
        # Check fraud
        fraud_detected = False
        try:
            response = requests.post(
                f"{fraud_service_url}/predict",
                json={"user_id": user_id, "amount": amount, "country": country},
                timeout=3
            )
            fraud_result = response.json()
            if fraud_result.get('is_fraud', False):
                fraud_detected = True
                orders_total.labels(status='fraud', country=country).inc()
                http_requests_total.labels(method='POST', endpoint='/order', status='403').inc()
                return {
                    "error": "Fraud detected",
                    "details": fraud_result
                }, 403
        except:
            # Continue if fraud service is down
            pass
        
        # Process payment
        time.sleep(0.1)
        if random.random() < 0.1:  # 10% failure
            orders_total.labels(status='payment_failed', country=country).inc()
            order_processing_time.observe(time.time() - start_time)
            http_requests_total.labels(method='POST', endpoint='/order', status='402').inc()
            return {"error": "Payment failed"}, 402
        
        # Create order
        order_id = f"ord_{int(time.time())}_{random.randint(1000, 9999)}"
        orders_db[order_id] = {
            "user_id": user_id,
            "amount": amount,
            "country": country,
            "status": "completed"
        }
        
        # Record metrics
        orders_total.labels(status='completed', country=country).inc()
        order_amount.observe(amount)
        order_processing_time.observe(time.time() - start_time)
        
        return {
            "order_id": order_id,
            "status": "completed",
            "amount": amount,
            "message": "Order created successfully"
        }, 201
        
    except Exception as e:
        http_requests_total.labels(method='POST', endpoint='/order', status='500').inc()
        orders_total.labels(status='error', country='unknown').inc()
        return {"error": str(e)}, 500

@app.route('/orders', methods=['GET'])
def list_orders():
    http_requests_total.labels(method='GET', endpoint='/orders', status='200').inc()
    return {"orders": list(orders_db.keys()), "count": len(orders_db)}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
