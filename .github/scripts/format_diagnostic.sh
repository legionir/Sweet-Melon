#!/usr/bin/env bash
# Publish the exact `dart format` diffs for every unformatted file as a
# pull-request comment, so the formatting can be fixed without access to the
# raw job log. The comment body is a unified diff that `patch -p1` can apply.
#
# Usage: format_diagnostic.sh [targets...]
set -uo pipefail

TARGETS="${*:-lib test integration_test}"
BRANCH="${GITHUB_HEAD_REF:-${GITHUB_REF_NAME:-}}"
REPO="${GITHUB_REPOSITORY:-}"

PR="$(gh pr list --repo "$REPO" --head "$BRANCH" --json number --jq '.[0].number' 2>/dev/null || true)"
if [ -z "$PR" ]; then
  echo "format_diagnostic: no PR found for branch '$BRANCH'; skipping comment"
  exit 0
fi

TMPDIR_FMT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_FMT"' EXIT

dart format --output=none --set-exit-if-changed $TARGETS > "$TMPDIR_FMT/format.txt" 2>&1 || true

CHANGED="$(grep '^Changed ' "$TMPDIR_FMT/format.txt" | sed 's/^Changed //' | head -40)"
if [ -z "$CHANGED" ]; then
  echo "format_diagnostic: everything is formatted"
  exit 0
fi

PATCH_FILE="$TMPDIR_FMT/format.patch"
: > "$PATCH_FILE"
while IFS= read -r f; do
  [ -f "$f" ] || continue
  cp "$f" "$TMPDIR_FMT/orig"
  dart format "$f" > /dev/null 2>&1 || true
  diff -u --label "a/$f" --label "b/$f" "$TMPDIR_FMT/orig" "$f" >> "$PATCH_FILE" || true
  cp "$TMPDIR_FMT/orig" "$f"
done <<< "$CHANGED"

BODY_FILE="$TMPDIR_FMT/comment.md"
{
  echo "## CI diagnostic: dart format diffs"
  echo ""
  echo "- Run: ${GITHUB_SERVER_URL:-https://github.com}/$REPO/actions/runs/${GITHUB_RUN_ID:-unknown}"
  echo "- Commit: ${GITHUB_SHA:-unknown}"
  echo ""
  echo "Unformatted files (apply with \`patch -p1\`):"
  echo ""
  echo '```diff'
  cat "$PATCH_FILE"
  echo '```'
} > "$BODY_FILE"

python3 - "$BODY_FILE" <<'PY'
import sys
p = sys.argv[1]
data = open(p, encoding="utf-8", errors="replace").read()
if len(data) > 60000:
    data = data[:60000] + "\n\n… (truncated)"
open(p, "w", encoding="utf-8").write(data)
PY

gh pr comment "$PR" --repo "$REPO" --body-file "$BODY_FILE" > /dev/null 2>&1 \
  || echo "format_diagnostic: failed to post comment on PR #$PR"
exit 0
