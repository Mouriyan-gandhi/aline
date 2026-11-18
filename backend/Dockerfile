FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# SQLite lives in /app/data (community_db.py resolves it relative to the app package). On
# Render's free plan this disk is ephemeral: it is wiped on every restart or deploy.
RUN mkdir -p /app/data

EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
