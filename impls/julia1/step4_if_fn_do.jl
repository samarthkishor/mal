#!/usr/bin/env julia

include("reader.jl")
include("printer.jl")
include("env.jl")
include("core.jl")

using .Reader
using .Printer
using .Env: MalEnv
using .MalCore

function READ(str::String)
    Reader.read_str(str)
end

function eval_ast(ast::Symbol, env::MalEnv)::Any
    Env.get_value(env, ast)
end

function eval_ast(ast::Array, env::MalEnv)::Any
    [EVAL(a, env) for a in ast]
end

function eval_ast(ast, ::MalEnv)::Any
    ast
end

"""
Evaluates a `let*` expression in the form

    (let* (var1 binding1 var2 binding2) body)

where `args` is in the form `[bindings body]`
"""
function eval_let(args::Array, env::MalEnv)::Union{Any,ErrorException}
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

function is_truthy(value::Bool)
    value != false
end

function is_truthy(::Int64)
    true
end

function is_truthy(value::Any)
    value != false
end

"""
Evaluates a `if` expression in the form

    (if cond then-block)

or

    (if cond then-block else-block)
"""
function eval_if(args::Array{Any}, env::MalEnv)::Union{Any,Nothing,ErrorException}
    if !(length(args) == 2 || length(args) == 3)
        error("Incorrect form for `if` expression.")
    end

    condition = EVAL(args[1], env)
    if condition !== nothing && is_truthy(condition)
        # condition is truthy, return then block
        EVAL(args[2], env)
    else
        # condition is falsy, return else block or nil
        if length(args) == 2
            nothing
        else
            EVAL(args[3], env)
        end
    end
end

"""
Returns a new function closure.

    (fn* (params) body)
"""
function eval_fn(args::Array, env::MalEnv)::Union{Function,ErrorException}
    params = args[1]
    body = args[2]
    (closure_params...)->EVAL(body, MalEnv(env, params, Any[closure_params...]))
end

function EVAL(ast::Any, env::MalEnv)
    eval_ast(ast, env)
end

function EVAL(ast::Any, env::MalEnv)
    eval_ast(ast, env)
end

function EVAL(ast::Array, env::MalEnv)
    if ast == []
        return ast
    end

    # handles special forms
    # TODO get multiple dispatch to work
    first = ast[1]
    args = ast[2:end]
    if first === Symbol("def!")
        name = args[1]
        body = args[2]
        Env.set!(env, name, EVAL(body, env))
    elseif first === Symbol("let*")
        eval_let(args, env)
    elseif first === Symbol("do")
        # Evaluate all the elements of `args` and return the final evaluated element.
        eval_ast(args, env)[end]
    elseif first === Symbol("if")
        eval_if(args, env)
    elseif first === Symbol("fn*")
        eval_fn(args, env)
    else
        evaled_ast = eval_ast(ast, env)
        f = evaled_ast[1]
        evaled_args = evaled_ast[2:end]
        f(evaled_args...)
    end
end

function PRINT(expression)
    Printer.pr_str(expression)
end

function rep(str::String, env)
    PRINT(EVAL(READ(str), env))
end

function main()

    env = MalEnv(nothing, MalCore.ns)

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
