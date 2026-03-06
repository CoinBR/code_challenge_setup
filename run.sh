#!/bin/sh


echo "Making script idempotent - always running from the script's directory"
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

. "$SCRIPT_DIR/submodules/megaman/megaman.sh"


echo "Checking if .env file exists with default values"
[ -f .env ] || {
    echo "Creating default .env file..."
    # Generate a valid base32 TOTP secret (only A-Z and 2-7 characters)
    RANDOM_SECRET=$(head -c 20 /dev/urandom | base64 | tr -dc 'A-Z2-7' | head -c 32)
    cat > .env << EOF
TOTP_SECRET=$RANDOM_SECRET
PORT=5000
BASE_URL=https://example.com
ENVIRONMENT=dev
EOF
    echo "⚠️  A random TOTP secret has been generated in .env"
    echo "⚠️  Make sure to configure your authenticator app with this secret: $RANDOM_SECRET"
}

echo "Loading .env file"
. "$SCRIPT_DIR/.env"

echo "Setting proper permissions for the SSH key"
chmod 600 ~/.ssh/github_code_challenge_setup


echo "Checking for old containers..."


echo "Stopping and removing any existing containers"
docker_compose down --remove-orphans

echo "Building and starting containers..."
docker_compose up --build -d

echo "Container status:"
docker_compose ps

echo "Reading port and base URL from .env"
PORT=$(grep PORT .env | cut -d= -f2)
BASE_URL=$(grep BASE_URL .env | cut -d= -f2)

echo "✅ Application should now be running at: $BASE_URL"
echo "Use Ctrl+C to stop following logs, the container will keep running"

echo "Following container logs..."
docker_compose logs -f

default_action() {
  :everything_you_see_above
}
# ! REQUIRED !
# run the functions passed as arguments
run_args "$@"
