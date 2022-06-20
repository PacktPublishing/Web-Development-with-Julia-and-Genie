using Genie
using TodoMVC.TodosController

route("/", TodosController.index)
route("/todos", TodosController.create, method = POST)
route("/todos/:id::Int/toggle", TodosController.toggle, method = POST)
route("/todos/:id::Int/update", TodosController.update, method = POST)
route("/todos/:id::Int/delete", TodosController.delete, method = POST)