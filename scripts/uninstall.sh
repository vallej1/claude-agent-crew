#!/bin/bash

# Uninstall Agent Crew skills from ~/.claude/skills/

set -e

SKILLS_DIR="$HOME/.claude/skills"

echo "Uninstalling Agent Crew skills..."

# Remove orchestrator skill
if [ -f "$SKILLS_DIR/orchestrate.md" ]; then
  rm "$SKILLS_DIR/orchestrate.md"
  echo "  ✓ Removed orchestrate.md"
fi

# Remove agent personas
if [ -d "$SKILLS_DIR/crew" ]; then
  rm -rf "$SKILLS_DIR/crew"
  echo "  ✓ Removed crew/ folder"
fi

echo ""
echo "Uninstallation complete!"
