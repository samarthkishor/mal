module Printer

include("reader.jl")
using .Reader

function is_keyword(str::String)
    str != "" && str[1] == '\U029E'
end

function pr_str(data::Nothing, readable=true)::String
    "nil"
end

"""
Converts a Mal datatype to a string.
If `readable` is true, then escape the string.
"""
function pr_str(data::String, readable=true)::String
    if is_keyword(data)
        # the first character of a keyword is unicode, so `nextind` takes the byte offset into account
        ":$(data[nextind(data, 1):end])"
    elseif readable
        "\"$(escape_string(data))\""
    else
        data
    end
end

function pr_str(data::Union{Symbol,Int,Float64,Bool}, readable=true)::String
    string(data)
end

function pr_str(::Function, readable=true)::String
    "#<function>"
end

function pr_str(atom::Threads.Atomic, readable=true)::String
    "(atom $(pr_str(atom[], readable)))"
end

function pr_str(lst::Array, readable=true)::String
    "($(join([pr_str(data, readable) for data in lst], " ")))"
end

function pr_str(dict::Dict, readable=true)::String
    """
    {$(join(
        [
            "$(pr_str(key, readable)) $(pr_str(value, readable))"
            for (key, value) in zip(keys(dict), values(dict))
        ],
        " "
    ))}"""
end

# TODO get this to work... Julia includes are really weird
function pr_str(vector::Reader.Types.MalVector, readable=true)::String
    "[$(join([pr_str(data, readable) for data in vector.vec], " "))]"
end

function pr_str(data::Any, readable=true)
    if hasproperty(data, :vec)
        "[$(join([pr_str(d, readable) for d in data.vec], " "))]"
    else
        error("Cannot print value $(data) that has Julia type of $(typeof(data))")
    end
end

end