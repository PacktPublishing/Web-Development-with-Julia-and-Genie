module TodosController

using TodoMVC.Todos
using TodoMVC.ViewHelper
using Genie.Router
# using Genie.Renderers
using Genie.Renderers.Html
using Genie.Renderers.Json
using Genie.Requests
using SearchLight
using SearchLight.Validation

function index()
  notdonetodos = count(Todo, completed = false)
  donetodos = count(Todo, completed = true)
  alltodos = notdonetodos + donetodos

  todos = if params(:filter, "") == "done"
    find(Todo, completed = true)
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false)
  else
    all(Todo)
  end

  html(:todos, :index; todos, notdonetodos, donetodos, alltodos, ViewHelper.active)
end

function create()
  todo = Todo(todo = params(:todo))

  validator = validate(todo) 
  if haserrors(validator) 
    return redirect("/?error=$(errors_to_string(validator))")
  end

  if save(todo)
    redirect("/?success=Todo created")
  else
    redirect("/?error=Could not save todo&todo=$(params(:todo))")
  end
end

function toggle()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.completed = ! todo.completed

  save(todo) && json(:todo => todo)
end

function update()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.todo = replace(jsonpayload("todo"), "<br>"=>"")

  save(todo) && json(todo)
end

function delete()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  SearchLight.delete(todo)

  json(Dict(:id => (:value => params(:id))))
end

end
