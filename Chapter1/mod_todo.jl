module ToDoApp
using Dates

export print_todo
export ToDo

mutable struct ToDo
  id::Int32
  description::String
  completed::Bool
  created::Date
  priority::Int8
end

function print_todo(todo)
  if !todo.completed
    println("I still have to do: $(todo.description)")
    print("A todo created at: ")
    helper(todo)
  end
end

function helper(todo)
   println(todo.created)
end

end
