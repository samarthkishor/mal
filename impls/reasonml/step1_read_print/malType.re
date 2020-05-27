type t =
  | MalList(list(t))
  | MalNumber(int)
  | MalSymbol(string);