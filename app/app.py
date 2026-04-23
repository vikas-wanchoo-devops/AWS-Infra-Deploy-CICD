from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Vikas from Wanchoo DevOps Pipeline!!"

@app.route("/health")
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run()
