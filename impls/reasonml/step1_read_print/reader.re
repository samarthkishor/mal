type t = {
  form: MalType.t,
  tokens: list(string),
};

type malListReader = {
  malListForm: list(MalType.t),
  tokens: list(string),
};

let tokenize = (str: string): list(string) => {
  let tokenRegex =
    Str.regexp(
      "~@\\|[][{}()'`~^@]\\|\"\\(\\\\.\\|[^\"]\\)*\"?\\|;.*\\|[^][  \n{}('\"`,;)]*",
    );
  let isDelim = strPart =>
    switch (strPart) {
    | Str.Delim(_) => true
    | Str.Text(_) => false
    };
  let extractText = text =>
    switch (text) {
    | Str.Delim(x) => x
    | _ => ""
    };

  Str.full_split(tokenRegex, str)
  |> List.filter(isDelim)
  |> List.map(extractText)
  |> List.filter(str => str != "");
};

let readAtom = (token: string): MalType.t => {
  switch (token.[0]) {
  | '0'..'9' => MalNumber(int_of_string(token))
  | _ => MalSymbol(token)
  };
};

let rec readList = (reader: malListReader): t => {
  switch (reader.tokens) {
  | [] => raise(End_of_file)
  | [token, ...tokens] =>
    switch (token) {
    | ")" => {form: MalList(reader.malListForm), tokens}
    | str =>
      let newReader = readForm(reader.tokens);
      readList({
        malListForm: [newReader.form, ...reader.malListForm],
        tokens,
      });
    }
  };
}
and readForm = (tokens: list(string)): t =>
  switch (tokens) {
  | [] => raise(End_of_file)
  | [token, ...tokens] =>
    switch (token) {
    | "(" => readList({malListForm: [], tokens})
    | _ => {form: readAtom(token), tokens}
    }
  };

let readStr = (str: string): option(MalType.t) =>
  switch (readForm(tokenize(str)).form) {
  | x => Some(x)
  | exception End_of_file => None
  };