# Wrapping up

## Final touches

Our todo app is complete. However, we can make it even better by adding a few more features.

### Adding pagination to the todos list

If we go back to the todos list, we can see that now we have a lot of data. It's getting hard to navigate through the list. Let's add pagination
to make the data more manageable.

First, let's compute the pagination data, calculating the total number of pages and the logic for the previous and next buttons. In the
`TodosController.jl` file add:

```julia
const TODOS_PER_PAGE = 20
const PAGINATION_DISPLAY_INTERVAL = 5
const MAX_PAGINATION_WIDTH = 30

page() = parse(Int, params(:page, "1"))

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
```

Then, in the `todos()` function we need to update the logic to take into account the pagination:

```julia
function todos()
  todos = if params(:filter, "") == "done"
    find(Todo, completed = true, user_id = current_user_id())
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false, user_id = current_user_id())
  else
    # this is updated to take into account the pagination
    find(Todo;  limit = TODOS_PER_PAGE |> SQLLimit,
                offset = (page() - 1) * TODOS_PER_PAGE,
                user_id = current_user_id(),
                order = "date DESC")
  end
end
```

Next, for the pagination UI. Create a new view partial in `app/resources/todos/views/_pagination.jl.html` and add the following code:

```julia
<nav>
  <ul class="pagination pagination-sm" style="justify-content: center;">
    <% iif(prev_page > 0) do %>
      <li class="page-item"><a class="page-link" href="/?page=$prev_page">Previous</a></li>
    <% end %>
    <% iif(total_pages > MAX_PAGINATION_WIDTH && current_page > PAGINATION_DISPLAY_INTERVAL) do ;[ %>
      <li class="page-item"><a class="page-link" href="/?page=1">1</a></li>
      <li class="page-item"><a class="page-link">...</a></li>
    <% ]; end %>
    <% for_each(1:total_pages) do page %>
      <% iif(page > (current_page - PAGINATION_DISPLAY_INTERVAL) && page < (current_page + PAGINATION_DISPLAY_INTERVAL)) do %>
        <li class="page-item">
          <% if page == current_page %>
            <a class="page-link bg-dark text-info">$page</a>
          <% else %>
            <a class="page-link" href="/?page=$page">$page</a>
          <% end %>
        </li>
      <% end %>
    <% end %>
    <% iif(total_pages > MAX_PAGINATION_WIDTH && current_page < (total_pages - PAGINATION_DISPLAY_INTERVAL)) do ;[ %>
      <li class="page-item"><a class="page-link">...</a></li>
      <li class="page-item"><a class="page-link" href="/?page=$total_pages">$total_pages</a></li>
    <% ]; end %>
    <% iif(next_page > 0) do %>
      <li class="page-item"><a class="page-link" href="/?page=$next_page">Next</a></li>
    <% end %>
  </ul>
</nav>
```

This is quite dense as the pagination includes a lot of logic. Let's break it down:

* If we're not on the first page, we show a "Previous" button.
* If there are lots of pages we replace some of the buttons with `...`, between the first page and our current page
* Then we show the buttons around our current page, and mark the current page with a different color.
* Next, if there are lots of pages between our current page and the last page, we replace some of the buttons with `...` and show the last page
* Finally, if we're not on the last page, we show a "Next" button.

### Updating the todo item creation

Another thing we need to take into account is that we have added extra properties to our todo items (category, date, and duration).
However, we haven't provided a way for our users to set these properties when creating a new todo item. Let's do it now.

Start by editing the view partial in `app/resources/todos/views/_form.jl.html` and make it look like this:

```julia
<div class="row">
  <form method="POST" action="/todos" class="form-floating">
    <div class="input-group mb-3">
      <input type="text" class="form-control" placeholder="Add a new todo" name="todo" value='$(params(:todo, ""))' />
      <input class="form-control" list="categories_list" name="category" placeholder="Todo category" value='$(params(:category, ""))' />
      <datalist id="categories_list">
        <% for_each(categories) do category %>
          <option value="$category" />
        <% end %>
      </datalist>
      <input type="number" class="form-control" placeholder="Duration in minutes" name="duration" value='$(params(:duration, ""))' min="5" max="240" step="5" />
      <input type="submit" class="btn btn-outline-secondary" value="Add" />
    </div>
  </form>
</div>
```

We have added a number of fields to the form:

* A text field for the category, with a list of existing categories to choose from. The data for the `datalist` is provided by a `categories` variable that we'll need to pass into the view.
* A number field for the duration, with a minimum of 5 minutes, a maximum of 240 minutes, and a step of 5 minutes.
* A date field for the date, with the current date as the default value.

In the `TodosController` we need to update the `create()` function to take into account the new fields:

```julia
function create()
  authenticated!()

  # we add the new values here
  todo = Todo(todo = params(:todo), category = params(:category), duration = params(:duration), user_id = current_user_id())

  # rest of the code is the same
end
```

We also need to add the logic to get the list of categories used on the frontend -- add this function to the `TodosController`:

```julia
categories() = vcat(SearchLight.query("SELECT DISTINCT category from todos ORDER by category ASC")[!,:category], Todos.CATEGORIES) |> unique! |> sort!
```

Finally, the `index()` function also needs to be updated to pass the pagination and the categories data to the view:

```julia
function index()
  authenticated!()

  html(:todos, :index; todos = todos(), count_todos()..., count_pages()..., ViewHelper.active, MAX_PAGINATION_WIDTH, PAGINATION_DISPLAY_INTERVAL, categories = categories())
end
```

### Adding navigation

We have a lot of pages now, and it's getting a bit hard to navigate between them. Let's add a navigation bar to the top of the page.

Start by editing the view partial in `app/layouts/_main_menu.jl.html` and make it look like this:

```julia
<nav class="navbar navbar-expand-lg navbar-light" style="background-color: #e3f2fd;">
  <div class="container-fluid">
    <a class="navbar-brand" href="#">Genie Todo MVC</a>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarSupportedContent">
      <span class="navbar-toggler-icon"></span>
    </button>
    <div class="collapse navbar-collapse" id="navbarSupportedContent">
      <ul class="navbar-nav me-auto mb-2 mb-lg-0">
        <li class="nav-item">
          <a class="nav-link" href="/">Todos</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="/dashboard">Dashboard</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" href="/logout">Logout</a>
        </li>
      </ul>
    </div>
  </div>
</nav>
```

This is a simple navigation bar with three links: "Todos", "Dashboard", and "Logout". We added it to the `layouts/` folder because we want it to be available on all pages.
So let's include the partial into the app's layout. Update the `<body>...</body>` part of the `app/layouts/app.jl.html` file to look like this:

```julia
... more code here ...
<body>
  <div class="container-fluid">
    <% partial("app/layouts/_main_menu.jl.html") %>
    <div class="container">
      <h1>What needs to be done?</h1>
      <%
        @yield
      %>
    </div>
  </div>
  <script src="https://unpkg.com/axios/dist/axios.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/cash-dom@8.1.1/dist/cash.min.js"></script>
  <script src="/js/app.js"></script>
</body>
... rest of the code here ...
```

### Updating the todos list

Now that we have prepared all the logic and thew views for the pagination and the updated todo item creation, let's update the todo's view to use them.
Edit the view file in `app/resources/todos/views/index.jl.html` and make it look like this:

```julia
<% partial("app/resources/todos/views/_messages.jl.html") %>
<% partial("app/resources/todos/views/_form.jl.html") %>
<% partial("app/resources/todos/views/_filters.jl.html") %>
<% if isempty(todos) && params(:filter, "") == "done" %>
    <p>You haven't completed any todos yet.</p>
<% elseif isempty(todos) %>
    <p>Nothing to do!</p>
<% else %>
  <div class="row">
    <div class="col">
      <ul class="list-group">
        <% for_each(todos) do todo %>
          <li class="list-group-item list-group-item-action form-check form-switch">
            <input type="checkbox" checked="$(todo.completed ? true : false)" class="form-check-input" id="todo_$(todo.id)" value="$(todo.id)" />
            <label class='form-check-label $(todo.completed ? "completed" : "")' data-original="$(todo.todo)" data-todo-id="$(todo.id)">$(todo.todo)</label>
            <button class="btn btn-outline-danger invisible" type="button" value="$(todo.id)">Delete</button>
          </li>
        <% end %>
      </ul>
    </div>
  </div>
<% end %>
<% partial("app/resources/todos/views/_pagination.jl.html") %>
```

Nothing complicated here:

* we moved the `_filters.jl.html` partial to the top of the page, so that the user can filter the todos without needing to scroll to the bottom.
* and the bottom of the page is now used by the `_pagination.jl.html` partial, to output the pagination links.

### Redirecting after login

The final tweak we'll make is to redirect the user to the todo list after they log in. Currently we are using the default implementation from
GenieAuthentication, which redirects to the success page. However, this isn't useful for us, so we're better off going straight to the
todo list after login. Update the `AuthenticationController.jl` file, replacing one line in the `login()` function:

```julia
function login()
  try
    user = findone(User, username = params(:username), password = Users.hash_password(params(:password)))
    authenticate(user.id, GenieSession.session(params()))

    # redirect(:success)  <-- replace this
    redirect("/")       # <-- with this
  catch ex
    flash("Authentication failed! ")

    redirect(:show_login)
  end
end
```