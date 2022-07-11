using Dates

mutable struct ToDo
  id::Int32
  description::String
  completed::Bool
  created::Date
  priority::Int8
end

todo1 = ToDo(1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5)
todo2 = ToDo(2, "Preparing dinner", false, Date("2022-04-02", "yyyy-mm-dd"), 6)

# if:
if todo2.priority > todo1.priority
  println("Better do todo2 first")
else
  println("Better do todo1 first")
end
# "Better do todo2 first"

