module MalCore

include("printer.jl")
include("reader.jl")
include("types.jl")

using .Printer
using .Reader
using .Types: MalAtom, MalFunction, MalVector

struct MalException <: Exception
    value::Any
end

function not(bool::Bool)
    !bool
end

function not(::Any)
    error("Type of argument to function `not` must be a bool.")
end

function not(args...)
    error("Too many arguments to function `not`")
end

function list(args...)
    Any[args...]
end

function vector(args...)
    Reader.Types.MalVector(list(args...))
end

function is_list(::Array)
    true
end

function is_list(::Any)
    false
end

function first(::Nothing)
    nothing
end

function first(lst::Array)
    lst == [] ? nothing : lst[1]
end

function first(lst)
    lst.vec == [] ? nothing : lst.vec[1]
end

function first(_...)
    error("Type of argument to function `first` must be a sequence.")
end

function rest(::Nothing)
    Any[]
end

function rest(lst::Array)
    lst[2:end]
end

function rest(lst)
    lst.vec[2:end]
end

function rest(_...)
    error("Type of argument to function `rest` must be a sequence.")
end

function nth(lst::Array, i::Int)
    if i < length(lst)
        lst[i + 1]
    else
        error("Out of bounds access to sequence $(lst) with length $(length(lst)) at index $(i)).")
    end
end

function nth(lst, i::Int)
    if i < length(lst.vec)
        lst.vec[i + 1]
    else
        error("Out of bounds access to sequence $(lst.vec) with length $(length(lst.vec)) at index $(i)).")
    end
end

function nth(_...)
    error("Types of arguments to function `nth` must be a sequence and an integer.")
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

function cons(x, lst::Array)
    Any[x, lst...]
end

function cons(x, lst)
    if hasproperty(lst, :vec)
        cons(x, lst.vec)
    else
        error("Cannot cons value $(x) to value $(lst) of Julia type $(typeof(lst))")
    end
end

function concat(a::Array, b::Array)
    vcat(a, b)
end

function concat(a, b)
    if hasproperty(a, :vec) && hasproperty(b, :vec)
        vcat(a.vec, b.vec)
    elseif hasproperty(a, :vec)
        vcat(a.vec, b)
    elseif hasproperty(b, :vec)
        vcat(a, b.vec)
    else
        error("Cannot concatenate list of type $(typeof(a)) and list of type $(typeof(b))")
    end
end

"""
Concatenate lists or vectors, always returning a list.
"""
function concat(lsts...)
    reduce(concat, lsts, init = Any[])
end

"""
The first argument is a function and the last argument is list (or vector).
The arguments between the function and the last argument (if there are any)
are concatenated with the final argument to create the arguments that are
used to call the function. The apply function allows a function to be called
with arguments that are contained in a list (or vector). In other words,
`(apply F A B [C D])` is equivalent to `(F A B C D)`.
"""
function apply(f, args...)
    args = if hasproperty(args, :vec)
        Any[Any[args.vec[1:end - 1]...]; args.vec[end]]
    else
        Any[Any[args[1:end - 1]...]; args[end]]
    end

    if hasproperty(f, :fn)
        f.fn(args...)
    elseif f isa Function
        f(args...)
    else
        error("First argument to `apply` must be a function.")
    end
end

"""
Takes a function and a list (or vector) and evaluates the function against
every element of the list (or vector) one at a time and returns the results
as a list.
"""
function mal_map(f, lst)
    if hasproperty(f, :fn) && hasproperty(lst, :vec)
        map(f.fn, lst.vec)
    elseif hasproperty(f, :fn) && !hasproperty(lst, :vec)
        map(f.fn, lst)
    elseif !hasproperty(f, :fn) && hasproperty(lst, :vec)
        map(f, lst.vec)
    else
        map(f, lst)
    end
end

function prn(str)
    println(Printer.pr_str(str))
end

function prn(strs...)
    println(join([Printer.pr_str(str) for str in Any[strs...]], " "))
end

ns = Dict{Symbol,Function}(
    :+ => +,
    :- => -,
    :* => *,
    :/ => /,
    :not => not,
    :throw => value->throw(MalException(value)),
    :prn => prn,
    :str => (strings...)->join([Printer.pr_str(str, false) for str in strings], ""),
    :slurp => filename->read(filename, String),
    :atom => atom,
    :deref => deref,
    :list => list,
    :vector => vector,
    :count => length,
    :cons => cons,
    :concat => concat,
    :first => first,
    :rest => rest,
    :nth => nth,
    :apply => apply,
    :map => mal_map,
    Symbol("atom?") => is_atom,
    Symbol("reset!") => (atom, value)->reset_atom!(atom, value),
    Symbol("swap!") => (atom, f, args...)->swap!(atom, f, args...),
    Symbol("list?") => is_list,
    Symbol("empty?") => isempty,
    Symbol("nil?") => value->(value === nothing),
    Symbol("true?") => value->(value === true),
    Symbol("false?") => value->(value === false),
    Symbol("symbol?") => value->(value isa Symbol),
    Symbol("=") => ==,
    Symbol("<") => <,
    Symbol(">") => >,
    Symbol("<=") => <=,
    Symbol(">=") => >=,
    Symbol("read-string") => Reader.read_str,
)

end