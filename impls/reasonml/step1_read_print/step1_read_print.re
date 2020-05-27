let read = (str: string): MalType.t =>
  switch (Reader.readStr(str)) {
  | Some(s) => s
  | None => raise(End_of_file)
  };

let eval = (ast: MalType.t) => ast;

let print = (value: MalType.t) => Printer.prStr(value);

let rep = (str: string) => str |> read |> eval |> print;

let rec main = () => {
  print_string("user> ");
  switch (read_line()) {
  | str =>
    switch (print_endline(rep(str))) {
    | () => main()
    | exception End_of_file => Printf.eprintf("EOF\n")
    }
  | exception End_of_file => Printf.eprintf("EOF\n")
  };
};

main();