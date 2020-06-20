module MalCore

include("printer.jl")
include("reader.jl")
include("types.jl")

using .Printer
using .Reader
using .Types: MalAtom, MalFunction, MalVector, keyword

struct MalException <: Exception
    value::Any
end

function is_keyword(str::String)
    str != "" && str[1] == '\U029E'
end

function is_keyword(::Any)
    false
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

function hash_map(args...)
    keys = [key for (i, key) in enumerate(args) if isodd(i)]
    if !all(key->(key isa Symbol || key isa String), keys)
        error("Hashmap key must either be a string, symbol, or keyword.")
    end
    values = [value for (i, value) in enumerate(args) if iseven(i)]
    Dict(zip(keys, values))
end

function is_list(::Array)
    true
end

function is_list(::Any)
    false
end

function is_vector(lst)
    hasproperty(lst, :vec)
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
    reduce(concat, lsts, init=Any[])
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
    new_args = map(args) do arg
        if hasproperty(arg, :vec)
            arg.vec
        else
            arg
        end
    end
    new_args = Any[Any[new_args[1:end - 1]...]; new_args[end]]

    if hasproperty(f, :fn)
        f.fn(new_args...)
    elseif f isa Function
        f(new_args...)
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

import Base.get
function get(::Nothing, ::Any, ::Any)
    nothing
end

"""
Takes a hash-map as the first argument and the remaining arguments are
odd/even key/value pairs to "associate" (merge) into the hash-map.
"""
function assoc(map::Dict, args...)
    merge(map, hash_map(args...))
end

"""
Takes a hash-map and a list of keys to remove from the hash-map. Again, note
that the original hash-map is unchanged and a new hash-map with the keys
removed is returned. Key arguments that do not exist in the hash-map are
ignored.
"""
function dissoc(map::Dict, remove_keys...)
    new_keys = [key for key in keys(map) if !(key in remove_keys)]
    Dict([(key, map[key]) for key in new_keys])
end

function prn(str)
    println(Printer.pr_str(str))
end

function prn(strs...)
    println(join([Printer.pr_str(str) for str in Any[strs...]], " "))
end

"""
Calls `pr_str` with the `readable` argument on every string and joins them with `sep`.
"""
function str(sep::String, readable::Bool, strs...)
    join([Printer.pr_str(str, readable) for str in strs], sep)
end

ns = Dict{Symbol,Function}(
    :+ => +,
    :- => -,
    :* => *,
    :/ => /,
    :not => not,
    :throw => value->throw(MalException(value)),
    :prn => prn,
    :str => (strs...)->str("", false, strs...),
    :slurp => filename->read(filename, String),
    :symbol => x->Symbol(x),
    :keyword => keyword,
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
    :assoc => assoc,
    :dissoc => dissoc,
    :get => (map, key)->get(map, key, nothing),
    :keys => map->collect(keys(map)),
    :vals => map->collect(values(map)),
    Symbol("atom?") => is_atom,
    Symbol("reset!") => (atom, value)->reset_atom!(atom, value),
    Symbol("swap!") => (atom, f, args...)->swap!(atom, f, args...),
    Symbol("hash-map") => hash_map,
    Symbol("list?") => is_list,
    Symbol("vector?") => is_vector,
    Symbol("sequential?") => lst->(is_list(lst) || is_vector(lst)),
    Symbol("map?") => map->(map isa Dict),
    Symbol("contains?") => (map, key)->haskey(map, key),
    Symbol("empty?") => isempty,
    Symbol("nil?") => value->(value === nothing),
    Symbol("true?") => value->(value === true),
    Symbol("false?") => value->(value === false),
    Symbol("symbol?") => value->(value isa Symbol),
    Symbol("keyword?") => is_keyword,
    Symbol("=") => ==,
    Symbol("<") => <,
    Symbol(">") => >,
    Symbol("<=") => <=,
    Symbol(">=") => >=,
    Symbol("read-string") => Reader.read_str,
    Symbol("pr-str") => (strs...)->str(" ", true, strs...),
)

end