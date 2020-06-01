module Printer

function pr_str(data::Nothing)::String
    "nil"
end

function pr_str(data::String)::String
    data
end

function pr_str(data::Union{Symbol,Int,Float64})::String
    string(data)
end

function pr_str(data::Bool)::String
    string(data)
end

function pr_str(lst::Array{Any})::String
    "($(join([pr_str(data) for data in lst], " ")))"
end

end