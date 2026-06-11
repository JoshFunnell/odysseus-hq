#!/bin/bash
# Staging smoke: boot this checkout on :7001 with the production venv,
# expect an HTTP response, then kill it. Does not touch the live :7000.
set -e
/opt/odysseus/venv/bin/uvicorn app:app --host 127.0.0.1 --port 7001 \
  > /tmp/ody_smoke.log 2>&1 &
PID=$!
sleep 6
CODE=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://127.0.0.1:7001/ || echo 000)
kill "$PID" 2>/dev/null || true
echo "smoke http=$CODE"
case "$CODE" in 2*|3*) exit 0 ;; *) tail -5 /tmp/ody_smoke.log; exit 1 ;; esac
