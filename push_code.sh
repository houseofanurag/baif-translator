#!/bin/bash

# 1. Navigate to project directory
cd ~/baif-translator

# 2. Initialize Git if not already a repo
if [ ! -d ".git" ]; then
    git init
    git branch -M main
    echo "Git initialized and branch set to main."
fi

# 3. Ensure remote is correct
git remote remove origin 2>/dev/null
git remote add origin https://github.com/houseofanurag/baif-translator.git

# 4. Clean up: Remove venv from tracking (just in case)
echo "Cleaning up tracking for large files..."
git rm -r --cached venv/ 2>/dev/null
git rm -r --cached .DS_Store 2>/dev/null

# 5. Add and Commit
git add .
# We use || true so the script doesn't stop if there's nothing new to commit
git commit -m "Update: BAIF Offline Translator" || echo "No new changes to commit"

# 6. Push to GitHub
echo "Pushing to GitHub..."
git push -u origin main