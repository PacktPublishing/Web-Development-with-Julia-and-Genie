using Dates

# Array:
todo1 = [1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5]
# 5-element Vector{Any}:
#      1
#       "Getting groceries"
#  false
#       2022-04-01
#      5

# Struct:
mutable struct ToDo
  id::Int32
  description::String
  completed::Bool
  created::Date
  priority::Int8
end

todo1 = ToDo(1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5)
# ToDo(1, "Getting groceries", false, Date("2022-04-01"), 5)

todo1.description
# "Getting groceries"
todo1.completed = true
# true
show(todo1)
display(todo1)

# Symbols:
sym = :info
# :info 
typeof(sym)
# Symbol 

# Functions:
increase_priority!(todo) = todo.priority += 1
todo1.priority          # 5
increase_priority!(todo1) # 6 
todo1.priority            # 6

# increase_priority!("does this work?") 
# ERROR: type String has no field priority 

# Stacktrace: 
# [1] getproperty 
# @ .\Base.jl:42 [inlined] 
# [2] increase_priority!(todo::String) 
# @ Main .\REPL[55]:2 
# [3] top-level scope 
# @ REPL[56]:1 