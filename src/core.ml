open Types

let step tape transition machine =
  let new_tape = { tape with current = transition.write } in
  match transition.action with
  | LEFT ->
      {
        left = (match new_tape.left with [] -> [] | _ :: t -> t);
        current = (match new_tape.left with [] -> machine.blank | c :: _ -> c);
        right = new_tape.current :: new_tape.right;
      }
  | RIGHT ->
      {
        left = new_tape.current :: new_tape.left;
        current = (match new_tape.right with [] -> machine.blank | c :: _ -> c);
        right = (match new_tape.right with [] -> [] | _ :: t -> t);
      }

let rec run tape state machine =
  if not (List.mem state machine.finals) then (
    let possible_transitions = Hashtbl.find machine.transitions state in
    let transition =
      List.find (fun trans -> trans.read = tape.current) possible_transitions
    in
    Ui.print_progression tape state transition;
    let tape = step tape transition machine in
    run tape transition.to_state machine)
