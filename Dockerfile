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

# Create a dummy README if it doesn't exist
RUN test -f README.md || echo "# Barnacle" > README.md

# Install PDM
RUN pip install --no-cache-dir pdm

# Install dependencies and the package
RUN pdm install --prod --no-lock

# Set Python path
ENV PYTHONPATH=/app/__pypackages__/3.11/lib:/app/src

CMD ["bash"]