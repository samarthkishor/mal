module Printer

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

function pr_str(lst::Array, readable = true)::String
    "($(join([pr_str(data) for data in lst], " ")))"
end

end