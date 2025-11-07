#!/bin/bash

# populate-wiki.sh
# Helper script to populate the GitHub Wiki with documentation from docs/wiki/
#
# Usage:
#   ./scripts/populate-wiki.sh
#
# This script will:
# 1. Clone the wiki repository (separate from main repo)
# 2. Copy markdown files from docs/wiki/ to the wiki
# 3. Commit and push changes to the wiki

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
WIKI_REPO="https://github.com/BabsyIT/Babsy-SSH-Key-Managment.wiki.git"
WIKI_DIR="/tmp/babsy-wiki"
DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/docs/wiki"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}GitHub Wiki Population Script${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check if docs/wiki directory exists
if [ ! -d "$DOCS_DIR" ]; then
    echo -e "${RED}Error: docs/wiki directory not found!${NC}"
    echo "Expected location: $DOCS_DIR"
    exit 1
fi

echo -e "${YELLOW}Step 1: Checking wiki repository...${NC}"

# Clone wiki repo if it doesn't exist, otherwise pull latest
if [ ! -d "$WIKI_DIR" ]; then
    echo "Cloning wiki repository..."
    git clone "$WIKI_REPO" "$WIKI_DIR"
else
    echo "Wiki repository already exists, pulling latest changes..."
    cd "$WIKI_DIR"
    git pull origin master
fi

cd "$WIKI_DIR"

echo -e "${GREEN}✓ Wiki repository ready${NC}"
echo ""

echo -e "${YELLOW}Step 2: Copying wiki files...${NC}"

# Copy markdown files from docs/wiki/ to wiki repo
cp -v "$DOCS_DIR"/*.md "$WIKI_DIR/"

echo -e "${GREEN}✓ Files copied${NC}"
echo ""

echo -e "${YELLOW}Step 3: Checking for changes...${NC}"

# Check if there are changes
if git diff --quiet && git diff --cached --quiet; then
    echo -e "${YELLOW}No changes detected. Wiki is already up to date.${NC}"
    exit 0
fi

echo "Changes detected:"
git status --short

echo ""
echo -e "${YELLOW}Step 4: Committing changes...${NC}"

# Configure git (use your own name/email)
git config user.name "SSH Manager Bot"
git config user.email "ssh-manager@babsy.chh"

# Add all markdown files
git add *.md

# Commit
git commit -m "Update wiki documentation from docs/wiki/

- Home.md: Wiki landing page and navigation
- Production-Deployment.md: 30-minute production setup guide
- Troubleshooting.md: Comprehensive troubleshooting guide
- SETUP-INSTRUCTIONS.md: Wiki setup instructions

Auto-updated by populate-wiki.sh script"

echo -e "${GREEN}✓ Changes committed${NC}"
echo ""

echo -e "${YELLOW}Step 5: Pushing to GitHub...${NC}"

# Push to wiki repo
git push origin master

echo -e "${GREEN}✓ Changes pushed to wiki${NC}"
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Wiki population complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Your wiki is now available at:"
echo "https://github.com/BabsyIT/Babsy-SSH-Key-Managment/wiki"
echo ""
echo "To update the wiki in the future, simply run this script again after"
echo "making changes to files in docs/wiki/"
