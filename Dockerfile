FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    libxml2 \
    libxslt1.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy everything
COPY . .

# Install with all extras (if defined)
RUN pip install --no-cache-dir -e ".[dev]" || pip install --no-cache-dir -e .

CMD ["bash"]