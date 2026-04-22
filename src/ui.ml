open Types

let width = 80

let print_centered str =
  let padding = (width - String.length str) / 2 in
  print_endline
    ("*"
    ^ String.make (padding - 1) ' '
    ^ str
    ^ String.make (width - padding - String.length str - 1) ' '
    ^ "*")

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
    (fun state trans_list ->
      List.iter
        (fun t ->
          let action_str =
            match t.action with LEFT -> "LEFT" | RIGHT -> "RIGHT"
          in
          Printf.printf "(%s, %s) -> (%s, %s, %s)\n" state t.read t.to_state
            t.write action_str)
        trans_list)
    machine.transitions;
  print_endline (String.make width '*')
