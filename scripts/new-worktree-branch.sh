#!/bin/bash

# Configuration
PROJECT=""
BRANCH=""
PROMPT=false
AGENT=""
DEFAULT_PROMPT_AGENT="orchestration"
WORKSPACE_ROOT="$HOME/Documents/workspace"

usage() {
  echo "Usage: ./new-worktree-branch.sh <project> <branch-name> [--prompt] [--agent <agent-name>]"
  echo "  --prompt: run opencode prompt in ai window"
  echo "  --agent: opencode agent name (defaults to '$DEFAULT_PROMPT_AGENT' when --prompt is used)"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --prompt)
    PROMPT=true
    shift
    ;;
  --agent)
    if [ "$#" -lt 2 ]; then
      echo "Missing value for $1"
      usage
      exit 1
    fi
    AGENT="$2"
    shift 2
    ;;
  -*)
    echo "Unknown flag: $1"
    usage
    exit 1
    ;;
  *)
    if [ -z "$PROJECT" ]; then
      PROJECT="$1"
      shift
    elif [ -z "$BRANCH" ]; then
      BRANCH="$1"
      shift
    else
      echo "Unexpected argument: $1"
      usage
      exit 1
    fi
    ;;
  esac
done

if [ -z "$PROJECT" ] || [ -z "$BRANCH" ]; then
  usage
  exit 1
fi

BASE_DIR="$WORKSPACE_ROOT/$PROJECT"

if [ ! -d "$BASE_DIR" ]; then
  echo "Project not found: $PROJECT"
  echo "Expected directory: $BASE_DIR"
  exit 1
fi

TARGET_DIR="$BASE_DIR/$BRANCH"

if [ "$PROMPT" = true ] && [ -z "$AGENT" ]; then
  AGENT="$DEFAULT_PROMPT_AGENT"
fi

if [ -n "$AGENT" ] && [ "$PROMPT" != true ]; then
  echo "--agent can only be used with --prompt"
  usage
  exit 1
fi

if [ -n "$AGENT" ]; then
  if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode command not found; cannot validate requested agent '$AGENT'"
    exit 1
  fi

  SUPPORTED_AGENTS=()
  while IFS= read -r supported_agent; do
    if [ -n "$supported_agent" ]; then
      SUPPORTED_AGENTS+=("$supported_agent")
    fi
  done < <(opencode agent list 2>/dev/null | awk '/^[[:alnum:]_.-]+([[:space:]]+\(.*\))?$/ {print $1}')

  if [ "${#SUPPORTED_AGENTS[@]}" -eq 0 ]; then
    echo "Unable to determine supported opencode agents"
    exit 1
  fi

  AGENT_SUPPORTED=false
  for supported_agent in "${SUPPORTED_AGENTS[@]}"; do
    if [ "$supported_agent" = "$AGENT" ]; then
      AGENT_SUPPORTED=true
      break
    fi
  done

  if [ "$AGENT_SUPPORTED" != true ]; then
    echo "Unsupported agent: $AGENT"
    echo "Supported agents:"
    printf '  - %s\n' "${SUPPORTED_AGENTS[@]}"
    exit 1
  fi
fi

# tmux normalizes some characters in session names (e.g. '.' -> '_').
# Normalize explicitly so checks and creation use the same name.
SESSION_BRANCH_SAFE="${BRANCH//[^[:alnum:]_-]/_}"
SESSION_NAME="$PROJECT-$SESSION_BRANCH_SAFE"

if [ -e "$TARGET_DIR" ]; then
  echo "Target path already exists: $TARGET_DIR"
  echo "Choose a different branch name or remove the existing path first."
  exit 1
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "tmux session already exists: $SESSION_NAME"
  echo "Kill it with: tmux kill-session -t $SESSION_NAME"
  exit 1
fi

# 1. Create Git Worktree
if git -C "$BASE_DIR" rev-parse --verify --quiet "$BRANCH" >/dev/null; then
  git -C "$BASE_DIR" worktree add "$TARGET_DIR" "$BRANCH" || exit 1
elif git -C "$BASE_DIR" rev-parse --verify --quiet "origin/$BRANCH" >/dev/null; then
  git -C "$BASE_DIR" worktree add --track -b "$BRANCH" "$TARGET_DIR" "origin/$BRANCH" || exit 1
else
  echo "Branch '$BRANCH' not found; creating it from current HEAD"
  git -C "$BASE_DIR" worktree add -b "$BRANCH" "$TARGET_DIR" || exit 1
fi

# 2. Create detached tmux session
# -s: session name, -n: initial window name, -d: start detached
tmux new-session -d -s "$SESSION_NAME" -n "install" -c "$TARGET_DIR" || exit 1

# 3. Run pnpm i in the first window
tmux send-keys -t "$SESSION_NAME:1" "pnpm i" Enter

# 4. Create second window for dev
tmux new-window -t "$SESSION_NAME" -n "dev" -c "$TARGET_DIR"
tmux send-keys -t "$SESSION_NAME:2" "pnpm dev" Enter

# 5. Create third window for AI work
tmux new-window -t "$SESSION_NAME" -n "ai" -c "$TARGET_DIR"

if [ "$PROMPT" = true ]; then
  STORIES_ROOT="$TARGET_DIR/docs/product/stories/stories"
  BRANCH_DASHED="${BRANCH//./-}"

  if [ ! -d "$STORIES_ROOT" ]; then
    echo "Stories directory not found: $STORIES_ROOT"
  else
    STORY_MATCHES=()
    while IFS= read -r story_path; do
      STORY_MATCHES+=("$story_path")
    done < <(find "$STORIES_ROOT" -type f \( -name "$BRANCH-*.md" -o -name "$BRANCH_DASHED-*.md" \) | LC_ALL=C sort)

    if [ "${#STORY_MATCHES[@]}" -eq 0 ]; then
      echo "No story file found for branch '$BRANCH'"
    else
      if [ "${#STORY_MATCHES[@]}" -eq 1 ]; then
        echo "Story file: ${STORY_MATCHES[0]}"
      else
        echo "Multiple story files found for branch '$BRANCH':"
        printf '  - %s\n' "${STORY_MATCHES[@]}"
        echo "Using first match: ${STORY_MATCHES[0]}"
      fi

      STORY_FILE="${STORY_MATCHES[0]}"
      OPENCODE_PROMPT=$(
        printf '%s\n' \
          "Implement $STORY_FILE end to end." \
          "" \
          "1. Create a plan to ensure we are able to successfully implement it. Detail any changes that will be needed, what files to add/change, what variables/logic will we need." \
          "2. Implement this feature based on the plan." \
          "3. For the implementation, make sure there are tests verifying successful implementation." \
          "4. Make sure any documentation changes are included, if needed." \
          "5. Separate implementation into concise commits." \
          "6. Prompt the user if we'd like to make a pull request."
      )

      if command -v opencode >/dev/null 2>&1; then
        echo "Running opencode prompt in ai window for: $STORY_FILE"
        if [ -n "$AGENT" ]; then
          echo "Using opencode agent: $AGENT"
        fi

        OPENCODE_RUN_CMD="opencode run"
        if [ -n "$AGENT" ]; then
          OPENCODE_RUN_CMD="$OPENCODE_RUN_CMD --agent $(printf '%q' "$AGENT")"
        fi
        OPENCODE_RUN_CMD="$OPENCODE_RUN_CMD $(printf '%q' "$OPENCODE_PROMPT")"

        tmux send-keys -t "$SESSION_NAME:3" "$OPENCODE_RUN_CMD" Enter
      else
        echo "opencode command not found; skipping AI prompt run"
      fi
    fi
  fi
fi

# 6. Switch to the session
# tmux switch-client -t "$SESSION_NAME" || tmux attach-session -t "$SESSION_NAME"
