module Reader

using Match

mutable struct MalReader
    tokens::Array{String}
    position::Int64
end

"Returns the reader token at the current position."
function peek(reader::MalReader)::Union{String,Nothing}
    if reader.position > length(reader.tokens)
        return nothing
    end
    reader.tokens[reader.position]
end

"Increments the reader and returns the previous token."
function next!(reader::MalReader)
    if reader.position > length(reader.tokens)
        return nothing
    end
    reader.position += 1
    reader.tokens[reader.position - 1]
end

"Splits a string into Mal tokens."
function tokenize(str::String)
    token_regex = r"[\s,]*(~@|[\[\]{}()'`~^@]|\"(?:\\.|[^\\\"])*\"?|;.*|[^\s\[\]{}('\"`,;)]*)"
    matches = collect(eachmatch(token_regex, str))
    filter(m->m != "", [strip(m.captures[1]) for m in matches])
end

"Reads a Mal list into a Julia array."
function read_list!(reader::MalReader)::Array{Any}
    @assert peek(reader) == "("
    if next!(reader) === nothing
        error("Expected \")\", got EOF")
    end

    lst = []
    while (token = peek(reader)) != ")"
        if token === nothing
            error("Expected \")\", got EOF")
        end
        push!(lst, read_form(reader))
    end
    next!(reader)
    lst
end

"Reads a Mal atom into a Julia type."
function read_atom!(reader::MalReader)::Union{Nothing,Int,Float64,Bool,Symbol}
    token = peek(reader)
    next!(reader)
    if tryparse(Int, token) !== nothing
        parse(Int, token)
    elseif tryparse(Float64, token) !== nothing
        parse(Float64, token)
    elseif token == "true"
        true
    elseif token == "false"
        false
    elseif token == "nil"
        nothing
    else
        Symbol(token)
    end
end

"Reads the appropriate Mal form based on the current token."
function read_form(reader::MalReader)
    @match peek(reader) begin
        "(" => read_list!(reader)
        _ => read_atom!(reader)
    end
end

"Reads a string and parses it into an AST."
function read_str(str::String)::Any
    tokens = tokenize(str)
    if tokens == []
        return nothing
    end
    read_form(MalReader(tokens, 1))  # Julia arrays start at 1
end

end