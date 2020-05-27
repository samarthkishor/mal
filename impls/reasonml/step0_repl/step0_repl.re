let read = (str: string) => str;

let eval = (ast: string) => ast;

let print = (value: string) => value;

let rep = (str: string) => str |> read |> eval |> print;

let rec main = () => {
  print_string("user> ");
  switch (read_line()) {
  | str =>
    print_endline(rep(str));
    main();
  | exception End_of_file => ()
  };
};

main();