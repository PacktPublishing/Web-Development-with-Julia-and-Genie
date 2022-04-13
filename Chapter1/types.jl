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