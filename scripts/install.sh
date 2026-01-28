#!/bin/bash

# Install Agent Crew skills to ~/.claude/skills/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$HOME/.claude/skills"

echo "Installing Agent Crew skills..."

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DIR/crew"

# Copy orchestrator skill
cp "$PROJECT_DIR/skills/orchestrate.md" "$SKILLS_DIR/orchestrate.md"
echo "  ✓ Installed orchestrate.md"

# Copy agent personas
for persona in market-researcher product-manager architect developer qa-tester devops customer-support; do
  cp "$PROJECT_DIR/skills/crew/$persona.md" "$SKILLS_DIR/crew/$persona.md"
  echo "  ✓ Installed crew/$persona.md"
done

echo ""
echo "Installation complete!"
echo ""
echo "Skills installed to: $SKILLS_DIR"
echo ""
echo "Usage:"
echo "  /orchestrate Build a todo app"
echo "  /orchestrate Build an API --constraints \"Python, FastAPI\""
