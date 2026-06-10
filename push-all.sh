#!/bin/bash
echo "🚀 Pushing to both repositories..."
echo "========================================"

# Push to your own repo (normal push)
echo "→ Pushing to your repo (origin)..."
if git push origin main; then
    echo "✅ Successfully pushed to your repo"
else
    echo "❌ Failed to push to your repo"
fi

echo ""
# Push to friend's repo with safer force
echo "→ Pushing to friend's repo (Musicaditya)..."
echo "   (Using --force-with-lease for safety)"

if git push friend main --force-with-lease; then
    echo "✅ Successfully pushed to friend's repo"
else
    echo "❌ Failed to push to friend's repo"
    echo "   Tip: Try 'git pull friend main' first or use --force"
fi

echo ""
echo "========================================"
echo "Done!"
