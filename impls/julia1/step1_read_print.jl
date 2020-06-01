#!/usr/bin/env julia

include("reader.jl")
include("printer.jl")

using .Reader
using .Printer

function READ(str::String)
    try
        Reader.read_str(str)
    catch e
        println("Error: $(e.msg)")
        nothing
    end
end

function EVAL(ast)
    ast
end

function PRINT(expression)
    Printer.pr_str(expression)
end

function rep(str::String)
    PRINT(EVAL(READ(str)))
end

function main()
    while true
        print("user> ")
        line = readline()
        if line == ""
            return
        end

        try
            println(rep(line))
        catch e
            println("Error: $(e.msg)")
        end
    end
end

main()
