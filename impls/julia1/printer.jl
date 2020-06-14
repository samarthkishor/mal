module Printer

include("reader.jl")
using .Reader

function pr_str(data::Nothing, readable = true)::String
    "nil"
end

"""
Converts a Mal datatype to a string.
If `readable` is true, then escape the string.
"""
function pr_str(data::String, readable = true)::String
    readable ? "\"$(escape_string(data))\"" : data
end

function pr_str(data::Union{Symbol,Int,Float64}, readable = true)::String
    string(data)
end

function pr_str(data::Bool, readable = true)::String
    string(data)
end

function pr_str(::Function, readable = true)::String
    "#<function>"
end

function pr_str(atom::Threads.Atomic, readable = true)::String
    "(atom $(pr_str(atom[])))"
end

function pr_str(lst::Array, readable = true)::String
    "($(join([pr_str(data) for data in lst], " ")))"
end

# TODO get this to work... Julia includes are really weird
function pr_str(vector::Reader.Types.MalVector, readable = true)::String
    "[$(join([pr_str(data) for data in vector.vec], " "))]"
end

function pr_str(data::Any, readable = true)
    if hasproperty(data, :vec)
        "[$(join([pr_str(d) for d in data.vec], " "))]"
    else
        error("Cannot print value $(data) that has Julia type of $(typeof(data))")
    end
end

end