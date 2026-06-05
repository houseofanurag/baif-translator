#!/bin/bash

echo "📤 Pushing BAIF Translator to GitHub..."

cd ~/baif-translator

# Initialize if needed
if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

# Ensure remote
git remote remove origin 2>/dev/null
git remote add origin https://github.com/houseofanurag/baif-translator.git

# Add changes
git add .

# Commit
git commit -m "Update: BAIF Offline Translator - $(date '+%Y-%m-%d %H:%M')" || echo "No changes to commit"

# Push
echo "Pushing to GitHub..."
git push -u origin main

echo "✅ Push completed!"
