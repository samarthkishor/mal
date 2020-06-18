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

end