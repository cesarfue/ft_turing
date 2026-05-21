#!/usr/bin/env python3
"""
Parse palindrome.json and generate full_palindrome.json extended to all
26 lowercase letters, following the exact same structural pattern.

How it works:
  - Input letters (a, b) are detected by looking at what find_target routes
    to find_X states.
  - Result symbols (y, n) are detected as everything else in the alphabet
    (excluding blank) that find_target routes elsewhere (to write_n/write_y).
    They are also treated as valid input letters in the full version: the
    per-state guards (read y → write_n) are discarded and y/n are expanded
    as regular pass-through letters, so "naan", "racecar", etc. all work.
  - Per-letter states (find_X, check_X) are instantiated from the template
    (find_a / check_a) for all 26 letters.
  - Fixed states (find_target, check_end, windup, write_y, write_n) have
    their letter transitions expanded to cover all 26 letters.
"""
import json
import copy
import string
import os

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
INPUT  = os.path.join(SCRIPT_DIR, 'res', 'palindrome.json')
OUTPUT = os.path.join(SCRIPT_DIR, 'res', 'full_palindrome.json')

ALL_LETTERS = list(string.ascii_lowercase)   # a … z


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def replace_letter_suffix(state_name, old_letter, new_letter):
    """'find_a' → 'find_c'  when old='a', new='c'; leaves other names unchanged."""
    suffix = '_' + old_letter
    if state_name.endswith(suffix):
        return state_name[:-len(suffix)] + '_' + new_letter
    return state_name


def instantiate(t, old_letter, new_letter):
    """
    Clone transition t, replacing old_letter → new_letter in:
      read, write (when equal to old_letter), and state-name suffix.
    """
    new_t = copy.deepcopy(t)
    if new_t['read']  == old_letter:
        new_t['read']  = new_letter
    if new_t['write'] == old_letter:
        new_t['write'] = new_letter
    new_t['to_state'] = replace_letter_suffix(new_t['to_state'], old_letter, new_letter)
    return new_t


# ---------------------------------------------------------------------------
# Per-letter state expansion  (find_X, check_X, …)
# ---------------------------------------------------------------------------

def expand_per_letter_state(template_trans, tmpl, other_tmpl, new_letter, result_syms):
    """
    Build the full transition list for state prefix_new_letter.

    tmpl       : template letter ('a')  — represents the "own" letter role
    other_tmpl : other  letter ('b')    — represents any "other" letter role
    new_letter : letter being generated
    result_syms: set of result symbols (y, n) — their guards are discarded here
                 because they are covered by the other-letter expansion below
    """
    result = []
    for t in template_trans:
        if t['read'] == tmpl:
            # "own letter" transition → substitute with new_letter
            result.append(instantiate(t, tmpl, new_letter))

        elif t['read'] == other_tmpl:
            # "other letter" pass-through template → expand for every letter ≠ new_letter
            # (this naturally covers result_syms too, replacing the old guards)
            for other in ALL_LETTERS:
                if other == new_letter:
                    continue
                new_t = copy.deepcopy(t)
                new_t['read'] = other
                if new_t['write'] == other_tmpl:   # pass-through write
                    new_t['write'] = other
                new_t['to_state'] = replace_letter_suffix(new_t['to_state'], tmpl, new_letter)
                result.append(new_t)

        elif t['read'] in result_syms:
            # Guard for result symbol (e.g. read y → write_n in find_a).
            # Discarded: already handled by the other-letter expansion above.
            pass

        else:
            # Fixed transition (blank, etc.) — keep but update state suffix
            new_t = copy.deepcopy(t)
            new_t['to_state'] = replace_letter_suffix(new_t['to_state'], tmpl, new_letter)
            result.append(new_t)

    return result


# ---------------------------------------------------------------------------
# Fixed state expansion  (find_target, check_end, windup, write_y, write_n)
# ---------------------------------------------------------------------------

def expand_fixed_state(state_trans, input_letters, tmpl, result_syms):
    """
    Expand a fixed state's transitions to cover all 26 letters.

    Uses the template letter (tmpl) transitions as the model and instantiates
    them for each of the 26 letters (including y, n).  Transitions that belong
    to other input letters (e.g. 'b') or to result-symbol guards are skipped
    as they are redundant / replaced by the expansion.
    """
    template_trans = []
    fixed_trans    = []

    for t in state_trans:
        if t['read'] == tmpl:
            template_trans.append(t)
        elif t['read'] in input_letters or t['read'] in result_syms:
            pass   # covered by template expansion
        else:
            fixed_trans.append(t)   # blank and any other special symbol

    result = []
    for t in template_trans:
        for new_letter in ALL_LETTERS:
            result.append(instantiate(t, tmpl, new_letter))
    result.extend(fixed_trans)
    return result


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    with open(INPUT) as f:
        machine = json.load(f)

    blank = machine['blank']

    # Detect input letters vs result symbols by inspecting find_target:
    #   - letter routed to find_X   → input letter
    #   - letter routed elsewhere   → result symbol
    input_letters  = []
    result_syms    = set()
    for t in machine['transitions'].get('find_target', []):
        sym = t['read']
        if sym == blank:
            continue
        if any(t['to_state'].endswith('_' + sym) for _ in [None]):
            input_letters.append(sym)
        elif t['to_state'].endswith('_' + sym):
            input_letters.append(sym)
        else:
            result_syms.add(sym)

    # Simpler detection: is to_state == f"find_{read}" ?
    input_letters = []
    result_syms   = set()
    for t in machine['transitions'].get('find_target', []):
        sym = t['read']
        if sym == blank:
            continue
        if t['to_state'] == f'find_{sym}':
            input_letters.append(sym)
        else:
            result_syms.add(sym)

    if len(input_letters) < 2:
        raise ValueError("Need at least 2 input letters in the template machine")

    tmpl       = input_letters[0]   # 'a'
    other_tmpl = input_letters[1]   # 'b'

    # --- Identify per-letter state prefixes (find, check, …) --------------
    per_letter_prefixes = []
    seen_prefixes       = set()
    fixed_state_names   = []

    for state in machine['states']:
        matched = False
        for letter in input_letters:
            suffix = '_' + letter
            if state.endswith(suffix) and len(state) > len(suffix):
                prefix = state[:-len(suffix)]
                if prefix not in seen_prefixes:
                    per_letter_prefixes.append(prefix)
                    seen_prefixes.add(prefix)
                matched = True
                break
        if not matched:
            fixed_state_names.append(state)

    # --- Build new states list (preserving original ordering) -------------
    new_states    = []
    seen_emitted  = set()

    for state in machine['states']:
        if state in fixed_state_names:
            new_states.append(state)
        else:
            for letter in input_letters:
                if state.endswith('_' + letter):
                    prefix = state[:-len('_' + letter)]
                    if prefix not in seen_emitted:
                        for new_letter in ALL_LETTERS:
                            new_states.append(f'{prefix}_{new_letter}')
                        seen_emitted.add(prefix)
                    break

    # --- Build transitions -------------------------------------------------
    new_transitions = {}

    for prefix in per_letter_prefixes:
        template_trans = machine['transitions'][f'{prefix}_{tmpl}']
        for new_letter in ALL_LETTERS:
            new_transitions[f'{prefix}_{new_letter}'] = expand_per_letter_state(
                template_trans, tmpl, other_tmpl, new_letter, result_syms
            )

    for state in fixed_state_names:
        if state not in machine['transitions']:
            continue
        new_transitions[state] = expand_fixed_state(
            machine['transitions'][state], input_letters, tmpl, result_syms
        )

    # --- Assemble final machine -------------------------------------------
    new_alphabet = ALL_LETTERS + [blank]
    # keep result symbols if they aren't already in ALL_LETTERS
    for s in sorted(result_syms):
        if s not in new_alphabet:
            new_alphabet.append(s)

    new_machine = {
        "name": "full_palindrome",
        "alphabet": new_alphabet,
        "blank": blank,
        "states": new_states,
        "initial": machine['initial'],
        "finals": machine['finals'],
        "transitions": new_transitions,
    }

    with open(OUTPUT, 'w') as f:
        json.dump(new_machine, f, indent=2)
        f.write('\n')

    total = sum(len(v) for v in new_transitions.values())
    print(f"Generated {OUTPUT}")
    print(f"  alphabet    : {len(new_alphabet)} symbols  ({', '.join(new_alphabet[:5])}, …)")
    print(f"  states      : {len(new_states)}")
    print(f"  transitions : {total}")
    print(f"  result syms : {sorted(result_syms)}  (also valid input letters)")


if __name__ == '__main__':
    main()
