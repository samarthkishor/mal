module Env

struct MalEnv
    outer::Any
    data::Dict{Symbol,Any}
end

function MalEnv(::Any)
    MalEnv(nothing, Dict())
end

function MalEnv(outer::Any)
    MalEnv(outer, Dict())
end

function MalEnv(outer::Any, binds::Array, exprs::Array)
    env = MalEnv(outer)
    if binds != [] && exprs == []
        # handle the case where there are no arguments to a function
        # with variadic parameters
        set!(env, binds[end], Any[])
    else
        init!(env, binds, exprs)
    end
    env
end

function init!(env::MalEnv, binds::Array, exprs::Array)
    if length(binds) > length(exprs)
        for (i, bind) in enumerate(binds)
            if bind === :&
                # handle the case for `((fn* (a & xs) ...) 1)`, xs should be `[]`
                # need this because `zip([:a, :&, :xs], [1])` is just `[(:a, 1)]`
                set!(env, binds[i + 1], [])
                return
            end
        end
    end

    for (i, (binding, expr)) in enumerate(zip(binds, exprs))
        # handle variadic function parameters (e.g. `(fn* (& xs) ...`)
        if binding === :&
            if i == length(binds)
                error("Need a parameter after `&`.")
            end

            set!(env, binds[i + 1], exprs[i:end])
            return
        end

        set!(env, binding, expr)
    end
end

"Adds a mapping from symbol `key` => `value` to the environment `env`."
function set!(env::MalEnv, key::Symbol, value::Any)
    env.data[key] = value
end

"""
Takes a symbol `key` and if the current environment contains that key then return the environment.
If no key is found and outer is not `nothing` then call `find` (recurse) on the outer environment.

Returns `nothing` if `key` is not in `env`.
"""
function find(env::MalEnv, key::Symbol)::Union{MalEnv,Nothing}
    value = get(env.data, key, nothing)
    if value !== nothing
        env
    elseif env.outer !== nothing
        find(env.outer, key)
    else
        nothing
    end
end

"""
Locates the environment with the key, then returns the matching value.
If no key is found up the outer chain, then throws a "not found" error.
"""
function get_value(env::MalEnv, key::Symbol)::Union{Any,ErrorException}
    environment = find(env, key)
    if environment === nothing
        error("\'$(key)\' not found")
    end
    environment.data[key]
end

end