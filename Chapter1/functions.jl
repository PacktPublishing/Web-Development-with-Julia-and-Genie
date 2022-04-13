increase_priority!(todo) = todo.priority += 1 
todo1.priority	          # 5
increase_priority!(todo1) # 6 
todo1.priority            # 6

increase_priority!("does this work?") 
# ERROR: type String has no field priority 

# Stacktrace: 
# [1] getproperty 
# @ .\Base.jl:42 [inlined] 
# [2] increase_priority!(todo::String) 
# @ Main .\REPL[55]:2 
# [3] top-level scope 
# @ REPL[56]:1 