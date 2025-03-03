FROM python:3.9-slim

# Install git and SSH client
RUN apt-get update && \
    apt-get install -y git openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Configure Git globally
RUN git config --global user.email "coinbr+github_code_challenge_setup@gmail.com" && \
    git config --global user.name "CodeChallenge Template Setup" && \
    git config --global init.defaultBranch main

# Set up SSH for GitHub
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh && \
    echo "Host github.com\n\tStrictHostKeyChecking no\n\tIdentityFile /root/.ssh/github_code_challenge_setup" > /root/.ssh/config && \
    chmod 600 /root/.ssh/config

# Copy requirements first to leverage Docker cache
COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app/ .

# Expose the port (will be dynamically set from .env)
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]

