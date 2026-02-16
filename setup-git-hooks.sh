#!/bin/bash

# Script to setup git hooks for the FitnessApp project

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔧 Setting up git hooks for FitnessApp..."

# Get the repository root directory
REPO_ROOT=$(git rev-parse --show-toplevel)

if [ -z "$REPO_ROOT" ]; then
    echo "❌ Error: Not in a git repository"
    exit 1
fi

# Set git hooks path to .githooks
git config core.hooksPath .githooks

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Git hooks configured successfully!${NC}"
    echo ""
    echo "Git hooks location: .githooks"
    echo ""
    echo "Available hooks:"
    ls -1 "$REPO_ROOT/.githooks/"
    echo ""
    echo -e "${YELLOW}💡 Make sure you have SwiftFormat installed: brew install swiftformat${NC}"
    echo -e "${YELLOW}💡 Make sure you have SwiftLint installed: brew install swiftlint${NC}"
else
    echo "❌ Error: Failed to configure git hooks"
    exit 1
fi
