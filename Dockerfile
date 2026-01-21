FROM python:3.11-slim

# Install system dependencies (Kraken may need some of these)
RUN apt-get update && apt-get install -y \
    git \
    libxml2 \
    libxslt1.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency files first (for better layer caching)
COPY pyproject.toml pdm.lock ./


RUN pip install --no-cache-dir pdm


RUN pdm install --prod --no-lock

# Copy the rest of the application
COPY . .

ENV PYTHONPATH=/app/__pypackages__/3.11/lib:/app/src

CMD ["bash"]