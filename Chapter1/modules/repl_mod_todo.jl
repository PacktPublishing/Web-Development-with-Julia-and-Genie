# use the following code in the REPL:
include("ToDoApp.jl") 
using .ToDoApp, Dates

todo1 = ToDo(1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5)
# ToDoApp.ToDo(...) is also correct

print_todo(todo1)
# I still have to do: Getting groceries
# A todo created at: 2022-04-01

# helper(todo1) 
# ERROR: UndefVarError: helper not defined

# hw-owever, this works:
ToDoApp.helper(todo1) # => 2022-04-01