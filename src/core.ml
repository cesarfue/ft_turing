open Types

let step tape transition machine =
  let new_tape = { tape with current = transition.write } in
  match transition.action with
  | LEFT ->
      {
        left = (match new_tape.left with [] -> [] | _ :: tail -> tail);
        current = (match new_tape.left with [] -> machine.blank | head :: _ -> head);
        right = new_tape.current :: new_tape.right;
      }
  | RIGHT ->
      {
        left = new_tape.current :: new_tape.left;
        current =
          (match new_tape.right with [] -> machine.blank | head :: _ -> head);
        right = (match new_tape.right with [] -> [] | _ :: tail -> tail);
      }

let rec run tape state machine steps limit =
  if steps >= limit then (
    Printf.eprintf
      "Error: execution limit reached %d steps. The machine may not have a \
       solution for the input.\n"
      limit;
    exit 1);
  if not (List.mem state machine.finals) then (
    let possible_transitions =
      match Hashtbl.find_opt machine.transitions state with
      | Some transition -> transition
      | None ->
          Printf.eprintf "Error: no transitions defined for state '%s'\n" state;
          exit 1
    in
    let transition =
      match
        List.find_opt
          (fun trans -> trans.read = tape.current)
          possible_transitions
      with
      | Some transition -> transition
      | None ->
          Printf.eprintf "Error: no transition for state '%s' reading '%s'\n"
            state tape.current;
          exit 1
    in
    Ui.print_progression tape state transition;
    let tape = step tape transition machine in
    run tape transition.to_state machine (steps + 1) limit)
