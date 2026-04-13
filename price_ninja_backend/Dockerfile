# Use an image that already has Python and Chrome installed
FROM joyzoursky/python-chromedriver:3.9-selenium

# Set working directory
WORKDIR /app

# Environmental variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8000

# Install additional parsing tools
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libxslt-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create data directory for persistence
RUN mkdir -p data

# Expose port
EXPOSE 8000

# Start command (using Shell form to allow environment variable expansion)
# Note: In this image, Chrome is already at /usr/bin/google-chrome
CMD uvicorn main:app --host 0.0.0.0 --port $PORT
