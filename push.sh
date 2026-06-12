#!/usr/bin/env bash
#
# Push a single file to a branch on the mayfly repo via the GitHub API
# (no local clone needed) and print the artifact preview URL.
#
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: push.sh <branch> <local-file> [dest-path]

Arguments:
  branch      Target branch. Created from the default branch if it doesn't exist.
  local-file  Path to the local file to upload.
  dest-path   Path within the repo (default: basename of local-file).

Environment:
  MAYFLY_REPO  Target repo as "owner/name". Defaults to the repo of the current
               directory (via `gh repo view`), so run this inside your fork's
               clone, or set MAYFLY_REPO explicitly.

Example:
  ./push.sh demo ./page.html
  MAYFLY_REPO=me/mayfly ./push.sh demo ./page.html index.html
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ "$#" -lt 2 ]; then
  usage
  exit "$([ "$#" -lt 2 ] && echo 1 || echo 0)"
fi

BRANCH="$1"
LOCAL_FILE="$2"
DEST_PATH="${3:-$(basename "$LOCAL_FILE")}"

[ -f "$LOCAL_FILE" ] || { echo "error: file not found: $LOCAL_FILE" >&2; exit 1; }

REPO="${MAYFLY_REPO:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
[ -n "$REPO" ] || {
  echo "error: could not determine repo. Set MAYFLY_REPO=owner/name or run inside a clone." >&2
  exit 1
}

# Create the branch from the default branch if it doesn't exist yet.
if ! gh api "repos/$REPO/git/ref/heads/$BRANCH" >/dev/null 2>&1; then
  DEFAULT_BRANCH=$(gh api "repos/$REPO" -q .default_branch)
  BASE_SHA=$(gh api "repos/$REPO/git/ref/heads/$DEFAULT_BRANCH" -q .object.sha)
  gh api -X POST "repos/$REPO/git/refs" \
    -f ref="refs/heads/$BRANCH" -f sha="$BASE_SHA" >/dev/null
  echo "created branch: $BRANCH"
fi

# Existing file blob SHA on that branch (required when updating an existing file).
FILE_SHA=$(gh api "repos/$REPO/contents/$DEST_PATH?ref=$BRANCH" -q .sha 2>/dev/null || true)

CONTENT_B64=$(base64 < "$LOCAL_FILE" | tr -d '\n')

PUT_ARGS=(-X PUT "repos/$REPO/contents/$DEST_PATH"
  -f message="mayfly: update $DEST_PATH"
  -f content="$CONTENT_B64"
  -f branch="$BRANCH")
[ -n "$FILE_SHA" ] && PUT_ARGS+=(-f sha="$FILE_SHA")

COMMIT_SHA=$(gh api "${PUT_ARGS[@]}" -q .commit.sha)
echo "pushed $DEST_PATH -> $REPO@$BRANCH ($COMMIT_SHA)"

# Wait for the Preview workflow to post the preview URL as a commit comment.
printf 'waiting for preview URL'
for _ in $(seq 1 60); do
  URL=$(gh api "repos/$REPO/commits/$COMMIT_SHA/comments" -q '.[].body' 2>/dev/null \
        | grep -oE 'https://github\.com/[^ ]+/artifacts/[0-9]+' | head -n1 || true)
  if [ -n "$URL" ]; then
    printf '\npreview: %s\n' "$URL"
    exit 0
  fi
  printf '.'
  sleep 3
done

printf '\ntimed out waiting for preview comment.\nCheck: https://github.com/%s/commit/%s\n' "$REPO" "$COMMIT_SHA" >&2
exit 1
