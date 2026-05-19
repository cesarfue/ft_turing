#!/bin/bash

BIN=./ft_turing
VALID=res/unary_add.json
PASS=0
FAIL=0

run_test() {
  local desc="$1"
  local expect_fail="$2"
  shift 2
  output=$("$@" 2>&1)
  exit_code=$?
  if [ "$expect_fail" = "1" ] && [ $exit_code -ne 0 ]; then
    echo "[OK]   $desc"
    echo "       -> $output"
    PASS=$((PASS + 1))
  elif [ "$expect_fail" = "0" ] && [ $exit_code -eq 0 ]; then
    echo "[OK]   $desc"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $desc"
    echo "       -> exit=$exit_code | $output"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== invalid machine ==="
for f in tests/invalid_machine/*.json; do
  run_test "$(basename $f)" 1 $BIN "$f" "1"
done

echo ""
echo "=== invalid tape ==="
run_test "empty input"              1 $BIN $VALID ""
run_test "blank in tape"            1 $BIN $VALID "1.1"
run_test "char not in alphabet"     1 $BIN $VALID "1X1"

echo ""
echo "=== valid ==="
run_test "unary_add valid"          0 $BIN $VALID "11+11="

echo ""
echo "=== results: $PASS passed, $FAIL failed ==="
