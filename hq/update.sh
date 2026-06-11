#!/bin/bash
# Upstream update flow: show drift, optionally bump base to a new pin.
# Usage: hq/update.sh            -> report drift between base and upstream/dev
#        hq/update.sh <new-pin>  -> set base, rebuild, leave testing to you
set -e
git fetch upstream dev --quiet
BASE=$(grep '^base:' hq/patches.yaml | awk '{print $2}')
if [ -z "$1" ]; then
  echo "base: $BASE"
  echo "upstream/dev: $(git rev-parse --short upstream/dev)"
  echo "commits behind: $(git rev-list --count "$BASE"..upstream/dev)"
  git log --oneline "$BASE"..upstream/dev | head -15
  exit 0
fi
sed -i "s/^base: .*/base: $1/" hq/patches.yaml
bash hq/rebuild.sh
echo "Now smoke-test (hq/smoke.sh), then: git push -f origin hq-custom"
