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

# Copy requirements from the backend folder into the container
COPY price_ninja_backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend code into the container
COPY price_ninja_backend/ .

# Create data directory for persistence
RUN mkdir -p data

# Expose port
EXPOSE 8000

# Start command
CMD uvicorn main:app --host 0.0.0.0 --port $PORT
