FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

# Fly's volume mounts at /app/data (see fly.toml) — community_db.py already resolves its DB
# path relative to the app package, so no code change needed, just make sure the directory
# exists before the volume is mounted over it.
RUN mkdir -p /app/data

EXPOSE 8080
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
