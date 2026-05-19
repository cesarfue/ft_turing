open Types
open Util

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
    let input = args.(2) in

    let machine = Parser.make_machine jsonfile in
    let tape = Parser.make_tape machine input in
    Ui.print_header machine;
    Core.run tape machine.initial machine
