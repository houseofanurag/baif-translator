#!/bin/bash

echo "========================================================"
echo "📤 BAIF Offline Translator - GitHub Push Script"
echo "========================================================"
echo ""

# Set colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR=~/baif-translator

# Check if project directory exists
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

# Ask for commit message
echo -e "${CYAN}✏️  Enter commit message (or press Enter for auto-generated):${NC}"
read -p "Commit message: " USER_COMMIT_MSG
echo ""

# Generate commit message
if [ -z "$USER_COMMIT_MSG" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
    COMMIT_MSG="Update: BAIF Offline Translator - $TIMESTAMP"
else
    COMMIT_MSG="$USER_COMMIT_MSG"
fi

echo -e "${BLUE}📝 Commit message: ${COMMIT_MSG}${NC}"
echo ""

# Ask for confirmation
read -p "Continue with push? (y/N): " -n 1 -r
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

# Set remote to HTTPS (not SSH)
echo -e "${BLUE}🔗 Setting remote to HTTPS...${NC}"
git remote remove origin 2>/dev/null
git remote add origin https://github.com/houseofanurag/baif-translator.git

# Add all changes
echo -e "${BLUE}📦 Staging files...${NC}"
git add .

# Commit
echo -e "${BLUE}💾 Committing changes...${NC}"
if git commit -m "$COMMIT_MSG"; then
    echo -e "${GREEN}✅ Commit successful: $COMMIT_MSG${NC}"
else
    echo -e "${RED}❌ Commit failed.${NC}"
    exit 1
fi

echo ""

# ============================================================
# GITHUB AUTHENTICATION - CLI Password Prompt
# ============================================================

echo -e "${CYAN}========================================================${NC}"
echo -e "${CYAN}🔐 GitHub Authentication${NC}"
echo -e "${CYAN}========================================================${NC}"
echo ""

echo -e "${YELLOW}📌 Enter your GitHub credentials:${NC}"
echo -e "   Username: ${BLUE}houseofanurag${NC} (or your GitHub username)"
echo -e "   Password: ${BLUE}Personal Access Token${NC} (with 'repo' scope)"
echo -e "   ${YELLOW}💡 Generate token at: https://github.com/settings/tokens${NC}"
echo ""

# Get username
read -p "👤 GitHub Username [houseofanurag]: " GITHUB_USER
GITHUB_USER=${GITHUB_USER:-houseofanurag}

# Get password/token (hidden input)
echo -n "🔑 GitHub Token/Password: "
read -s GITHUB_TOKEN
echo ""
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}❌ No token provided. Exiting.${NC}"
    exit 1
fi

# ============================================================
# PUSH TO GITHUB
# ============================================================

echo -e "${BLUE}🚀 Pushing to GitHub...${NC}"
echo ""

# Try push with provided credentials
if git push https://$GITHUB_USER:$GITHUB_TOKEN@github.com/houseofanurag/baif-translator.git main -u; then
    echo ""
    echo -e "${GREEN}========================================================${NC}"
    echo -e "${GREEN}✅ Push completed successfully!${NC}"
    echo -e "${GREEN}========================================================${NC}"
    echo ""
    echo -e "${BLUE}🔗 Repository URL: https://github.com/houseofanurag/baif-translator${NC}"
    echo -e "${BLUE}📊 View commits: https://github.com/houseofanurag/baif-translator/commits/main${NC}"
else
    echo ""
    echo -e "${RED}❌ Push failed.${NC}"
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting:${NC}"
    echo "   1. Make sure your token has 'repo' scope"
    echo "   2. Generate a new token: https://github.com/settings/tokens"
    echo "   3. Check your internet connection"
    echo "   4. Verify the repository exists: https://github.com/houseofanurag/baif-translator"
    echo ""
    echo -e "${YELLOW}🔑 To generate a new token:${NC}"
    echo "   1. Go to: https://github.com/settings/tokens"
    echo "   2. Click 'Generate new token (classic)'"
    echo "   3. Select 'repo' scope"
    echo "   4. Copy the token and try again"
    echo ""
    exit 1
fi

# Clear sensitive variables
unset GITHUB_TOKEN
unset GITHUB_USER

# Show final status
echo ""
echo -e "${BLUE}📊 Current status:${NC}"
git status --short

echo ""
echo -e "${GREEN}🎉 All done!${NC}"