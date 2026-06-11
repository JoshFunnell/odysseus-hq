#!/bin/bash
# Rebuild hq-custom from hq/patches.yaml. Run from repo root on any branch
# that contains hq/. Conflicts stop the build with the offending PR number.
set -e
TMP=$(mktemp -d)
cp -r hq "$TMP/"
BASE=$(grep '^base:' "$TMP/hq/patches.yaml" | awk '{print $2}')
git fetch upstream dev --quiet
git checkout -B hq-custom "$BASE"
rm -rf hq && cp -r "$TMP/hq" hq && chmod +x hq/*.sh
git add hq && git commit -q -m "hq: patch-stack tooling + manifest"
for PR in $(grep -oE 'pr: [0-9]+' "$TMP/hq/patches.yaml" | awk '{print $2}'); do
  echo "--- applying PR #$PR"
  git fetch upstream "pull/$PR/head" --quiet
  MB=$(git merge-base FETCH_HEAD upstream/dev)
  for C in $(git rev-list --no-merges --reverse "$MB..FETCH_HEAD"); do
    if ! git cherry-pick "$C"; then
      if [ -z "$(git ls-files -u)" ]; then
        echo "rerere resolved $C; continuing"
        GIT_EDITOR=true git cherry-pick --continue
      else
        echo "CONFLICT on PR #$PR commit $C - resolve, cherry-pick --continue, rerun"
        exit 1
      fi
    fi
  done
done
rm -rf "$TMP"
echo "hq-custom rebuilt at $(git rev-parse --short HEAD)"
