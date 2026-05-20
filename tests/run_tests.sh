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
  elif [ "$expect_fail" = "0" ] && [ $exit_code -eq 0 ]; then
    echo "[OK]   $desc"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] $desc"
    echo "       -> $(echo "$output" | tail -1)"
    FAIL=$((FAIL + 1))
  fi
}

run_test_result() {
  local desc="$1"
  local expected="$2"
  local label=$(echo "$expected" | grep -o "HALT, [yn]" | grep -o "[yn]")
  shift 2
  output=$("$@" 2>&1)
  exit_code=$?
  last=$(echo "$output" | tail -1)
  local got=$(echo "$last" | grep -o "HALT, [yn]" | grep -o "[yn]")
  if [ $exit_code -ne 0 ]; then
    echo "[FAIL] input=$desc  expect=$label  got=crash"
    echo "       -> $last"
    FAIL=$((FAIL + 1))
  elif echo "$last" | grep -q "$expected"; then
    echo "[OK]   input=$desc  expect=$label  got=$label"
    PASS=$((PASS + 1))
  else
    echo "[FAIL] input=$desc  expect=$label  got=${got:-?}"
    echo "       -> $last"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== invalid machine ==="
for f in tests/invalid_machine/*.json; do
  run_test "$(basename $f)" 1 $BIN "$f" "1"
done

echo ""
echo "=== invalid tape ==="
run_test "empty input"          1 $BIN $VALID ""
run_test "blank in tape"        1 $BIN $VALID "1.1"
run_test "char not in alphabet" 1 $BIN $VALID "1X1"

echo ""
echo "=== unary_add ==="
run_test "1+1"      0 $BIN res/unary_add.json "1+1="
run_test "11+11"    0 $BIN res/unary_add.json "11+11="
run_test "0+0"      0 $BIN res/unary_add.json "+="

echo ""
echo "=== palindrome ==="
PALI=res/palindrome.json
run_test_result "a"             "HALT, y" $BIN $PALI "a"
run_test_result "b"             "HALT, y" $BIN $PALI "b"
run_test_result "aa"            "HALT, y" $BIN $PALI "aa"
run_test_result "bb"            "HALT, y" $BIN $PALI "bb"
run_test_result "aba"           "HALT, y" $BIN $PALI "aba"
run_test_result "bab"           "HALT, y" $BIN $PALI "bab"
run_test_result "abba"          "HALT, y" $BIN $PALI "abba"
run_test_result "aabbaa"        "HALT, y" $BIN $PALI "aabbaa"
run_test_result "abababa"       "HALT, y" $BIN $PALI "abababa"
run_test_result "aaaaaaaaa"     "HALT, y" $BIN $PALI "aaaaaaaaa"
run_test_result "ab"            "HALT, n" $BIN $PALI "ab"
run_test_result "ba"            "HALT, n" $BIN $PALI "ba"
run_test_result "abb"           "HALT, n" $BIN $PALI "abb"
run_test_result "aab"           "HALT, n" $BIN $PALI "aab"
run_test_result "abab"          "HALT, n" $BIN $PALI "abab"
run_test_result "aaaaab"        "HALT, n" $BIN $PALI "aaaaab"
run_test_result "abbbbbbbbbbb"  "HALT, n" $BIN $PALI "abbbbbbbbbbb"
run_test "x not in input"       1 $BIN $PALI "axb"
run_test "y not in input"       1 $BIN $PALI "ayb"
run_test "n not in input"       1 $BIN $PALI "anb"

echo ""
echo "=== 0n1n ==="
ZO=res/0n1n.json
run_test_result "01"            "HALT, y" $BIN $ZO "01"
run_test_result "0011"          "HALT, y" $BIN $ZO "0011"
run_test_result "000111"        "HALT, y" $BIN $ZO "000111"
run_test_result "0000011111"    "HALT, y" $BIN $ZO "0000011111"
run_test_result "00001111"      "HALT, y" $BIN $ZO "00001111"
run_test_result "0"        "HALT, n" $BIN $ZO "0"
run_test_result "1"        "HALT, n" $BIN $ZO "1"
run_test_result "00"       "HALT, n" $BIN $ZO "00"
run_test_result "11"       "HALT, n" $BIN $ZO "11"
run_test_result "001"           "HALT, n" $BIN $ZO "001"
run_test_result "011"           "HALT, n" $BIN $ZO "011"
run_test_result "0101"          "HALT, n" $BIN $ZO "0101"
run_test_result "00111"  "HALT, n" $BIN $ZO "00111"
run_test_result "000011" "HALT, n" $BIN $ZO "000011"
run_test_result "10"   "HALT, n" $BIN $ZO "10"
run_test_result "1100" "HALT, n" $BIN $ZO "1100"

echo ""
echo "=== results: $PASS passed, $FAIL failed ==="
