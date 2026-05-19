open Util
open Yojson.Basic
open Yojson.Basic.Util
open Types

let error msg = failwith ("Error: " ^ msg)

let get_string key json =
  match member key json with
  | `Null -> error ("missing field '" ^ key ^ "'")
  | `String s ->
      if s = "" then error ("field '" ^ key ^ "' is empty");
      s
  | _ -> error ("field '" ^ key ^ "' must be a string")

let get_string_list key json =
  match member key json with
  | `Null -> error ("missing field '" ^ key ^ "'")
  | `List lst ->
      if lst = [] then error ("field '" ^ key ^ "' is empty");
      List.map
        (fun v ->
          match v with
          | `String s ->
              if s = "" then
                error ("field '" ^ key ^ "' contains an empty string");
              s
          | _ -> error ("field '" ^ key ^ "' must be a list of strings"))
        lst
  | _ -> error ("field '" ^ key ^ "' must be a list")

let has_duplicates lst =
  let deduped = List.sort_uniq String.compare lst in
  List.length deduped <> List.length lst

let parse_action str =
  match str with
  | "LEFT" -> Types.LEFT
  | "RIGHT" -> Types.RIGHT
  | _ -> error ("unknown action: " ^ str)

let parse_transition tr =
  {
    Types.read = get_string "read" tr;
    to_state = get_string "to_state" tr;
    write = get_string "write" tr;
    action = get_string "action" tr |> parse_action;
  }

let check_mem m =
  if not (List.mem m.blank m.alphabet) then
    error ("blank '" ^ m.blank ^ "' is not in alphabet");
  if not (List.mem m.initial m.states) then
    error ("initial state '" ^ m.initial ^ "' is not in states");
  List.iter
    (fun f ->
      if not (List.mem f m.states) then
        error ("final state '" ^ f ^ "' is not in states"))
    m.finals;
  Hashtbl.iter
    (fun state trans ->
      if not (List.mem state m.states) then
        error ("transition state '" ^ state ^ "' is not in states");
      List.iter
        (fun t ->
          if not (List.mem t.read m.alphabet) then
            error
              ("read '" ^ t.read ^ "' in state '" ^ state
             ^ "' is not in alphabet");
          if not (List.mem t.to_state m.states) then
            error
              ("to_state '" ^ t.to_state ^ "' in state '" ^ state
             ^ "' is not in states");
          if not (List.mem t.write m.alphabet) then
            error
              ("write '" ^ t.write ^ "' in state '" ^ state
             ^ "' is not in alphabet"))
        trans)
    m.transitions

let check_dup m =
  if has_duplicates m.alphabet then error "alphabet contains duplicates";
  if has_duplicates m.states then error "states contains duplicates";
  if has_duplicates m.finals then error "finals contains duplicates";
  Hashtbl.iter
    (fun state trans ->
      let reads = List.map (fun t -> t.read) trans in
      if has_duplicates reads then
        error ("state '" ^ state ^ "' has duplicate read symbols"))
    m.transitions

let check_single_char m =
  if String.length m.blank <> 1 then
    error ("blank '" ^ m.blank ^ "' must be a single character");
  List.iter
    (fun s ->
      if String.length s <> 1 then
        error ("alphabet symbol '" ^ s ^ "' must be a single character"))
    m.alphabet

let check_initial_not_final m =
  if List.mem m.initial m.finals then
    error ("initial state '" ^ m.initial ^ "' cannot be a final state")

let validate_machine m =
  check_single_char m;
  check_dup m;
  check_mem m;
  check_initial_not_final m

let make_machine filename =
  if not (Sys.file_exists filename || Sys.is_directory filename) then
    error ("file not found: " ^ filename);
  let json =
    try from_file filename with
    | Sys_error msg -> error msg
    | Yojson.Json_error msg -> error ("invalid JSON: " ^ msg)
  in
  (match json with `Assoc _ -> () | _ -> error "invalid JSON");
  let name = get_string "name" json in
  let alphabet = get_string_list "alphabet" json in
  let blank = get_string "blank" json in
  let states = get_string_list "states" json in
  let initial = get_string "initial" json in
  let finals = get_string_list "finals" json in
  let transitions = Hashtbl.create 16 in
  (match member "transitions" json with
  | `Null -> error "missing field 'transitions'"
  | `Assoc pairs ->
      List.iter
        (fun (state, trans_json) ->
          (match trans_json with
          | `List _ -> ()
          | _ -> error ("transitions for state '" ^ state ^ "' must be a list"));
          let trans = trans_json |> to_list |> List.map parse_transition in
          Hashtbl.add transitions state trans)
        pairs
  | _ -> error "invalid transitions");
  let machine =
    { Types.name; alphabet; blank; states; initial; finals; transitions }
  in
  validate_machine machine;
  machine

let validate_tape machine chars =
  if chars = [] then error "input is empty";
  if List.mem machine.blank chars then
    error ("tape contains blank character '" ^ machine.blank ^ "'");
  List.iter
    (fun c ->
      if not (List.mem c machine.alphabet) then
        error ("tape character '" ^ c ^ "' is not in alphabet"))
    chars

let make_tape machine input =
  let chars = explode input in
  validate_tape machine chars;
  match chars with
  | [] -> assert false
  | first :: rest -> { Types.left = []; current = first; right = rest }
