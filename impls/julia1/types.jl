module Types

struct MalFunction
    params::Array
    body
    env  # TODO figure out how to type this
    fn::Function
end

mutable struct MalAtom
    value
end

end