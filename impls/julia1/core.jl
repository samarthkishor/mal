module MalCore

include("printer.jl")
include("reader.jl")
include("types.jl")

using .Printer
using .Reader
using .Types: MalAtom, MalFunction

function list(args...)
    Any[args...]
end

function is_list(::Array)
    true
end

function is_list(::Any)
    false
end

function is_atom(::MalAtom)
    true
end

function is_atom(::Any)
    false
end

function deref(atom::MalAtom)
    atom.value
end

function deref(var::Any)
    error("Cannot dereference non-atomic value $(Printer.pr_str(var)).")
end

function reset_atom!(atom::MalAtom, value::Any)
    atom.value = value
end

function reset_atom!(var::Any, ::Any)
    error("Cannot reset non-atomic value $(Printer.pr_str(var)).")
end

function swap!(atom::MalAtom, f::Function, args...)
    atom.value = f(atom.value, args...)
end

# TODO fix type for MalFunction
function swap!(atom::MalAtom, f, args...)
    try
        atom.value = f.fn(atom.value, args...)
    catch
        error("Value $(Printer.pr_str(f)) is not a function.")
    end
end

function swap!(var::Any, ::Any, ::Any)
    error("Cannot swap non-atomic value $(Printer.pr_str(var))")
end

import Base.length
function length(nothing)
    0
end

function prn(str)
    println(Printer.pr_str(str))
end

ns = Dict{Symbol,Function}(
    :+ => +,
    :- => -,
    :* => *,
    :/ => /,
    :prn => prn,
    :str => (strings...)->join([Printer.pr_str(str, false) for str in strings], ""),
    :slurp => filename->read(filename, String),
    :atom => value->MalAtom(value),
    :deref => value->deref(value),
    :list => list,
    :count => length,
    Symbol("atom?") => is_atom,
    Symbol("reset!") => (atom, value)->reset_atom!(atom, value),
    Symbol("swap!") => (atom, f, args...)->swap!(atom, f, args...),
    Symbol("list?") => is_list,
    Symbol("empty?") => isempty,
    Symbol("=") => ==,
    Symbol("<") => <,
    Symbol(">") => >,
    Symbol("<=") => <=,
    Symbol(">=") => >=,
    Symbol("read-string") => Reader.read_str,
)

end