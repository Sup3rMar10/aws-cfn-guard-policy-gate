#!/usr/bin/env bash
# cfn-guard's native unit tests: one test file per rule file. Exits 1 if any case does not match its expectation.
set -uo pipefail
cd "$(dirname "$0")"

status=0
for name in s3 network iam data tags; do
  echo "== $name"
  out="$(cfn-guard test -r "rules/$name.guard" -t "tests/rule-tests/$name.yaml" 2>&1)"
  rc=$?
  echo "$out" | grep -E 'Test Case|PASS Rules|FAIL Rules|SKIP Rules|Error' | sed 's/^/  /'
  if [ "$rc" -ne 0 ]; then
    echo "  -> cfn-guard test exited $rc"
    echo "$out" | sed 's/^/     /' | head -40
    status=1
  fi
done
exit "$status"
