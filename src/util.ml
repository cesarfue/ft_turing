let explode str =
  List.init (String.length str) (fun i -> String.make 1 str.[i])
