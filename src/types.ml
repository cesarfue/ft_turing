type direction = LEFT | RIGHT

type transition = {
  read : string;
  to_state : string;
  write : string;
  action : direction;
}

type machine = {
  name : string;
  alphabet : string list;
  blank : string;
  states : string list;
  initial : string;
  finals : string list;
  transitions : (string, transition list) Hashtbl.t;
}

type tape = { left : string list; current : string; right : string list }
