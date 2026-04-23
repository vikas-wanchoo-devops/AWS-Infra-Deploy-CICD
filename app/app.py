from flask import Flask, render_template_string, request
import logging
from datetime import datetime

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)

@app.route("/")
def hello():
    user_ip = request.remote_addr
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    app.logger.info(f"Homepage accessed from {user_ip} at {now}")

    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Assa Abloy DevOps Pipeline</title>
        <style>
            body { font-family: Arial, sans-serif; background: #f4f4f9; text-align: center; padding: 50px; }
            h1 { color: #2c3e50; }
            p { color: #34495e; }
            .footer { margin-top: 40px; font-size: 12px; color: #7f8c8d; }
        </style>
    </head>
    <body>
        <h1>Hello Vikas from Assa Abloy DevOps Pipeline!</h1>
        <p>Welcome to your interactive Flask app.</p>
        <p><strong>Current time:</strong> {{ now }}</p>
        <p><strong>Your IP:</strong> {{ ip }}</p>
        <div class="footer">Powered by Flask & AWS ECS</div>
    </body>
    </html>
    """
    return render_template_string(html, now=now, ip=user_ip)

@app.route("/health")
def health():
    app.logger.info("Health check endpoint called")
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
