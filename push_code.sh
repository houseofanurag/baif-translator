#!/bin/bash

echo "========================================================"
echo "📤 BAIF Offline Translator - GitHub Push Script"
echo "========================================================"
echo ""

# Set colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Change to project directory
PROJECT_DIR=~/baif-translator

if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${RED}❌ Error: Project directory not found at $PROJECT_DIR${NC}"
    echo "   Please update the PROJECT_DIR variable in this script."
    exit 1
fi

cd "$PROJECT_DIR"
echo -e "${BLUE}📁 Working directory: $(pwd)${NC}"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}❌ Error: Git is not installed. Please install git first.${NC}"
    exit 1
fi

# Check if there are any changes to commit
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠️  No changes to commit. Repository is up to date.${NC}"
    echo ""
    echo -e "${GREEN}✅ Nothing to push!${NC}"
    exit 0
fi

# Show what's being committed
echo -e "${BLUE}📝 Files to be committed:${NC}"
git status --short
echo ""

# Ask for confirmation
read -p "Do you want to continue with the push? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}❌ Push cancelled.${NC}"
    exit 0
fi

# Initialize git if needed
if [ ! -d ".git" ]; then
    echo -e "${BLUE}🔧 Initializing git repository...${NC}"
    git init
    git branch -M main
fi

# Ensure remote URL is correct
echo -e "${BLUE}🔗 Setting remote origin...${NC}"
git remote remove origin 2>/dev/null
git remote add origin https://github.com/houseofanurag/baif-translator.git

# Check if remote is accessible
echo -e "${BLUE}🔍 Checking remote connection...${NC}"
if ! git ls-remote origin &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: Cannot reach GitHub. You might need to:${NC}"
    echo "   1. Check your internet connection"
    echo "   2. Use SSH instead of HTTPS: git@github.com:houseofanurag/baif-translator.git"
    echo "   3. Or set up GitHub CLI: gh auth login"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Push cancelled.${NC}"
        exit 0
    fi
fi

# Add all changes
echo -e "${BLUE}📦 Staging files...${NC}"
git add .

# Commit with timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
COMMIT_MSG="Update: BAIF Offline Translator - $TIMESTAMP"

echo -e "${BLUE}💾 Committing changes...${NC}"
if git commit -m "$COMMIT_MSG"; then
    echo -e "${GREEN}✅ Commit successful: $COMMIT_MSG${NC}"
else
    echo -e "${RED}❌ Commit failed.${NC}"
    exit 1
fi

# Push to GitHub
echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
echo ""

# Try with HTTPS first
if git push -u origin main; then
    echo ""
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}✅ Push completed successfully!${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo ""
    echo -e "${BLUE}🔗 Repository URL: https://github.com/houseofanurag/baif-translator${NC}"
    echo -e "${BLUE}📊 View commits: https://github.com/houseofanurag/baif-translator/commits/main${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS push failed. Trying alternative methods...${NC}"
    echo ""
    
    # Try SSH if HTTPS fails
    echo -e "${BLUE}🔑 Attempting SSH push...${NC}"
    git remote remove origin 2>/dev/null
    git remote add origin git@github.com:houseofanurag/baif-translator.git
    
    if git push -u origin main; then
        echo ""
        echo -e "${GREEN}========================================================${NC}"
        echo -e "${GREEN}✅ Push completed successfully using SSH!${NC}"
        echo -e "${GREEN}========================================================${NC}"
    else
        echo -e "${RED}❌ Push failed. Please check:${NC}"
        echo "   1. Your internet connection"
        echo "   2. GitHub credentials (HTTPS) or SSH keys (SSH)"
        echo "   3. Repository permissions"
        echo ""
        echo -e "${YELLOW}💡 To fix authentication issues:${NC}"
        echo "   - For HTTPS: Run 'git config --global credential.helper store' and try again"
        echo "   - For SSH: Run 'ssh-keygen -t rsa -b 4096' and add to GitHub"
        echo "   - Or install GitHub CLI: 'brew install gh' (macOS) or 'choco install gh' (Windows)"
        echo "   - Then run: 'gh auth login' and 'gh repo sync'"
        echo ""
        exit 1
    fi
fi

# Show status
echo ""
echo -e "${BLUE}📊 Current status:${NC}"
git status --short

echo ""
echo -e "${GREEN}🎉 All done!${NC}"