FROM python:3.10-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install
COPY papaya_disease_system/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the backend code and models
COPY papaya_disease_system/ /app/papaya_disease_system/

# Create a non-root user for Hugging Face compatibility
RUN useradd -m -u 1000 user
USER user
ENV HOME=/home/user \
    PATH=/home/user/.local/bin:$PATH

WORKDIR /app/papaya_disease_system

# Expose port
EXPOSE 7860

# Run the server
# Note: Hugging Face uses port 7860 by default
CMD ["uvicorn", "app.api_server:app", "--host", "0.0.0.0", "--port", "7860"]
