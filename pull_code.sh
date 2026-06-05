#!/bin/bash

echo "📥 Pulling latest code from GitHub..."

cd ~/baif-translator

# Fetch and pull latest changes
git fetch origin
git pull origin main

echo "✅ Latest code pulled successfully!"
echo "Run './run.sh' to start the application."
