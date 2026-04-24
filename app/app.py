from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Vikas from Wanchoo DevOps Pipeline!"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    # ✅ Bind to 0.0.0.0 so ECS/ALB can reach it
    # ✅ Match target group port (5000)
    app.run(host="0.0.0.0", port=5000)
