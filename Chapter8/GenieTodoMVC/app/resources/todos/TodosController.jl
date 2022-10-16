module TodosController

using TodoMVC.Todos
using Genie.Renderers.Html
using Genie.Router
using SearchLight
using SearchLight.Validation
using Genie.Renderers.Json
using Genie.Requests
using TodoMVC.ViewHelper

using GenieAuthentication
using TodoMVC.AuthenticationController
using TodoMVC

const TODOS_PER_PAGE = 20
const PAGINATION_DISPLAY_INTERVAL = 5
const MAX_PAGINATION_WIDTH = 30

function count_todos()
  notdonetodos = count(Todo, completed = false, user_id = current_user_id())
  donetodos = count(Todo, completed = true, user_id = current_user_id())

  (
    notdonetodos = notdonetodos,
    donetodos = donetodos,
    alltodos = notdonetodos + donetodos
  )
end

page() = parse(Int, params(:page, "1"))
categories() = vcat(SearchLight.query("SELECT DISTINCT category from todos ORDER by category ASC")[!,:category], Todos.CATEGORIES) |> unique! |> sort!

function count_pages()
  total_pages = count(Todo, user_id = current_user_id()) / TODOS_PER_PAGE |> ceil |> Int
  current_page = page()
  prev_page = current_page - 1
  next_page = current_page < total_pages ? current_page + 1 : 0

  (
    total_pages = total_pages,
    current_page = current_page,
    prev_page = prev_page,
    next_page = next_page
  )
end

function todos()
  todos = if params(:filter, "") == "done"
    find(Todo, completed = true, user_id = current_user_id())
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false, user_id = current_user_id())
  else
    find(Todo;  limit = TODOS_PER_PAGE |> SQLLimit,
                offset = (page() - 1) * TODOS_PER_PAGE,
                user_id = current_user_id(),
                order = "date DESC")
  end
end

function index()
  authenticated!()

  html(:todos, :index; todos = todos(), count_todos()..., count_pages()..., ViewHelper.active, MAX_PAGINATION_WIDTH, PAGINATION_DISPLAY_INTERVAL, categories = categories())
end

function create()
  authenticated!()

  todo = Todo(todo = params(:todo), category = params(:category), duration = params(:duration), user_id = current_user_id())

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
  authenticated!()

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.completed = ! todo.completed

  save(todo) && json(todo)
end

function update()
  authenticated!()

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.todo = replace(jsonpayload("todo"), "<br>"=>"")

  save(todo) && json(todo)
end

function delete()
  authenticated!()

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  SearchLight.delete(todo)

  json(Dict(:id => (:value => params(:id))))
end

### API

module API
module V1

using TodoMVC.Todos
using Genie.Router
using Genie.Renderers.Json
using ....TodosController
using Genie.Requests
using SearchLight
using SearchLight.Validation

using GenieAuthentication
using TodoMVC.AuthenticationController
using TodoMVC

using Genie.Exceptions
const NOT_AUTHORISED_ERROR = ExceptionalResponse(401, ["Content-Type" => "application/json"], "Not authorised")

function list()
  authenticated!(NOT_AUTHORISED_ERROR)

  TodosController.todos() |> json
end

function item()
  authenticated!(NOT_AUTHORISED_ERROR)

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  todo |> json
end

function check_payload(payload = Requests.jsonpayload())
  isnothing(payload) && throw(JSONException(status = BAD_REQUEST, message = "Invalid JSON message received"))

  payload
end

function persist(todo)
  authenticated!(NOT_AUTHORISED_ERROR)

  validator = validate(todo)
  if haserrors(validator)
    return JSONException(status = BAD_REQUEST, message = errors_to_string(validator)) |> json
  end

  try
    if ispersisted(todo)
      save!(todo)
      json(todo, status = OK)
    else
      save!(todo)
      json(todo, status = CREATED, headers = Dict("Location" => "/api/v1/todos/$(todo.id)"))
    end
  catch ex
    JSONException(status = INTERNAL_ERROR, message = string(ex)) |> json
  end
end

function create()
  authenticated!(NOT_AUTHORISED_ERROR)

  payload = try
    check_payload()
  catch ex
    return json(ex)
  end

  todo = Todo(todo = get(payload, "todo", ""), completed = get(payload, "completed", false), user_id = current_user_id())

  persist(todo)
end

function update()
  authenticated!(NOT_AUTHORISED_ERROR)

  payload = try
    check_payload()
  catch ex
    return json(ex)
  end

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  todo.todo = get(payload, "todo", todo.todo)
  todo.completed = get(payload, "completed", todo.completed)

  persist(todo)
end

function delete()
  authenticated!(NOT_AUTHORISED_ERROR)

  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  try
    SearchLight.delete(todo) |> json
  catch ex
    JSONException(status = INTERNAL_ERROR, message = string(ex)) |> json
  end
end

end # V1
end # API


end
