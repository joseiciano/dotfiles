#!/bin/bash

PROJECT=""
BRANCH=""
WORKSPACE_ROOT="$HOME/Documents/workspace"

usage() {
	echo "Usage: ./delete-worktree-branch.sh <project> <branch-name>"
}

while [ "$#" -gt 0 ]; do
	case "$1" in
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

if ! command -v tmux >/dev/null 2>&1; then
	echo "tmux command not found"
	exit 1
fi

BASE_DIR="$WORKSPACE_ROOT/$PROJECT"
WORKTREE_DIR="$BASE_DIR/$BRANCH"

if [ ! -d "$BASE_DIR" ]; then
	echo "Project not found: $PROJECT"
	echo "Expected directory: $BASE_DIR"
	exit 1
fi

# Keep session naming aligned with scripts/new-worktree-branch.sh.
SESSION_BRANCH_SAFE="${BRANCH//[^[:alnum:]_-]/_}"
WORKTREE_SESSION_NAME="$PROJECT-$SESSION_BRANCH_SAFE"
DELETE_SESSION_NAME="delete-worktree-branch-$SESSION_BRANCH_SAFE"

if tmux has-session -t "$DELETE_SESSION_NAME" 2>/dev/null; then
	echo "tmux session already exists: $DELETE_SESSION_NAME"
	echo "Kill it with: tmux kill-session -t $DELETE_SESSION_NAME"
	exit 1
fi

tmux new-session -d -s "$DELETE_SESSION_NAME" -n "cleanup" -c "$BASE_DIR" || exit 1

printf -v BASE_DIR_Q '%q' "$BASE_DIR"
printf -v WORKTREE_DIR_Q '%q' "$WORKTREE_DIR"
printf -v BRANCH_Q '%q' "$BRANCH"
printf -v WORKTREE_SESSION_NAME_Q '%q' "$WORKTREE_SESSION_NAME"
printf -v DELETE_SESSION_NAME_Q '%q' "$DELETE_SESSION_NAME"

CLEANUP_CMD="cd $BASE_DIR_Q"
CLEANUP_CMD="$CLEANUP_CMD; git worktree remove --force $WORKTREE_DIR_Q"
CLEANUP_CMD="$CLEANUP_CMD; git branch -D $BRANCH_Q"
CLEANUP_CMD="$CLEANUP_CMD; tmux kill-session -t $WORKTREE_SESSION_NAME_Q 2>/dev/null"
CLEANUP_CMD="$CLEANUP_CMD; tmux kill-session -t $DELETE_SESSION_NAME_Q"

tmux send-keys -t "$DELETE_SESSION_NAME:1" "$CLEANUP_CMD" Enter

echo "Started cleanup in tmux session: $DELETE_SESSION_NAME"
