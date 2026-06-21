#!/bin/bash
# Claude Code PreToolUse hook: Validates git push commands
# Warns on pushes to protected branches
# Exit 0 = allow, Exit 2 = block
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git push origin main" } }

INPUT=$(cat)

# Parse command -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git push commands
if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+push'; then
    exit 0
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
MATCHED_BRANCH=""

# Check if pushing to a protected branch
for branch in develop main master; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
        MATCHED_BRANCH="$branch"
        break
    fi
    # Also check if pushing to a protected branch explicitly (quote branch name for safety)
    if echo "$COMMAND" | grep -qE "[[:space:]]${branch}([[:space:]]|$)"; then
        MATCHED_BRANCH="$branch"
        break
    fi
done

# B2: Protected-branch block -- direct pushes to develop/main/master are not allowed.
# This is an outright block (exit 2). Run BEFORE the test gate so we do not waste
# time running tests on a push that will be rejected anyway.
if [ -n "$MATCHED_BRANCH" ]; then
    echo "BLOCKED: direct push to protected branch '$MATCHED_BRANCH'." >&2
    echo "How to fix:" >&2
    echo "  1. Create a feature branch:  git switch -c feature/<short-name>" >&2
    echo "  2. Push the feature branch:  git push origin feature/<short-name>" >&2
    echo "  3. Open a pull request into '$MATCHED_BRANCH' for review/merge." >&2
    exit 2
fi

# B1: Pre-push test gate -- run the test suite (if one is configured) before allowing
# the push. Degrades gracefully: if no engine/test runner/test files exist (fresh
# template state), it skips without blocking. Only reached for non-protected (feature)
# pushes since B2 already exited above for protected branches.

# Find a working Python command (used to invoke pytest as `python -m pytest`)
PYTHON_CMD=""
for cmd in python python3 py; do
    if command -v "$cmd" >/dev/null 2>&1; then
        PYTHON_CMD="$cmd"
        break
    fi
done

if [ -f tests/gdunit4_runner.gd ] && command -v godot >/dev/null 2>&1; then
    # Godot test runner available -- run headless gdUnit4 suite.
    echo "test gate: running Godot test suite (gdunit4_runner.gd)..." >&2
    if ! godot --headless --script tests/gdunit4_runner.gd; then
        echo "BLOCKED: Godot tests failed. Fix failing tests before pushing." >&2
        exit 2
    fi
    echo "test gate: Godot tests passed." >&2
elif [ -d tests ] \
    && [ -n "$PYTHON_CMD" ] \
    && "$PYTHON_CMD" -m pytest --version >/dev/null 2>&1 \
    && [ -n "$(find tests -name 'test_*.py' -o -name '*_test.py' 2>/dev/null)" ]; then
    # pytest available and actual test files exist under tests/.
    echo "test gate: running pytest suite..." >&2
    if ! "$PYTHON_CMD" -m pytest tests; then
        echo "BLOCKED: pytest tests failed. Fix failing tests before pushing." >&2
        exit 2
    fi
    echo "test gate: pytest tests passed." >&2
else
    # No engine / no test runner / no test files -- nothing testable yet.
    echo "test gate: no test suite configured yet, skipping" >&2
fi

exit 0
