open Types

let usage () =
  print_endline "usage: ft_turing [-h] jsonfile input";
  print_endline "";
  print_endline "positional arguments:";
  print_endline "  jsonfile    json description of the machine";
  print_endline "  input       input of the machine";
  print_endline "";
  print_endline "optional arguments:";
  print_endline "  -h, --help  show this help message and exit"

let explode input =
  List.init (String.length input) (fun i -> String.make 1 input.[i])

let init_tape input =
  let chars = explode input in
  match chars with
  | [] -> failwith "empty input"
  | first :: rest -> { Types.left = []; current = first; right = rest }

let run tape state machine =
  if List.mem state machine.finals then Printf.printf "reached final";
  let possible_transitions = Hashtbl.find machine.transitions state in
  let transition =
    List.find (fun trans -> trans.read = tape.current) possible_transitions
  in
  Ui.print_progression tape state transition

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
    let input = args.(2) in

    let machine = Parser.parse_json jsonfile in
    let tape = init_tape input in
    Ui.print_header machine;
    run tape machine.initial machine
