(pwd() != @__DIR__) && cd(@__DIR__) # allow starting app from bin/ dir

using TodoMVC
const UserApp = TodoMVC
TodoMVC.main()
