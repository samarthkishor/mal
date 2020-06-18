#!/usr/bin/env julia

include("reader.jl")
include("printer.jl")
include("env.jl")
include("core.jl")
include("types.jl")

using .Reader
using .Printer
using .Env: MalEnv
using .MalCore
using .Types: MalFunction, MalAtom, MalVector

function READ(str::String)
    Reader.read_str(str)
end

function eval_ast(ast::Symbol, env::MalEnv)
    Env.get_value(env, ast)
end

function eval_ast(ast::Array, env::MalEnv)
    Any[EVAL(a, env) for a in ast]
end

function eval_ast(ast::Reader.Types.MalVector, env::MalEnv)
    Reader.Types.MalVector(Any[EVAL(a, env) for a in ast.vec])
end

function eval_ast(ast, ::MalEnv)
    ast
end

"""
Evaluates a `let*` expression in the form

    (let* (var1 binding1 var2 binding2) body)

or

    (let* [var1 binding1 var2 binding2] body)

where `args` is in the form `[bindings body]`.
Returns a new environment.
"""
function eval_let(args::Array, env::MalEnv)::Union{MalEnv,ErrorException}
    if length(args) > 2
        error("Incorrect syntax for let binding")
    end

    let_env = Env.MalEnv(env, Dict())
    forms = args[1]  # the forms in the let expression, e.g. `(var1 binding1 var2 binding2)`
    if forms isa Reader.Types.MalVector
        forms = forms.vec
    end

    if isodd(length(forms))
        error("Incorrect forms for let binding")
    end

    vars = Any[arg for (i, arg) in enumerate(forms) if isodd(i)]
    bindings = Any[arg for (i, arg) in enumerate(forms) if iseven(i)]
    for (var, expression) in zip(vars, bindings)
        Env.set!(let_env, var, EVAL(expression, let_env))
    end
    let_env
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
Returns a new function closure.

    (fn* (params) body)

or

    (fn* [params] body)
"""
function eval_fn(args::Array, env::MalEnv)::MalFunction
    params = args[1]
    if params isa Reader.Types.MalVector
        params = params.vec
    end
    body = args[2]
    fn = (closure_params...)->EVAL(body, MalEnv(env, params, Any[closure_params...]))
    MalFunction(params, body, env, fn)
end

function is_pair(lst::Array)
    length(lst) > 0
end

function is_pair(lst::Reader.Types.MalVector)
    length(lst.vec) > 0
end

function is_pair(::Any)
    false
end

function quasiquote(::Nothing)
    nothing
end

function quasiquote(ast)
    if !is_pair(ast)
        Any[:quote, ast]
    elseif ast[1] === :unquote
        ast[2]
    elseif is_pair(ast[1]) && ast[1][1] === Symbol("splice-unquote")
        Any[:concat, ast[1][2], quasiquote(ast[2:end])]
    else
        Any[:cons, quasiquote(ast[1]), quasiquote(ast[2:end])]
    end
end

"""
Returns true if the first symbol in `ast` refers to a macro.
"""
function is_macro_call(ast, env::MalEnv)::Bool
    if ast isa Array && ast != [] && ast[1] isa Symbol
        if Env.find(env, ast[1]) !== nothing
            func = Env.get_value(env, ast[1])
            func isa MalFunction && func.is_macro
        else
            false
        end
    else
        false
    end
end

function mal_macroexpand(ast, env::MalEnv)
    while is_macro_call(ast, env)
        macro_func = Env.get_value(env, ast[1])
        ast = macro_func.fn(ast[2:end]...)
    end
    ast
end

function EVAL(ast, env::MalEnv)
    while true
        # can't use multiple dispatch here because of TCO
        if !(ast isa Array)
            return eval_ast(ast, env)
        end

        if ast == []
            return ast
        end

        ast = mal_macroexpand(ast, env)
        if !(ast isa Array)
            return eval_ast(ast, env)
        end

        if ast == []
            return ast
        end

        # handles special forms
        first = ast[1]
        args = ast[2:end]
        if first === Symbol("def!")
            name = args[1]
            body = args[2]
            ret = EVAL(body, env)
            Env.set!(env, name, ret)
            return ret
        elseif first === Symbol("defmacro!")
            name = args[1]
            body = args[2]
            ret = EVAL(body, env)
            if ret isa MalFunction
                ret.is_macro = true
                Env.set!(env, name, ret)
                return ret
            else
                error("Body of macro cannot be evaluated as a function.")
            end
        elseif first === Symbol("macroexpand")
            body = args[1]
            return mal_macroexpand(body, env)
        elseif first === Symbol("let*")
            env = eval_let(args, env)
            # TCO
            ast = args[2]
        elseif first === Symbol("do")
            # evaluate all the elements of `args` and return the final evaluated element.
            eval_ast(args[1:end - 1], env)
            # TCO
            ast = args[end]
        elseif first === Symbol("if")
            if !(length(args) == 2 || length(args) == 3)
                error("Incorrect form for `if` expression.")
            end
            condition = EVAL(args[1], env)
            if condition !== nothing && is_truthy(condition)
                # condition is truthy, return then block
                # TCO
                ast = args[2]
            else
                # condition is falsy, return else block or nil
                if length(args) == 2
                    return nothing
                else
                    # TCO
                    ast = args[3]
                end
            end
        elseif first === Symbol("fn*")
            return eval_fn(args, env)
        elseif first === Symbol("quote")
            return args[1]
        elseif first === Symbol("quasiquote")
            # TCO
            ast = quasiquote(ast[2])
        else
            evaled_ast = eval_ast(ast, env)
            f = evaled_ast[1]
            evaled_args = evaled_ast[2:end]
            if f isa MalFunction
                # TCO
                ast = f.body
                env = MalEnv(f.env, f.params, evaled_args)
            else
                return f(evaled_args...)
            end
        end
    end
end

function PRINT(f::MalFunction)
    Printer.pr_str(f.fn)
end

function PRINT(a::MalCore.Types.MalAtom)
    "(atom $(Printer.pr_str(a.value)))"
end

function PRINT(vector::Reader.Types.MalVector)
    "[$(join([PRINT(data) for data in vector.vec], " "))]"
end

function PRINT(expression)
    Printer.pr_str(expression)
end

function rep(str::String, env)
    PRINT(EVAL(READ(str), env))
end

function main()
    env = MalEnv(nothing, MalCore.ns)
    Env.set!(env, :eval, (ast->EVAL(ast, env)))

    # Functions defined within Mal
    load_file_fn = raw"""
    (def! load-file
      (fn* (f)
        (eval
          (read-string
            (str
              "(do"
              (slurp f)
              " nil)")))))
    """
    rep(load_file_fn, env)

    cond_macro = raw"""
    (defmacro! cond
      (fn* (& xs)
        (if (> (count xs) 0)
          (list
            'if
            (first xs)
            (if (> (count xs) 1) (nth xs 1) (throw "odd number of forms to cond"))
            (cons 'cond (rest (rest xs)))))))
    """
    rep(cond_macro, env)

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
