#!/bin/sh
set -e

echo "Making script idempotent - always running from the script's directory"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo "Checking if .env file exists with default values"
[ -f .env ] || {
    echo "Creating default .env file..."
    # Generate a valid base32 TOTP secret (only A-Z and 2-7 characters)
    RANDOM_SECRET=$(head -c 20 /dev/urandom | base64 | tr -dc 'A-Z2-7' | head -c 32)
    cat > .env << EOF
TOTP_SECRET=$RANDOM_SECRET
PORT=5000
BASE_URL=https://example.com
EOF
    echo "⚠️  A random TOTP secret has been generated in .env"
    echo "⚠️  Make sure to configure your authenticator app with this secret: $RANDOM_SECRET"
}

echo "Setting proper permissions for the SSH key"
chmod 600 ~/.ssh/github_code_challenge_setup

echo "Checking for old containers..."

echo "Determining which docker compose command to use"
command -v docker-compose > /dev/null && DOCKER_COMPOSE="docker-compose" || {
    docker compose version > /dev/null 2>&1 && DOCKER_COMPOSE="docker compose" || {
        echo "❌ Error: Neither docker-compose nor docker compose is available"
        echo "Please install Docker and docker-compose to run this application"
        exit 1
    }
}

echo "Stopping and removing any existing containers"
$DOCKER_COMPOSE down --remove-orphans

echo "Building and starting containers..."
$DOCKER_COMPOSE up --build -d

echo "Container status:"
$DOCKER_COMPOSE ps

echo "Reading port and base URL from .env"
PORT=$(grep PORT .env | cut -d= -f2)
BASE_URL=$(grep BASE_URL .env | cut -d= -f2)

echo "✅ Application should now be running at: $BASE_URL"
echo "Use Ctrl+C to stop following logs, the container will keep running"

echo "Following container logs..."
$DOCKER_COMPOSE logs -f

