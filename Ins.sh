#!/bin/bash

# Set your Cloudflare account details
CF_API_TOKEN="your_cloudflare_api_token"
CF_ACCOUNT_ID="your_cloudflare_account_id"
WORKER_NAME="your_worker_name"

# ANSI escape codes for colors
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Prompt the user for their Cloudflare API token, account ID, and desired Worker name
echo "Please enter your Cloudflare API token:"
read -r CF_API_TOKEN

echo "Please enter your Cloudflare account ID:"
read -r CF_ACCOUNT_ID

echo "Please enter the desired Worker name:"
read -r WORKER_NAME

# Use Wrangler to generate a new Worker project
wrangler generate "$WORKER_NAME"

# Navigate to the project directory
cd "$WORKER_NAME" || exit

# Create wrangler.toml file with user input
cat > wrangler.toml <<EOF
name = "$WORKER_NAME"
type = "webpack"
account_id = "$CF_ACCOUNT_ID"
workers_dev = true

# Add other configurations if needed
EOF

# Create package.json file with default content
cat > package.json <<EOF
{
  "name": "$WORKER_NAME",
  "version": "1.0.0",
  "scripts": {
    "start": "wrangler dev",
    "publish": "wrangler publish"
  },
  "main": "worker.js",
  "license": "MIT"
}
EOF

# Create package-lock.json file with default content
cat > package-lock.json <<EOF
{
  "name": "$WORKER_NAME",
  "version": "1.0.0",
  "lockfileVersion": 1,
  "requires": true,
  "dependencies": {}
}
EOF

# Authenticate Wrangler with the provided API token
wrangler config --api-key "$CF_API_TOKEN"

# Prompt the user for the URL of the worker.js file
echo "Please enter the URL of the worker.js file:"
read -r WORKER_JS_URL

# Fetch the worker.js content from the provided URL
curl -o worker.js "$WORKER_JS_URL"

# Publish the Worker using Wrangler
wrangler publish

# Output the Worker URL
echo "${GREEN}Your Worker has been deployed successfully!${RESET}"
echo "You can access it at: https://${WORKER_NAME}.${CF_ACCOUNT_ID}.workers.dev"
