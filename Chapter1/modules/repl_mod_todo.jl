include("mod_todo.jl") 
using .ToDoApp, Dates

todo1 = ToDo(1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5)
# ToDoApp.ToDo(...) is also correct

julia> print_todo(todo1)
# I still have to do: Getting groceries
# A todo created at: 2022-04-01

helper(todo1) 
# ERROR: UndefVarError: helper not defined 