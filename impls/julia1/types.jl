module Types

struct MalFunction
    params::Array
    body::Array
    env  # TODO figure out how to type this
    fn::Function
end

end