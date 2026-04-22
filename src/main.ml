let usage () =
  print_endline "usage: ft_turing [-h] jsonfile input";
  print_endline "";
  print_endline "positional arguments:";
  print_endline "  jsonfile    json description of the machine";
  print_endline "  input       input of the machine";
  print_endline "";
  print_endline "optional arguments:";
  print_endline "  -h, --help  show this help message and exit"

let () =
  let args = Sys.argv in
  if Array.length args = 2 && (args.(1) = "-h" || args.(1) = "--help") then (
    usage ();
    exit 0)
  else if Array.length args <> 3 then (
    usage ();
    exit 1)
  else
    let jsonfile = args.(1) in
    let _input = args.(2) in
    let r = Parser.parse_json jsonfile in
    Printf.printf "Fields    : \n\n";
    Printf.printf "%s\n" r.name;
    Printf.printf "[ %s ]\n" (String.concat ", " r.alphabet);
    Printf.printf "%s\n" r.blank;
    Printf.printf "[ %s ]\n" (String.concat ", " r.states);
    Printf.printf "%s\n" r.initial;
    Printf.printf "[ %s ]\n" (String.concat ", " r.finals);
    Hashtbl.iter
      (fun state trans_list ->
        Printf.printf "%s:\n" state;
        List.iter
          (fun t ->
            Printf.printf "  read=%s write=%s to_state=%s\n" t.Types.read
              t.Types.write t.Types.to_state)
          trans_list)
      r.transitions
