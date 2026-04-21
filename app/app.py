from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello from Assa Abloy DevOps Pipeline!"

@app.route("/health")
def health():
    # Simple health check endpoint for ALB
    return "OK", 200

if __name__ == "__main__":
    # Bind to all interfaces on port 5000
    app.run(host="0.0.0.0", port=5000)
