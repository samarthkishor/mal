module MalCore

include("printer.jl")

using .Printer

function list(args...)
    Any[args...]
end

function is_list(lst::Array)
    true
end

function is_list(lst)
    false
end

import Base.length
function length(nothing)
    0
end

function prn(str)
    println(Printer.pr_str(str))
end

ns = Dict(
    :+ => +,
    :- => -,
    :* => *,
    :/ => /,
    :prn => prn,
    :list => list,
    :count => length,
    Symbol("list?") => is_list,
    Symbol("empty?") => isempty,
    Symbol("=") => ==,
    Symbol("<") => <,
    Symbol(">") => >,
    Symbol("<=") => <=,
    Symbol(">=") => >=,
)

end