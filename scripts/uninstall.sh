#!/bin/bash

# Uninstall Agent Crew skills from ~/.claude/skills/

set -e

SKILLS_DIR="$HOME/.claude/skills"

echo "Uninstalling Agent Crew skills..."

# Remove orchestrator skill
if [ -d "$SKILLS_DIR/orchestrate" ]; then
  rm -rf "$SKILLS_DIR/orchestrate"
  echo "  ✓ Removed orchestrate"
fi

# Remove agent personas
if [ -d "$SKILLS_DIR/crew" ]; then
  rm -rf "$SKILLS_DIR/crew"
  echo "  ✓ Removed crew/ folder"
fi

echo ""
echo "Uninstallation complete!"
