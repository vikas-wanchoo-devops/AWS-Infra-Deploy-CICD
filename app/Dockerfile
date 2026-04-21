FROM python:3.9-slim

# Install curl for debugging inside ECS Exec
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Run the Flask app
CMD ["python", "app.py"]
