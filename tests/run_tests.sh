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
  output=$("$@" "$desc" 2>&1)
  exit_code=$?
  last=$(echo "$output" | tail -1)
  local got=$(echo "$last" | grep -o "HALT, [yn]" | grep -o "[yn]")
  if [ $exit_code -ne 0 ]; then
    echo "[FAIL] input=$desc  expect=$label  got=crash"
    echo "       -> $last"
    FAIL=$((FAIL + 1))
  elif echo "$last" | grep -q "$expected"; then
    echo "[OK]   input=$desc  expect=$label"
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
m_pal=res/palindrome.json
run_test_result "a"            "HALT, y" $BIN $m_pal
run_test_result "b"            "HALT, y" $BIN $m_pal
run_test_result "aa"           "HALT, y" $BIN $m_pal
run_test_result "bb"           "HALT, y" $BIN $m_pal
run_test_result "aba"          "HALT, y" $BIN $m_pal
run_test_result "bab"          "HALT, y" $BIN $m_pal
run_test_result "abba"         "HALT, y" $BIN $m_pal
run_test_result "aabbaa"       "HALT, y" $BIN $m_pal
run_test_result "abababa"      "HALT, y" $BIN $m_pal
run_test_result "aaaaaaaaa"    "HALT, y" $BIN $m_pal
run_test_result "ab"           "HALT, n" $BIN $m_pal
run_test_result "ba"           "HALT, n" $BIN $m_pal
run_test_result "abb"          "HALT, n" $BIN $m_pal
run_test_result "aab"          "HALT, n" $BIN $m_pal
run_test_result "abab"         "HALT, n" $BIN $m_pal
run_test_result "aaaaab"       "HALT, n" $BIN $m_pal
run_test_result "abbbbbbbbbbb" "HALT, n" $BIN $m_pal
run_test_result "ynyn"         "HALT, n" $BIN $m_pal
run_test_result "aya"          "HALT, n" $BIN $m_pal
run_test_result "nyn"          "HALT, n" $BIN $m_pal
run_test_result "nan"          "HALT, n" $BIN $m_pal

echo ""
echo "=== 0n1n ==="
m_0n1n=res/0n1n.json
run_test_result "01"         "HALT, y" $BIN $m_0n1n
run_test_result "0011"       "HALT, y" $BIN $m_0n1n
run_test_result "000111"     "HALT, y" $BIN $m_0n1n
run_test_result "0000011111" "HALT, y" $BIN $m_0n1n
run_test_result "00001111"   "HALT, y" $BIN $m_0n1n
run_test_result "0"          "HALT, n" $BIN $m_0n1n
run_test_result "1100"          "HALT, n" $BIN $m_0n1n
run_test_result "01010"          "HALT, n" $BIN $m_0n1n
run_test_result "010"          "HALT, n" $BIN $m_0n1n
run_test "empty input" 1 $BIN $m_0n1n ""
run_test "space input" 1 $BIN $m_0n1n " "
run_test_result "1"          "HALT, n" $BIN $m_0n1n
run_test_result "00"         "HALT, n" $BIN $m_0n1n
run_test_result "11"         "HALT, n" $BIN $m_0n1n
run_test_result "001"        "HALT, n" $BIN $m_0n1n
run_test_result "011"        "HALT, n" $BIN $m_0n1n
run_test_result "0101"       "HALT, n" $BIN $m_0n1n
run_test_result "00111"      "HALT, n" $BIN $m_0n1n
run_test_result "000011"     "HALT, n" $BIN $m_0n1n
run_test_result "10"         "HALT, n" $BIN $m_0n1n
run_test_result "1100"       "HALT, n" $BIN $m_0n1n
run_test_result "n101n"        "HALT, n" $BIN $m_0n1n
run_test_result "n0n"          "HALT, n" $BIN $m_0n1n
run_test_result "01y"          "HALT, n" $BIN $m_0n1n

echo ""
echo "===02n==="
m_02n=res/02n.json
run_test_result "00"         "HALT, y" $BIN $m_02n
run_test_result "000"         "HALT, n" $BIN $m_02n
run_test_result "0000"         "HALT, y" $BIN $m_02n
run_test_result "00000"         "HALT, n" $BIN $m_02n
run_test_result "000000"         "HALT, y" $BIN $m_02n
run_test_result "0000000"         "HALT, n" $BIN $m_05n

echo ""
echo "=== results: $PASS passed, $FAIL failed ==="
