ex = :(a + b * c + 1)
a = 1
b = 2
c = 3
println("ex is $ex") # => ex is a + b * c + 1
println("ex is $( eval(ex) )") # => ex is 8