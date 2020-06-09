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

function is_atom(::Union{MalAtom,Threads.Atomic})
    true
end

function is_atom(::Any)
    false
end

function atom(value::T) where T <: Union{Bool,Int,Float64}
    Threads.Atomic{T}(value)
end

function atom(value::Any)
    MalAtom(value)
end

function deref(atom::MalAtom)
    atom.value
end

function deref(atom::Threads.Atomic)
    atom[]
end

function deref(var::Any)
    error("Cannot dereference non-atomic value $(Printer.pr_str(var)).")
end

function reset_atom!(atom::MalAtom, value::Any)
    atom.value = value
end

function reset_atom!(atom::Threads.Atomic{T}, value::T) where T <: Union{Bool,Int,Float64}
    Threads.atomic_xchg!(atom, value)
    value
end

function reset_atom!(::Threads.Atomic{T}, ::Any) where T <: Union{Bool,Int,Float64}
    # TODO change this to modify the atom by reference since Mal is dynamically typed
    # and technically should be able to reset primitive atoms to non-primitives
    error("Cannot reset a primitive atom (bool, int, float) to a non-primitive value.")
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

function swap!(atom::Threads.Atomic{T}, f::Function, args...) where T <: Union{Bool,Int,Float64}
    value = f(atom[], args...)
    Threads.atomic_xchg!(atom, value)
    value
end

function swap!(atom::Threads.Atomic{T}, f, args...) where T <: Union{Bool,Int,Float64}
    value = f.fn(atom[], args...)
    Threads.atomic_xchg!(atom, value)
    value
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
    :atom => value->atom(value),
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