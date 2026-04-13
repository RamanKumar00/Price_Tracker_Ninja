# Use a pre-built image that already has Python, Chrome and Driver
FROM joyzoursky/python-chromedriver:3.9-selenium

# Set working directory
WORKDIR /app

# Environmental variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV PORT 8000

# Copy requirements from backend folder
COPY price_ninja_backend/requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the backend code
COPY price_ninja_backend/ .

# Create data directory
RUN mkdir -p data

# Expose port
EXPOSE 8000

# Start command
CMD uvicorn main:app --host 0.0.0.0 --port $PORT
