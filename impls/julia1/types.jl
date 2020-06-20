module Types

mutable struct MalFunction
    params::Array
    body
    env  # TODO figure out how to type this
    fn::Function
    is_macro::Bool
    MalFunction(params::Array, body, env, fn::Function) = new(params, body, env, fn, false)
end

mutable struct MalAtom
    value
end

struct MalVector
    vec::Vector
end

function keyword(str::String)
    str[1] == '\U029E' ? str : "\U029E$(str)"
end

function keyword(::Any)
    error("Can only convert strings to keywords")
end

import Base.getindex
function getindex(lst::MalVector, i::Int)
    lst.vec[i]
end

function getindex(lst::MalVector, range::UnitRange)
    getindex(lst.vec, range)
end

import Base.lastindex
function lastindex(lst::MalVector)
    lst.vec[end]
end

import Base.==
function ==(a::MalVector, b::MalVector)
    a.vec == b.vec
end

function ==(a::Array, b::MalVector)
    a == b.vec
end

function ==(a::MalVector, b::Array)
    a.vec == b
end

end