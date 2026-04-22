open Yojson.Basic
open Yojson.Basic.Util

let get_string key json = json |> member key |> to_string

let get_string_list key json =
  json |> member key |> to_list |> List.map to_string

let parse_action str =
  match str with
  | "LEFT" -> Types.LEFT
  | "RIGHT" -> Types.RIGHT
  | _ -> failwith ("unknown action: " ^ str)

let parse_transition tr =
  {
    Types.read = get_string "read" tr;
    to_state = get_string "to_state" tr;
    write = get_string "write" tr;
    action = get_string "action" tr |> parse_action;
  }

let parse_json filename =
  let json = from_file filename in
  let name = get_string "name" json in
  let alphabet = get_string_list "alphabet" json in
  let blank = get_string "blank" json in
  let states = get_string_list "states" json in
  let initial = get_string "initial" json in
  let finals = get_string_list "finals" json in
  let transitions = Hashtbl.create 16 in
  json |> member "transitions" |> to_assoc
  |> List.iter (fun (state, trans_json) ->
      let trans = trans_json |> to_list |> List.map parse_transition in
      Hashtbl.add transitions state trans);
  { Types.name; alphabet; blank; states; initial; finals; transitions }
