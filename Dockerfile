FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

RUN adduser --disabled-password --gecos "" appuser
WORKDIR /app

COPY requirements.txt ./
RUN pip install -r requirements.txt

COPY app ./app
EXPOSE 8080
USER appuser

CMD ["gunicorn", "-c", "app/gunicorn.conf.py", "app:app"]
