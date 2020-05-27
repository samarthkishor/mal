let rec prStr = (data: MalType.t): string => {
  switch (data) {
  | MalSymbol(s) => s
  | MalNumber(n) => string_of_int(n)
  | MalList(lst) =>
    "(" ++ String.concat(" ", List.map(prStr, List.rev(lst))) ++ ")"
  };
};