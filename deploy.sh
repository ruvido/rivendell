#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# Get the current date and time
CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME> Bella secco! "

# Add your deployment commands here
cp -rp rsa/* /root/.ssh
chown -R root:root /root/.ssh
ssh-keyscan -t ed25519 github.com >> /root/.ssh/known_hosts

REPO_DIR="flutterchat"
REPO_URL="git@github.com:scanzy/flutterchat.git"

# Check if the repository directory already exists
if [ -d "$REPO_DIR" ]; then
    echo "Directory $REPO_DIR already exists. Removing it..."
    rm -rf "$REPO_DIR"
fi
echo "Cloning the repository..."
git clone "$REPO_URL"
cd "$REPO_DIR"

# Install dependencies and build the project
echo "Installing flutter dependencies"
flutter pub get
flutter create --platforms web .
echo "Building web application"
flutter build web

# Define version number based on the current timestamp
VERSION_NUMBER=$(date +"%Y%m%d%H%M%S")
DEPLOY_DIR="/app/deploy/$VERSION_NUMBER"

# Create the deployment directory
mkdir -p "$DEPLOY_DIR"

# Copy the build output to the versioned directory
cp -r build/web/* "$DEPLOY_DIR/"

# Create a symbolic link to the latest version
ln -sfn "$VERSION_NUMBER" "/app/deploy/current"

CURRENT_DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
echo "$CURRENT_DATETIME> Deployment completed successfully!"
