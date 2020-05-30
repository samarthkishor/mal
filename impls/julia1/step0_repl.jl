#!/usr/bin/env julia

function READ(str)
    str
end

function EVAL(ast)
    ast
end

function PRINT(expression)
    expression
end

function rep(str)
    str |> READ |> EVAL |> PRINT
end

function main()
    while true
        print("user> ")
        line = readline()
        if line == ""
            return
        end
        line |> rep |> println
    end
end

main()
