open Types

let width = 80
let tape_filler = 20

let print_centered str =
  let padding = (width - String.length str) / 2 in
  print_endline
    ("*"
    ^ String.make (padding - 1) ' '
    ^ str
    ^ String.make (width - padding - String.length str - 1) ' '
    ^ "*")

let print_transition state transition =
  let action =
    match transition.action with LEFT -> "LEFT" | RIGHT -> "RIGHT"
  in
  Printf.printf "(%s, %s) -> (%s, %s, %s)\n" state transition.read
    transition.to_state transition.write action

let print_progression tape state transition =
  let left_tape = String.concat "" tape.left in
  let right_tape = String.concat "" tape.right in
  let tape_length =
    String.length left_tape + String.length tape.current
    + String.length right_tape
  in
  let filler_length = max 0 (tape_filler - tape_length) in
  let filler = String.make filler_length '.' in
  Printf.printf "[%s<%s>%s%s] " left_tape tape.current right_tape filler;
  print_transition state transition

let print_header machine =
  print_endline (String.make width '*');
  print_centered "";
  print_centered machine.name;
  print_centered "";
  print_endline (String.make width '*');
  Printf.printf "Alphabet : [ %s ]\n" (String.concat ", " machine.alphabet);
  Printf.printf "States   : [ %s ]\n" (String.concat ", " machine.states);
  Printf.printf "Initial  : %s\n" machine.initial;
  Printf.printf "Finals   : [ %s ]\n" (String.concat ", " machine.finals);
  Hashtbl.iter
    (fun state transitions ->
      List.iter (fun t -> print_transition state t) transitions)
    machine.transitions;
  print_endline (String.make width '*')
