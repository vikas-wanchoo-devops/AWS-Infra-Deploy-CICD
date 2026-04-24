from flask import Flask, render_template, request
import logging
from datetime import datetime

app = Flask(__name__)

# Configure logging to stdout (captured by ECS/CloudWatch.)
logging.basicConfig(level=logging.INFO,
                    format="%(asctime)s [%(levelname)s] %(message)s")

@app.before_request
def log_request_info():
    app.logger.info(f"Request: {request.method} {request.path} from {request.remote_addr}")

@app.route("/")
def home():
    client_ip = request.remote_addr
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    app.logger.info(f"Homepage accessed from {client_ip} at {now}")
    return render_template("index.html", client_ip=client_ip, now=now)

@app.route("/health")
def health():
    app.logger.info("Health check endpoint called")
    return "200 OK", 200

@app.route("/feedback", methods=["POST"])
def feedback():
    user_feedback = request.form.get("feedback")
    app.logger.info(f"Feedback submitted: {user_feedback}")
    return render_template("thankyou.html", feedback=user_feedback)

if __name__ == "__main__":
    # ✅ Bind to all interfaces on port 5000 so ALB can reach it
    app.run(host="0.0.0.0", port=5000)
