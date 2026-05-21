#!/usr/bin/env python3
"""
Encode any Turing machine JSON into the UTM binary description format.

Separator levels:
  n0 = 0       top-level UTM tape separator (description | state | worktape)
  n1 = 00      first item in a section, or from-state header
  n2 = 000     subsequent items in a section, or transition index
  n3 = 0000    field labels  (read / to_state / write / action)
  n4 = 00000   field values  (symbol / state / action encodings)

Symbol encoding : i-th symbol in alphabet array  → (i + 2) ones
State  encoding : i-th state  in states  array   → (i + 1) ones
Action encoding : LEFT = 1 one  |  RIGHT = 2 ones
Field IDs       : read=1  to_state=11  write=111  action=1111
"""
import argparse
import json
import sys
import os

N1 = "00"
N2 = "000"
N3 = "0000"
N4 = "00000"

FIELD_ID = {"read": "1", "to_state": "11", "write": "111", "action": "1111"}
ACTION = {"LEFT": "1", "RIGHT": "11"}


def ones(n):
    return "1" * n


def encode(machine_path, output_path, readable=False):
    with open(machine_path) as f:
        m = json.load(f)

    alpha = m["alphabet"]
    states = m["states"]
    finals = set(m["finals"])

    sym = {s: ones(i + 2) for i, s in enumerate(alpha)}
    state = {s: ones(i + 1) for i, s in enumerate(states)}

    parts = []  # (code, comment) tuples

    def w(code, comment=""):
        parts.append((code, comment))

    # ---- alphabet -------------------------------------------------------
    if readable:
        w("", "// alphabet")
    for i, s in enumerate(alpha):
        label = f"{s} [blank]" if s == m["blank"] else s
        w((N1 if i == 0 else N2) + sym[s], label)

    # ---- states ---------------------------------------------------------
    if readable:
        w("", "// states")
    for i, s in enumerate(states):
        label = f"{s} [final]" if s in finals else s
        w((N1 if i == 0 else N2) + state[s], label)

    # ---- initial state --------------------------------------------------
    if readable:
        w("", "// initial")
    w(N1 + state[m["initial"]], m["initial"])

    # ---- transitions ----------------------------------------------------
    if readable:
        w("", "// transitions")
    for from_st, trans_list in m["transitions"].items():
        if readable:
            w("", "")
        w(N1 + state[from_st], from_st)
        for idx, t in enumerate(trans_list):
            if readable:
                w("", "")
            w(N2 + ones(idx + 1), f"t{idx + 1}")
            w(N3 + FIELD_ID["read"], "read")
            w(N4 + sym[t["read"]], t["read"])
            w(N3 + FIELD_ID["to_state"], "to_state")
            w(N4 + state[t["to_state"]], t["to_state"])
            w(N3 + FIELD_ID["write"], "write")
            w(N4 + sym[t["write"]], t["write"])
            w(N3 + FIELD_ID["action"], "action")
            w(N4 + ACTION[t["action"]], t["action"])

    if readable:
        lines = []
        for code, comment in parts:
            if not code:
                lines.append(comment)
            elif comment:
                lines.append(f"{code}  // {comment}")
            else:
                lines.append(code)
        result = "\n".join(lines) + "\n"
    else:
        result = "".join(code for code, _ in parts if code) + "\n"

    with open(output_path, "w") as f:
        f.write(result)

    print(f"input    : {machine_path}")
    print(f"output   : {output_path}")
    print(f"symbols  : { {s: sym[s]   for s in alpha}  }")
    print(f"states   : { {s: state[s] for s in states} }")


def main():
    p = argparse.ArgumentParser(
        description="Encode a Turing machine JSON to UTM binary format"
    )
    p.add_argument("machine", help="input machine JSON")
    p.add_argument("output", nargs="?", help="output file (default: <machine>_utm.txt)")
    p.add_argument("--readable", action="store_true", help="add comments and newlines")
    args = p.parse_args()

    if args.output:
        out = args.output
    else:
        with open(args.machine) as f:
            name = json.load(f)["name"]
        suffix = "_readable" if args.readable else ""
        outdir = os.path.join(
            os.path.dirname(os.path.abspath(__file__)), "res", "utm_inputs"
        )
        os.makedirs(outdir, exist_ok=True)
        out = os.path.join(outdir, f"{name}{suffix}.txt")

    encode(args.machine, out, readable=args.readable)


if __name__ == "__main__":
    main()
