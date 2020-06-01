module Env

struct MalEnv
    outer::Any
    data::Dict{Symbol,Any}
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
        error("Symbol $(key) not found in the environment")
    end
    environment.data[key]
end

end