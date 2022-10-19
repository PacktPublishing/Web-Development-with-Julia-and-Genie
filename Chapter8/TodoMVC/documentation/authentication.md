# Authentication

We've made great progress so far, developing our todo app and hosting it on the web. However, making our application available on the internet introduces a new problem: how do we keep our data safe? Anybody who knows the URL of our app can access it and can see and modify all of our todos. We need to add some kind of restrictions to our app so that only authorized users can access it. In addition, wouldn't it be nice if we could share our todo app with our friends and family so they could also create their list and keep track of their own todos, without mixing theirs with ours -- making our app _multi-user_?

The solution to these problems is to add an authentication layer to our app. The authentication will ensure that only authorized users can see and modify specific todo items. In other words, before allowing users to create or edit todo items, we will ask them to authenticate, by requiring them to login in using their username and password. If they are new to the website they will be asked to register. Once they are registered, they will be able to use their credentials (username and password) to log in. In addition, to ensure data privacy -- allowing only the user that created the todos to see and modify them -- we will also make sure that each todo item is associated with a specific user.

## Adding Authentication to our App

The easiest way to add authentication to a Genie app is to use the GenieAuthentication plugin. Let's add it and follow the **installation** instructions (<https://github.com/GenieFramework/GenieAuthentication.jl>) to set up our app for authentication.

In a terminal start the Genie REPL for the TodoMVC app: go to the application folder and run `bin/repl` if you are on Linux or Mac,
or `bin\repl.bat` if you are on Windows. Then, in the REPL, type `]` to enter the Pkg mode and add the GenieAuthentication plugin:

```julia
pkg> add GenieAuthentication
```

Once the plugin is installed, we need to configure it:

```julia
julia> using GenieAuthentication
julia> GenieAuthentication.install(@__DIR__)
```

By running the `install` function, the plugin has added all the necessary integrations into our app (views, controller, model,
migrations, etc). You can see all the operations performed by the `install` function by looking at output in the REPL.

### Configuring the GenieAuthentication plugin

Now that the plugin is installed, let's configure it to our needs. First, we said that we want to allow users to register, so
let's enable this functionality. Registration is disabled by default as a security precaution, to make sure that we don't
accidentally allow unwanted registrations on our app. To enable user registration we need to edit the newly created `genie_authentication.jl`
file in the `plugins/` folder (this was one of the files created by the `GenieAuthentication.install` function). Open the file and uncomment the
two routes at the bottom of the file:

```julia
# UNCOMMENT TO ENABLE REGISTRATION ROUTES

route("/register", AuthenticationController.show_register, named = :show_register)
route("/register", AuthenticationController.register, method = POST, named = :register)
```

#### What are the plugins?

In case you are wondering about this `plugins/` folder, it's worth mentioning that this is a special Genie folder. The files
placed inside this folder behave very similarly to the initializer files hosted in the `config/initializers/` folder. The
`plugins/` folder is designed to be used by Genie plugins to add their integration and initialization logic - and the only difference
compared to regular initializers is that the files in the `plugins/` folder are loaded after the initializers so they can
get access to all the features of the Genie app (like say the database connection, logging, etc).

### Setting up the database

The GenieAuthentication plugin stores the user information in the application's database. For this reason we'll need to create
a new table to store the user information. The plugin has created a migration file for us in the `migrations/` folder. Let's
run the migration to create the `users` table. Go back to the Genie app REPL and run:

```julia
julia> using SearchLight
julia> SearchLight.Migration.status()
```

This will show us the status of the migrations. We can see that we have one migration, `create_table_users`, that has not
been run yet. Let's run it:

```julia
julia> SearchLight.Migration.allup()
```

The `Migration.allup` function will run the migrations that have not been run yet. Alternatively, we can run a specific migration by
passing its name to the `Migration.up` function, for example in our case: `SearchLight.Migration.up("CreateTableUsers")`.

Running the migration will create a new table in the database called `users`. The table only includes a minimum set of columns
that are required by the GenieAuthentication plugin: `id`, `username`, `password`, `name` and `email`. If you want to customize
this structure you can edit the migration before running it or you can create and execute additional migrations.

### Restricting access to the app

It's time to give our authentication feature a try. Let's go ahead and restrict access to the list of todo items. To do this
edit the `app/resources/todos/TodosController.jl` file as follows:

1) at the top of the file, under the last `using` statement, add the following:

```julia
using GenieAuthentication
using TodoMVC.AuthenticationController
using TodoMVC
```

2) change the `index` function by adding the `authenticated!()` function call -- this effectively restricts access to the
body of the function to only authenticated users. The updated `index` function should look like this:

```julia
function index()
  authenticated!()

  html(:todos, :index; todos = todos(), count_todos()..., ViewHelper.active)
end
```

That's all we need to do in order to add authentication to our Genie app!

Before testing our app we need to reload it to give Genie the
opportunity to load the plugin. Exit the Genie REPL and start it again -- then start the server with `julia> up()` and open the
application in the browser (<http://localhost:8000>).

### Registering a new user

This time, due to the authentication, we will not be able to see the list of todos. Instead, we will be redirected to the login page because we
are not authenticated. Let's enable the registration functionality to create a new user for us. We have already enabled the registration
routes earlier by uncommenting the routes in the `genie_authentication.jl` plugin. We'll need to do the same for the registration link in the login page. Open the
`app/resources/authentication/views/login.jl` file and uncomment the section at the bottom of the file by deleting the first and
last lines (the ones that say "Uncomment to enable registration"):

```html
<!-- Uncomment to enable registration
<div class="bs-callout bs-callout-primary">
  <p>
    Not registered yet? <a href="$(linkto(:register))">Register</a>
  </p>
</div>
Uncomment to enable registration -->
```

After you delete the two lines and reload the page, at the bottom, under the login form, you should see a link to the registration page.
Clicking on the "Register" link will take us to the registration page, displaying a form that allows us to create a new account.
Let's fill it up with some data and create a new user. Upon successful registration, by default, we will get a message saying
"Registration successful". Let's improve on this by redirecting the user to their todo list instead. Edit the
`app/resources/authentication/AuthenticationController.jl` file and change the `register` function. Look for the line that says
"Redirect successful" and replace it with `redirect("/?success=Registration successful")`.

Let's try out the new flow by navigating back to the registration page <http://localhost:8000/register> and creating a new user.
This time, after the successful registration the user will be automatically logged in and will be taken to the todo list page,
with the app displaying a success message, while notifying that the registration was successful.

If you want, you can also try an invalid registration, for example by reusing the same username or by leaving some of the fields
empty. You will see that the plugin will automatically guard against such attempts, blocking the invalid registration and displaying
a default error message, indicating the problematic field. As a useful exercise, you can further improve the registration
experience by customizing the error message.

Note: as we haven't added a "logoff" button yet, you can logoff by navigating to <http://localhost:8000/logout>.

### Restricting access to the data

Our app is now protected by authentication, but we still need to make sure that the user can only see their own todo items. To
do this we need to modify our app so that for each todo item we also store the user id that created the todo, effectively
associating each todo item with a user. Once we have that we'll need to further modify our code to only retrieve the todo items
that belong to the currently logged in user.

#### Adding the user id to the todo items

In order to associate each todo item with a user we need to add a new column to the `todos` table. This means we'll need to create
a new migration. Let's do that by running the following command in the Genie REPL:

```julia
julia> using SearchLight
julia> SearchLight.Migration.new("add column user_id to todos")
```

This will create a new migration `AddColumnUserIdToTodos` -- let's edit it to put in our logic. In the `db/migrations/` folder
open the file that ends in `add_column_user_id_to_todos.jl` and make it look like this:

```julia
module AddColumnUserIdToTodos

import SearchLight.Migrations: add_columns, remove_columns, add_index, remove_index

function up()
  add_columns(:todos, [
    :user_id => :int
  ])

  add_index(:todos, :user_id)
end

function down()
  remove_index(:todos, :user_id)

  remove_columns(:todos, [
    :user_id
  ])
end

end
```

The migration syntax should be familiar to you by now. We are adding a new column called `user_id` to the `todos` table and
a new index on that column (this is a good practice to improve the performance of queries given that we will filter the todos
by the data in this column). The `down` function will undo the changes made by the `up` function, by first removing the index and
then dropping the column. Let's run our migration:

```julia
julia> SearchLight.Migration.up()
```

##### Modifying the Todo model

Now that we have the new column in the database we need to modify the `Todo` model to include it. Open the `app/resources/todos/Todos.jl` file
and change the model definition to look like this:

```julia
@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
  todo::String = ""
  completed::Bool = false
  user_id::DbId = DbId()
end
```

We have added a new field called `user_id` of type `DbId` which will be used to reference the id of the user that created the todo.

**Important**: Julia requires a restart when definitions of `struct`s are changed. Exit the Genie REPL and start it again, otherwise
the application will not work correctly from this point on.

Now that we have added the column to store the user id of the owner of the todo item let's update our existing todo items to
set their `user_id` to the id of our user. This is the id of the user that we just created during the registration process. If
you want to check what users are in the database run the following at the Genie app REPL:

```julia
julia> using TodoMVC.Users
julia> all(User)
```

You will get a list of all users in the database. In my case, it looks like this:

```julia
2-element Vector{User}:
 User
| KEY              | VALUE                                                            |
|------------------|------------------------------------------------------------------|
| email::String    | adrian@geniecloud.io                                             |
| id::DbId         | 1                                                                |
| name::String     | Adrian                                                           |
| password::String | d74ff0ee8da3b9806b18c877dbf29bbde50b5bd8e4dad7a3a725000feb82e8f1 |
| username::String | adrian                                                           |

 User
| KEY              | VALUE                                                            |
|------------------|------------------------------------------------------------------|
| email::String    | j@j.com                                                          |
| id::DbId         | 2                                                                |
| name::String     | John                                                             |
| password::String | 03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4 |
| username::String | john                                                             |
```

Note: if you haven't created a user for yourself yet, do that now by navigating to <http://localhost:8000/register>.

Let's check the `id` of our user -- that is, the user that will be associated with the todo items we previously created. In my case,
the id is `1`. Now let's update the existing todo items to set their `user_id` to `1` (or whatever id has the user you want to use).
Run the following at the Genie app REPL:

```julia
julia> for t in all(Todo)
          t.user_id = 1
          save!(t)
       end
```

Now all our existing todos are associated with the id of the user. But we've got two more things left to make our app multi-user:
first, filter the todos by the user id of the authenticated user when retrieving them; and second, make sure that the user id is set when creating a new todo item.

##### Getting information about the authenticated user

So far so good, adding a `user_id` manually was not hard. But how do we get the `user_id` of the authenticated user? As it turns
out, this information is readily available through the same `GenieAuthentication` plugin. If you check the
`plugins/genie_authentication.jl` file, you will see that it exports only two names: `current_user()` and `current_user_id()`. The first one returns the `User`
instance corresponding to the currently authenticated user, and the second one returns just the id of that user (as an `Int`).
If the a user is not authenticated, both functions return `nothing`. We'll use the `current_user_id()` function to filter
the todos by the user id of the authenticated user. And as these functions are exported by the plugin, they are included directly
and exposed by our application's main module, `TodoMVC`. So we need to make sure that we add `using TodoMVC` to the top of the
`app/resources/todos/TodosController.jl` -- as well as inside the `API.V1` submodule.

##### Filtering the todos by user id

Let's continue by updating our application logic to filter the todos by the user id of the authenticated user.
Open the `app/resources/todos/TodosController.jl` file and make the following changes:

1) in the `count_todos` function, we add a new filter -- `user_id = current_user_id()` -- to the `count` function to only
count the todos that belong to the authenticated user:

```julia
function count_todos()
  notdonetodos = count(Todo, completed = false, user_id = current_user_id())
  donetodos = count(Todo, completed = true, user_id = current_user_id())

  (
    notdonetodos = notdonetodos,
    donetodos = donetodos,
    alltodos = notdonetodos + donetodos
  )
end
```

2) in the `todos` function, we add the same filter to all the `find` calls:

```julia
function todos()
  todos = if params(:filter, "") == "done"
    find(Todo, completed = true, user_id = current_user_id())
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false, user_id = current_user_id())
  else
    find(Todo;  limit = params(:limit, SearchLight.SQLLimit_ALL) |> SQLLimit,
                offset = (parse(Int, params(:page, "1"))-1) * parse(Int, params(:limit, "0")),
                user_id = current_user_id())
  end
end
```

3) then we apply the same logic to the `toggle`, `update` and `delete` functions:

```julia
function toggle()
  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.completed = ! todo.completed

  save(todo) && json(todo)
end

function update()
  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.todo = replace(jsonpayload("todo"), "<br>"=>"")

  save(todo) && json(todo)
end

function delete()
  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  SearchLight.delete(todo)

  json(Dict(:id => (:value => params(:id))))
end
```

4) Next, we need to update our API module, modifying the relevant functions in the `TodosController.jl` file, within the
`API.V1` module, by adding the same `user_id` filter, as follows:

```julia
function item()
  todo = findone(Todo, id = params(:id), user_id = current_user_id())
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  todo |> json
end

function update()
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
```

5) We also need to bring the authentication features into the scope of the `API.V1` submodule, by adding the following using
statements at the top of the `API.V1` module:

```julia
using GenieAuthentication
using TodoMVC.AuthenticationController
using TodoMVC
```

##### Setting the user id when creating a new todo item

Now that we retrieve the todos by the user id of the authenticated user, we need to make sure that the user id is set when creating
a new todo item. In the same file, `app/resources/todos/TodosController.jl`, update the `create` function to set the `user_id`:

```julia
function create()
  todo = Todo(todo = params(:todo), user_id = current_user_id())

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
```

Then, in the `API.V1` module, in the same controller file file, update the `create` function to set the `user_id`:

```julia
function create()
  payload = try
    check_payload()
  catch ex
    return json(ex)
  end

  todo = Todo(todo = get(payload, "todo", ""), completed = get(payload, "completed", false), user_id = current_user_id())

  persist(todo)
end
```

##### Enhancing the validation rules

One last thing: remember that the `current_user_id()` function returns `nothing` if the user is not authenticated? This is
a valid value for the `user_id` filed, allowing us to create todo items without being authenticated. This is not what we want,
so we need to add a validation rule to the `Todo` model, to make sure that the `user_id` is not `nothing` when creating a new
todo item.

We need to create a new validation rule in the `app/resources/todos/TodosValidator.jl` file. We will call it `dbid_is_not_nothing`.
Add the following code at the bottom of the module, _inside_ the module, right under the `is_unique` function body:

```julia
function dbid_is_not_nothing(field::Symbol, m::T)::ValidationResult where {T<:AbstractModel}
  isa(getfield(m, field), SearchLight.DbId) && isa(getfield(m, field).value, Nothing) && return ValidationResult(invalid, :DbId_is_not_nothing, "should not be nothing")

  ValidationResult(valid)
end
```

The rule will retrieve the indicated field from the model and if it's of type `SearchLight.DbId` it will make sure that its `value`
property in not `nothing`. If it is, it will return an `invalid` validation result, producing an exception -- otherwise it will return a `valid` result.

To enable the validation rule, in the `app/resources/todos/Todos.jl` file update the model validator logic by replacing it with the following code:

```julia
SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
  ValidationRule(:user_id, TodosValidator.dbid_is_not_nothing)
])
```

We have added a new validation rule, `dbid_is_not_nothing`, which will ensure that the `user_id` can not be left unset upon saving a todo item.

#### Securing all the public facing pages

Now that we've made sure that authentication works as expected, by creating a new user and logging in, and by extending the
application to support multiple users, we need to make sure that all the public facing pages are secured as well. We have already
secured the `TodosController.index` function by calling the `authenticated!` function, but there are other pages that are not yet secured.
We need to make sure that we protect both pages accessible over `GET` and `POST` -- even if a page is not directly linked
from our app, a malicious user can see what other URLs our app exposes and can try to access them directly to expose and
corrupt our data.

As such, besides the `TodosController.index` function, we need to secure the following functions in the `TodosController`, by adding
the `authenticated!` function call at the top of each function, exactly like we did for the `index` function. For instance,
for the `TodosController.create` function, the updated code will look like this:

```julia
function create()
  authenticated!()      # <----- we have added this line, the rest is unchanged

  todo = Todo(todo = params(:todo), user_id = current_user_id())

  # rest of the function is unchanged
end
```

Apply the same logic to the following functions: `TodosController.toggle`, `TodosController.delete`, and `TodosController.update`.

##### Securing the API

This should take care of the application's public facing pages. However, we also need to make sure that the API is secured as well.
Remember that a chain is as strong as its weakest link, and if we don't secure the API, we are leaving a door open for malicious users.

We can just go ahead and apply the same logic as we did for the public facing pages, by adding the `authenticated!` function call to
all our public facing API functions. This would work, but it's not idea. The problem is that by default, the `authenticated!` function
is optimized to support integration with web pages. What this means is that it will redirect the user to the login page if they are not
authenticated. This is not what we want for the API, as we want to return a JSON response instead (a redirect response is not valid JSON).

Exactly for this use case, `GenieAuthentication` allows us to specify a custom response to be returned when the user is not authenticated.
All we need to do is to create a new JSON response and send it to the unauthenticated users. Add the following code to the
`TodosController.API.V1` module, inside the `TodosController.jl` file, for example right after the `using` statements:

```julia
using Genie.Exceptions
const NOT_AUTHORISED_ERROR = ExceptionalResponse(401, ["Content-Type" => "application/json"], "Not authorised")
```

With this code we have created a new `ExceptionalResponse` object, which is a type of error response. We will use it
to return a `401` unauthorised response to unauthenticated users, by passing it to the `authenticated!` function. For instance,
to secure the `TodosController.API.V1.list` function, we will update the function body to look like this:

```julia
function list()
  authenticated!(NOT_AUTHORISED_ERROR)

  TodosController.todos() |> json
end
```

That's all there is to it! When attempting to access our API endpoint, unauthenticated users will now receive a `401` response,
with a JSON body containing the message "Not authorised".

Repeat the same logic for all the publicly accessible API functions, by adding the `authenticated!(NOT_AUTHORISED_ERROR)` function call at the top of each
of the following functions: `TodosController.API.V1.item`, `TodosController.API.V1.persist`, `TodosController.API.V1.create`,
`TodosController.API.V1.update`, and `TodosController.API.V1.delete`.

### Updating our tests

Excellent, our application is now protected against unauthorized access. However, we need to make sure that our tests are updated as well.
Because if we run our test suite now, we will see that all the tests are failing, because they are also unable to access
authentication protected pages and API endpoints. So we need to allow our tests to authenticate as well.

#### Enabling basic authentication

This raises the question of how we can authenticate our tests -- and non-human users in general. We want to allow automations and scripts,
like our tests, to access specific user data without having to go through the login process. There are a few methods for authenticating
non-human users, and one of the most common one -- and the simplest one -- is to use the so-called `Basic Authentication`.
This is a standard HTTP authentication method, which allows us to restrict access to our server using the HTTP "Basic" schema.

Put it very simply, the `Basic` schema allows us to send a username and password in the HTTP request header. The header has a
standard format: the key is `Authorization`, and the value is `Basic <base64 encoded username:password>`. That is, under the
`Authorization` key, we send the `Basic` schema, followed by a space, followed by the `base64` encoded username and password, separated by a colon.
(You can read more about the HTTP "Basic" schema at <https://developer.mozilla.org/en-US/docs/Web/HTTP/Authentication>).

In order to enable basic authentication, we need to integrate the dedicated `GenieAuthentication` features into our app. Add the following
at the bottom of the `genie_authentication.jl` file:

```julia
# basic auth
basicauth(req, res, params) = begin
  if GenieAuthentication.isbasicauthrequest(params)
    try
      user = findone(Users.User, username = params[:username], password = Users.hash_password(params[:password]))
      user === nothing && return req, res, params
      login(user, authenticate(user.id, GenieAuthentication.GenieSession.session(params)))
    catch _
    end
  end

  req, res, params
end
basicauth in Genie.Router.pre_match_hooks || push!(Genie.Router.pre_match_hooks, basicauth)
```

##### Genie hooks

The above snippet uses a Genie hook to enable basic authentication. Hooks are a powerful feature of Genie that is common to
many frameworks. They allow us to run custom code at specific points in the request lifecycle. That is, we can register functions
that will be automatically invoked by Genie when certain events occur. In this case we register a `pre_match_hook` with the Genie router.
Pre-match hooks are functions that are invoked before Genie matches the request to a route. This hook is triggered very early in the
request-response lifecycle, and it allows us to modify the request and response objects, as well as the request parameters. Router hooks
functions are expected to accept three arguments: the request, the response, and the request parameters. And the function is expected to return
the same 3 arguments, optionally modifying them.

In our code we have registered the `basicauth` function as a pre-match hook. The function checks if the request is a basic authentication request,
by looking for the `Authorization` header. If the request is a basic authentication request, the function attempts to find a user with the given
username and password. If a user is found, the function logs the user in, and returns modified request, response, and parameters. If no user is found,
the function returns the request, response, and parameters without modifying them.

#### Setting up the authentication flow

Let's configure the `Basic` authentication header for our tests. In the `test/runtests.jl` file, add the following code,
right above the `@testset` block at the bottom of the file:

```julia
using Base64
const DEFAULT_HEADERS = Dict("Authorization" => "Basic $(base64encode("testuser:testpass"))")
```

As mentioned we need to base64 encode the username and password, and we are using the `base64encode` function from the `Base64` module.
Then we simply declare a new constant, `DEFAULT_HEADERS`, which is a dictionary containing the `Authorization` headers key and value.
We're declaring them here as we'll be using them throughout all of our tests.

Remember to also add `Base64` as a dependency to our tests project. Start a Julia session in the `test/` folder, and run the following command:

```julia
julia> ] # enter the package manager
pkg> activate .
(test) pkg> add Base64
```

##### Creating the default test user

For the username and password we're using `testuser` and `testpass`. However, there's a problem: we don't have a user with this username and password.
In addition, remember that the test database is setup before each test run, and is reset after each test suite to ensure that
no preexisting state affects the test, so we need to create the test user dynamically before each test run. Given that we
already use the migrations to create the database tables, we can use the migrations to create the test user as well. Let's
add a new migration. At the Julia/Genie app repl, run the following command:

```julia
julia> using SearchLight
julia> SearchLight.Migration.new("create default user")
```

This will create a new migration file in the `migrations` folder. Open the file and add the following code:

```julia
module CreateDefaultUser

using Genie
using SearchLight
using ..Main.TodoMVC.Users

function up()
  Genie.Configuration.istest() || return

  Users.User( username  = "testuser",
              password  = "testpass" |> Users.hash_password,
              name      = "Test user",
              email     = "testuser@test.test") |> save!
end

function down()
  Genie.Configuration.istest() || return

  findone(Users.User, username = "testuser") |> delete
end

end
```

In the `up` function we create a new user with the username and password we want to use for our tests. We then save the user to the database.
In the `down` function we delete the user from the database. Notice that, since we only want to run these functions when we are in test mode,
we check for the current environment using the `Genie.Configuration.istest()` function. This function returns `true` if the current environment
is `test`, and `false` otherwise. If we're not in test mode, we simply return from the functions without running the actual migration code.

This migration however, introduces an interesting problem. It needs to have access to application logic, like our `User` model. This means that
it can only be run after the application is fully loaded. However, remember that in our app we run the migrations in the `searchlight.jl` initializer.
Initializers are run before the app resources are loaded, including the models. As such, this migration will crash our app upon startup.
To address this, again, we will resort to Genie hooks. We need to replace the following snippet in the `searchlight.jl` initializer:

```julia
try
  SearchLight.Migration.init()
catch
end
SearchLight.Migration.allup()
```

with the following:

```julia
push!(Genie.Loader.post_load_hooks, () -> begin
  try
    SearchLight.Migration.init()
  catch
  end
  SearchLight.Migration.allup(context = @__MODULE__)
end)
```

Here, instead of directly running the migrations, we wrap the logic into an anonymous function, and register it as a `Loader` post-load hook.
This hook is invoked by Genie after the app resources are loaded, and it allows us to run code that depends on said resources. We simply
delegate the migration logic to the hook function, to be executed by Genie at the exact right time.

Finally, notice that we also pass a `context` value to the `Migration.allup` function, allowing us to inject the dependencies used by the migration.

##### Wrapping up the tests

Now that we have configured the Basic authentication for our app and API, and we have created the test user, we can finally update our tests.
Updating the tests needs to cover the following areas:

1) set up and tear down the test database before and after each test suite, passing in the `context` value to inject the app's dependencies.
2) add the `Authorization` header to all the requests, so that the requests are authenticated.
3) alter all the creation/persistence code for todo items to make sure that the `user_id` value is set to the id of the test user.

Let's proceed. Starting with the `test/todos_test.jl` file, modify the existing `@testset "Todo is correctly initialized"` and
`@testset "Todo is valid"` blocks:

```julia
  @testset "Todo is correctly initialized" begin
    @test t.todo == ""
    @test t.completed == false
    @test t.user_id.value == nothing # <------------------- add this line
  end
  ```

  ```julia
  @testset "Todo is valid" begin
      t.todo = "Buy milk"
      t.user_id = 1  # <------------------- add this line
      v = validate(t)

      # rest of the code the same
    end
```

As for the `test/todos_API_test.jl`, the `test/todos_db_test.jl` and the `test/todos_integration_test.jl` files, I'll just include them in
full as the changes are small and numerous:

---> include the files in full?