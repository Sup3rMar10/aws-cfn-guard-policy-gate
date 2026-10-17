#!/usr/bin/env bash
# Run every rule against every fixture and compare with what is expected. Exit 1 on any difference.
#   templates/good/*.yaml   must produce NO failures (compliant, including tricky edge cases)
#   templates/bad/*.yaml    must fail exactly the rules listed in templates/bad/expected.json: no more, no fewer
#
# cfn-guard exits 0 when everything passes and 19 when a rule fails. Anything else (a template or rule file it
# cannot parse, for instance) is an ERROR here, never "no failures": an unreadable template must not look compliant.
set -uo pipefail
cd "$(dirname "$0")"

failed_rules() { # failed_rules <template>: prints the failing rules sorted on one line, or ERROR(<exit code>)
  local out rc
  out="$(cfn-guard validate -r rules -d "$1" --show-summary all 2>&1)"
  rc=$?
  if [ "$rc" -ne 0 ] && [ "$rc" -ne 19 ]; then
    echo "ERROR($rc)"
    return
  fi
  if grep -q -E 'Error occurred|Parsing error' <<<"$out"; then
    echo "ERROR(parse)"
    return
  fi
  grep -E '^[a-z0-9_.]+/[a-z0-9_]+ +FAIL' <<<"$out" | sed -E 's#^[^/]+/([a-z0-9_]+).*#\1#' | sort | tr '\n' ' '
}

bad=0
for f in templates/good/*.yaml; do
  got="$(failed_rules "$f")"
  if [ -n "$got" ]; then echo "UNEXPECTED  $f: $got"; bad=$((bad + 1)); else echo "ok    $f"; fi
done
for f in templates/bad/*.yaml; do
  name="$(basename "$f" .yaml)"
  want="$(python -c "import json,sys; print(' '.join(sorted(json.load(open('templates/bad/expected.json'))[sys.argv[1]])) + ' ')" "$name")"
  got="$(failed_rules "$f")"
  if [ "$got" = "$want" ]; then echo "ok    $f"; else echo "WRONG $f: got [$got] expected [$want]"; bad=$((bad + 1)); fi
done
echo
echo "fixtures with a wrong result: $bad"
[ "$bad" -eq 0 ]
