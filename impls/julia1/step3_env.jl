#!/usr/bin/env julia

using Match

include("reader.jl")
include("printer.jl")
include("env.jl")

using .Reader
using .Printer
using .Env: MalEnv

function READ(str::String)
    Reader.read_str(str)
end

function eval_ast(ast::Symbol, env::MalEnv)::Any
    Env.get_value(env, ast)
end

function eval_ast(ast::Array, env::MalEnv)::Any
    [EVAL(a, env) for a in ast]
end

function eval_ast(ast, _::MalEnv)::Any
    ast
end

"""
Evaluates a `let*` expression in the form

    (let* (var1 binding1 var2 binding2) body)

where `args` is in the form `[bindings body]`
"""
function eval_let(env::MalEnv, args::Array{Any})::Any
    if length(args) > 2
        error("Incorrect syntax for let binding")
    end

    let_env = Env.MalEnv(env, Dict())
    forms = args[1]  # the forms in the let expression, e.g. `(var1 binding1 var2 binding2)`
    if isodd(length(forms))
        error("Incorrect forms for let binding")
    end

    vars = [arg for (i, arg) in enumerate(forms) if isodd(i)]
    bindings = [arg for (i, arg) in enumerate(forms) if iseven(i)]
    for (var, expression) in zip(vars, bindings)
        Env.set!(let_env, var, EVAL(expression, let_env))
    end

    body = args[2]
    EVAL(body, let_env)
end

function EVAL(first::Symbol, args::Array{Any}, env::MalEnv)::Any
    if first === Symbol("def!")
        name = args[1]
        body = args[2]
        Env.set!(env, name, EVAL(body, env))
    elseif first === Symbol("let*")
        eval_let(env, args)
    else
        evaled_ast = eval_ast([first; args], env)
        EVAL(evaled_ast[1], evaled_ast[2:end], env)
    end
end

function EVAL(f::Function, args::Array{Any}, _::MalEnv)::Any
    f(args...)
end

function EVAL(ast::Array{Any}, env::MalEnv)::Any
    if ast == []
        ast
    else
        f = ast[1]
        args = ast[2:end]
        EVAL(f, args, env)
    end
end

function EVAL(ast, env::MalEnv)::Any
    eval_ast(ast, env)
end

function PRINT(expression)
    Printer.pr_str(expression)
end

function rep(str::String, env)
    PRINT(EVAL(READ(str), env))
end

function main()

    repl_env = Dict(
        :+ => +,
        :- => -,
        :* => *,
        :/ => /
    )
    env = MalEnv(nothing, repl_env)

    while true
        print("user> ")
        line = readline()
        if line == ""
            return
        end

        try
            println(rep(line, env))
        catch e
            println("Error: $(e.msg)")
        end
    end
end

main()
