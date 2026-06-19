#!/bin/bash
# Claude Code PreToolUse hook: Validates git commit commands
# Receives JSON on stdin with tool_input.command
# Exit 0 = allow, Exit 2 = block (stderr shown to Claude)
#
# Input schema (PreToolUse for Bash):
# { "tool_name": "Bash", "tool_input": { "command": "git commit -m ..." } }

INPUT=$(cat)

# Parse command -- use jq if available, fall back to grep
if command -v jq >/dev/null 2>&1; then
    COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
else
    COMMAND=$(echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/"command"[[:space:]]*:[[:space:]]*"//;s/"$//')
fi

# Only process git commit commands
if ! echo "$COMMAND" | grep -qE '^git[[:space:]]+commit'; then
    exit 0
fi

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)
if [ -z "$STAGED" ]; then
    exit 0
fi

WARNINGS=""   # Advisory issues -- printed, but commit is allowed (exit 0)
ERRORS=""     # Blocking issues -- printed, commit is blocked (exit 2)

# B5: Check design documents for required sections.
# BLOCKING for files under design/gdd/** (completeness gate replacing the human
# design-review approval for *completeness*). Advisory remains for any other design
# path, but only design/gdd/ was ever checked here, so nothing new is blocked elsewhere.
DESIGN_FILES=$(echo "$STAGED" | grep -E '^design/gdd/')
if [ -n "$DESIGN_FILES" ]; then
    while IFS= read -r file; do
        if [[ "$file" == *.md ]] && [ -f "$file" ]; then
            MISSING=""
            for section in "Overview" "Player Fantasy" "Detailed" "Formulas" "Edge Cases" "Dependencies" "Tuning Knobs" "Acceptance Criteria"; do
                if ! grep -qi "$section" "$file"; then
                    MISSING="$MISSING $section;"
                fi
            done
            if [ -n "$MISSING" ]; then
                ERRORS="$ERRORS\nDESIGN: $file (design/gdd/) is missing required section(s):$MISSING add them before committing."
            fi
        fi
    done <<< "$DESIGN_FILES"
fi

# Validate JSON data files -- block invalid JSON
DATA_FILES=$(echo "$STAGED" | grep -E '^assets/data/.*\.json$')
if [ -n "$DATA_FILES" ]; then
    # Find a working Python command
    PYTHON_CMD=""
    for cmd in python python3 py; do
        if command -v "$cmd" >/dev/null 2>&1; then
            PYTHON_CMD="$cmd"
            break
        fi
    done

    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if [ -n "$PYTHON_CMD" ]; then
                if ! "$PYTHON_CMD" -m json.tool "$file" > /dev/null 2>&1; then
                    echo "BLOCKED: $file is not valid JSON" >&2
                    exit 2
                fi
            else
                echo "WARNING: Cannot validate JSON (python not found): $file" >&2
            fi
        fi
    done <<< "$DATA_FILES"
fi

# B3: Check for hardcoded gameplay values in gameplay code.
# BLOCKING for src/gameplay/** (data-driven values are required by coding-standards).
# Uses grep -E (POSIX extended) instead of grep -P (Perl) for cross-platform compatibility.
# Suppress the raw grep match (-q) and emit a clean explanatory line instead.
CODE_FILES=$(echo "$STAGED" | grep -E '^src/gameplay/')
if [ -n "$CODE_FILES" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if grep -qnE '(damage|health|speed|rate|chance|cost|duration)[[:space:]]*[:=][[:space:]]*[0-9]+' "$file" 2>/dev/null; then
                ERRORS="$ERRORS\nCODE: $file contains hardcoded gameplay values (src/gameplay/). Move them to data files."
            fi
        fi
    done <<< "$CODE_FILES"
fi

# Check for TODO/FIXME without assignee -- uses grep -E instead of grep -P
SRC_FILES=$(echo "$STAGED" | grep -E '^src/')
if [ -n "$SRC_FILES" ]; then
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if grep -nE '(TODO|FIXME|HACK)[^(]' "$file" 2>/dev/null; then
                WARNINGS="$WARNINGS\nSTYLE: $file has TODO/FIXME without owner tag. Use TODO(name) format."
            fi
        fi
    done <<< "$SRC_FILES"
fi

# B7: Commit message format + story-ID check (WARNING only for now).
# Conventional Commits prefix + a Story:/task-ID reference are required by
# coding-standards. This is advisory (exit 0) to avoid surprising the user; it can be
# escalated to a block by moving the appends below into ERRORS instead of WARNINGS.
# Best-effort: extract the -m message from the command. If no -m message is present
# (editor commit, -F file, etc.), SKIP silently -- do not emit a false warning.
COMMIT_MSG=$(echo "$COMMAND" | grep -oE '\-m[[:space:]]+"[^"]*"' | head -n1 | sed 's/^-m[[:space:]]*"//;s/"$//')
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG=$(echo "$COMMAND" | grep -oE "\-m[[:space:]]+'[^']*'" | head -n1 | sed "s/^-m[[:space:]]*'//;s/'$//")
fi
if [ -n "$COMMIT_MSG" ]; then
    if ! echo "$COMMIT_MSG" | grep -qE '^(feat|fix|chore|docs|test|refactor|perf|style|build|ci)(\(.+\))?!?:'; then
        WARNINGS="$WARNINGS\nFORMAT: commit message should start with a Conventional Commits prefix (feat|fix|chore|docs|test|refactor|perf|style|build|ci): \"$COMMIT_MSG\""
    fi
    if ! echo "$COMMIT_MSG" | grep -qE '(Story:|[A-Z]+-[0-9]+)'; then
        WARNINGS="$WARNINGS\nFORMAT: commit message should reference a story/task ID (e.g. 'Story: EPIC-001-S02' or 'ABC-123')."
    fi
fi

# Print advisory warnings (non-blocking)
if [ -n "$WARNINGS" ]; then
    echo -e "=== Commit Validation Warnings ===$WARNINGS\n================================" >&2
fi

# Print blocking errors and reject the commit if any were found
if [ -n "$ERRORS" ]; then
    echo -e "=== Commit Validation: ERRORS (Blocking) ===$ERRORS\n============================================\nFix these errors before committing." >&2
    exit 2
fi

exit 0
