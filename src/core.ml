open Types

let step tape transition =
  let new_tape = { tape with current = transition.write } in
  match transition.action with
  | LEFT ->
      {
        left = List.tl new_tape.left;
        current = List.hd new_tape.left;
        right = new_tape.current :: new_tape.right;
      }
  | RIGHT ->
      {
        left = new_tape.current :: new_tape.left;
        current = List.hd new_tape.right;
        right = List.tl new_tape.right;
      }

let rec run tape state machine =
  if not (List.mem state machine.finals) then (
    let possible_transitions = Hashtbl.find machine.transitions state in
    let transition =
      List.find (fun trans -> trans.read = tape.current) possible_transitions
    in
    Ui.print_progression tape state transition;
    let tape = step tape transition in
    run tape transition.to_state machine)
