#!/usr/bin/env julia

include("reader.jl")
include("printer.jl")

using .Reader
using .Printer

function READ(str::String)
    Reader.read_str(str)
end

function eval_ast(ast::Symbol, env::Dict{String,Function})
    val = get(env, string(ast), nothing)
    if val === nothing
        error("Error: symbol $(ast) not in environment")
    else
        val
    end
end

function eval_ast(ast::Array, env::Dict{String,Function})
    [EVAL(a, env) for a in ast]
end

function eval_ast(ast, _::Dict{String,Function})
    ast
end

function EVAL(ast, env::Dict{String,Function})
    if !isa(ast, Array)
        eval_ast(ast, env)
    elseif ast == []
        ast
    else
        evaled_ast = eval_ast(ast, env)
        f = evaled_ast[1]
        args = evaled_ast[2:end]
        f(args...)
    end
end

function PRINT(expression)
    Printer.pr_str(expression)
end

function rep(str::String)
    repl_env = Dict(
        "+" => +,
        "-" => -,
        "*" => *,
        "/" => /
    )
    PRINT(EVAL(READ(str), repl_env))
end

function main()
    while true
        print("user> ")
        line = readline()
        if line == ""
            return
        end

        try
            println(rep(line))
        catch e
            println("Error: $(e.msg)")
        end
    end
end

main()
