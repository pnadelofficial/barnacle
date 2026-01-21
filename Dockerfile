FROM python:3.11-slim

# Install system dependencies (Kraken may need some of these)
RUN apt-get update && apt-get install -y \
    git \
    libxml2 \
    libxslt1.1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy ALL files needed for installation
COPY pyproject.toml pdm.lock README.md ./
COPY src/ ./src/

# Install PDM
RUN pip install --no-cache-dir pdm

# Install dependencies and the package
RUN pdm install --prod --no-lock

# Copy the rest of the application
COPY . .

# Set Python path so modules can be imported
ENV PYTHONPATH=/app/__pypackages__/3.11/lib:/app/src

# Default command
CMD ["bash"]