# Genie Todo MVC walk through

## Creating a new app

Genie includes various handy generators for bootstrapping new applications. These generators setup the necessary packages and application files in order to streamline the creation of various types of projects, including full stack (MVC) apps and APIs.

As we're creating a MVC app, we'll use the MVC generator.

```julia
julia> using Genie
julia> Genie.Generator.newapp_mvc("TodoMVC")
```

We invoke the `newapp_mvc` generator, passing the name of our new applications. Genie integrates with various database backends through SearchLight, an ORM library that provides a reach API to work with relational DBs. As MVC apps routinely use database backends, the generator gives us the possibility to configure the DB connection now. SearchLight makes it very easy to write code that is portable between the supported backends, so our plan is to use SQLite during development (for ease of configuring) and Postgres or MariaDB in production (for high performance under live online traffic).

```
Please choose the DB backend you want to use:
1. SQLite
2. MySQL
3. PostgreSQL
4. Skip installing DB support at this time

Input 1, 2, 3 or 4 and press ENTER to confirm.
If you are not sure what to pick, choose 1 (SQLite). It is the simplest option to get you started right away.
You can add support for additional databases anytime later.
```

Inputting `1` will install and configure SQLite and the SearchLight SQLite adapter. When ready, Genie will load our newly created app and will start the web server on port 8000:

```

 ██████╗ ███████╗███╗   ██╗██╗███████╗    ███████╗
██╔════╝ ██╔════╝████╗  ██║██║██╔════╝    ██╔════╝
██║  ███╗█████╗  ██╔██╗ ██║██║█████╗      ███████╗
██║   ██║██╔══╝  ██║╚██╗██║██║██╔══╝      ╚════██║
╚██████╔╝███████╗██║ ╚████║██║███████╗    ███████║
 ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚═╝╚══════╝    ╚══════╝

| Website  https://genieframework.com
| GitHub   https://github.com/genieframework
| Docs     https://genieframework.com/docs
| Discord  https://discord.com/invite/9zyZbD6J7H
| Twitter  https://twitter.com/essenciary

Active env: DEV


Ready!

┌ Info:
└ Web Server starting at http://127.0.0.1:8000
```

We can check that everything works by navigating to the indicated url (`http://127.0.0.1:8000`) in the browser. We should see Genie's welcome page.

```

Welcome!
It works! You have successfully created and started your Genie app.
```

## Setting up the database

Because various relational database backends support different features and flavours as SQL, when working with SearchLight we use a set of programming APIs and workflows that ensure that our code that interacts with the database can be ported across the different supported backends. This pattern also covers table creation and modification, which is done via "migration" scripts. Besides being database agnostic, migration scripts provide another very important advantage: they allow versioning and automating/repeating table creation and modification operations, for example between multiple team members or when deploying the app in production.

Before we can use migrations to create our table we need to setup the migrations infrastructure: a table stored in the app's db, where `SearchLight.Migrations` keeps track of the various migration scripts. This is easily done with another generator:

```julia
julia> using SearchLight
julia> SearchLight.Migrations.init()
```

We get the following output:

```
┌ Info: CREATE TABLE `schema_migrations` (
│       `version` varchar(30) NOT NULL DEFAULT '',
│       PRIMARY KEY (`version`)
└     )
[ Info: Created table schema_migrations
```

## Creating our table

Our application will need a database table to store the todos. We'll also need a way to interact with this database table, in order to store, retrieve, update and potentially delete todo items. This is done using "Models", the "M" in the "MVC" stack. SearchLight has a series of generators that allow us to quickly create models and their respective migrations, plus a few other useful files.

```julia
julia> SearchLight.Generator.newresource("Todo")
```

We'll get the following output, informing us that four files have been created.

```
[ Info: New model created at TodoMVC/app/resources/todos/Todos.jl
[ Info: New table migration created at TodoMVC/db/migrations/<timestamp>_create_table_todos.jl
[ Info: New validator created at TodoMVC/app/resources/todos/TodosValidator.jl
[ Info: New unit test created at TodoMVC/test/todos_test.jl
```

A resource represents a business entity or a piece of data (in our case a todo item) implemented in code through a bundle of files serving various roles. For now we'll focus on the model and the migration - but notice that SearchLight has also created a validator and a test file. We'll get back to these later.

### The migration

As we can see in the output above, the migration file has been created inside the `db/migrations/` folder. The file name ends in `_create_table_todos.jl` and begins with a timestamp of the moment the file was created. The purpose for timestamping the migration file is to reduce the risk of name conflicts when working with a team -- but also to inform SearchLight about the creation and execution order of the migration files.

Let's check out the file. It looks like this:

```julia
module CreateTableTodos

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:todos) do
    [
      pk()
      column(:column_name, :column_type)
      columns([
        :column_name => :column_type
      ])
    ]
  end

  add_index(:todos, :column_name)
  add_indices(:todos, :column_name_1, :column_name_2)
end

function down()
  drop_table(:todos)
end

end
```

SearchLight has added some boilerplate code to get us started - we just need to fill up the placeholders with the names and properties of our table's columns. The Migrations API should be pretty self explanatory, but let's go over it quickly. We have two functions `up` and `down`. In migrations parlance, the `up` function is used to apply the database modification logic. So any changes we want to make, should go into the `up` function. Conversely, the `down` function contains logic for undoing the changes introduced by `up`.

Moving on to the contents of the `up` function, in creates a table called `todos` (`create_table(:todos)`), adds a primary key (`pk()`) and then provides boilerplate for adding a number of columns and indices. The `down` function deletes the table (`drop_table(:todos)`) undoing the effects of `up`.

In the spirit of traditional TodoMVC apps we'll keep it simple and we'll only store the todo item itself (we'll call it `todo`) and we'll store whether or not it's completed (by default not). Let's set up the `up` logic:

```julia
module CreateTableTodos

import SearchLight.Migrations: create_table, column, columns, pk, add_index, drop_table, add_indices

function up()
  create_table(:todos) do
    [
      pk()
      column(:todo, :string)
      column(:completed, :bool; default = false)
    ]
  end

  add_index(:todos, :completed)
end

function down()
  drop_table(:todos)
end

end
```

We're now ready to execute our migration (execute the code within the `up` function). The `SearchLight.Migration` API provides a series of utilities to work with migrations, for instance to keep track of which migrations have been executed, and execute migrations in the correct order. We can check the status of our migrations:

```julia
julia> SearchLight.Migrations.status()
```

Output:

```
[ Info: SELECT version FROM schema_migrations ORDER BY version DESC
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                 CreateTableTodos: DOWN |
| 1 |      <timestamp>_create_table_todos.jl |
```

As expected, our migration is down, meaning that we haven't run the `up` function to apply the changes to the database. Let's do it:

```julia
julia> SearchLight.Migrations.up()
```

We can see all the steps executed by the `up` function:

```
[ Info: SELECT version FROM schema_migrations ORDER BY version DESC
[ Info: CREATE TABLE todos (id INTEGER PRIMARY KEY , todo TEXT  , completed BOOLEAN  DEFAULT false  )
[ Info: CREATE  INDEX todos__idx_completed ON todos (completed)
[ Info: INSERT INTO schema_migrations VALUES ('2022052910095674')
[ Info: Executed migration CreateTableTodos up
```

If we check again we'll see that the migration's status is now `UP`:

```julia
julia> SearchLight.Migrations.status()
```

Output:

```
[ Info: SELECT version FROM schema_migrations ORDER BY version DESC
|   | Module name & status                   |
|   | File name                              |
|---|----------------------------------------|
|   |                   CreateTableTodos: UP |
| 1 | 2022052910095674_create_table_todos.jl |
```

## Setting up the model

Interacting with the Migrations API we have seen the effectiveness of an ORM: writing concise and readable Julia code, SearchLight generates a multitude of SQL queries that are optimised for the configured database backend (in our case SQLite). This idea is taken to its next step by models: the models are even more powerful constructs that allow us to manipulate the _data_ (compared to migrations, which manipulate the tables's _structure_). A model is a Julia struct whose fields (properties) map the table columns that we want to control. By setting up these structs we retrieve data from our database tables -- and by changing the values of their fields, we write data back to the database.

Remember that our model was created in the `app/resources/todos/` folder, under the name `Todos.jl`. Let's open it in our editor.

```julia
module Todos

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Todo

@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
end

end
```

Similar to the migration, SearchLight has set up a good amount of boilerplate to get us started. The model struct is included into a module. Notice that the name of the modules is pluralized, like the name of the table -- while the struct is singular. The table contains multiple _todos_; and each `Todo` struct represents one row in the table, that is, one todo item.

The struct already includes the `id` field corresponding to the primary key. Let's add the other two fields, corresponding to the todo and the completed status. These fields must match the names of the types we declared in the migration.

```julia
module Todos

import SearchLight: AbstractModel, DbId
import Base: @kwdef

export Todo

@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
  todo::String = ""
  completed::Bool = false
end

end
```

Let's give our model a try:

```julia
julia> using Todos
```

We'll ask SearchLight to find all the todos:

```
julia> all(Todo)
```

Output:

```
[ Info: 2022-05-29 12:58:03 SELECT "todos"."id" AS "todos_id", "todos"."todo" AS "todos_todo", "todos"."completed" AS "todos_completed" FROM "todos" ORDER BY todos.id ASC
Todo[]
```

Since we haven't added any todo item we're getting back an empty vector of Todo objects.

Time to create our first todo:

```julia
julia> my_first_todo = Todo()
```

We've just created our first todo item:

```
Todo
| KEY             | VALUE |
|-----------------|-------|
| completed::Bool | false |
| id::DbId        | NULL  |
| todo::String    |       |
```

However, this is empty, so not very useful. We should store something useful in it:

```julia
julia> my_first_todo.todo = "Build the Genie TodoMVC app"
```

Now, to store it, run:

```
julia> save!(my_first_todo)
```

Output:

```
[ Info: INSERT  INTO todos ("todo", "completed") VALUES ('Build the Genie TodoMVC app', false)
[ Info: SELECT CASE WHEN last_insert_rowid() = 0 THEN -1 ELSE last_insert_rowid() END AS LAST_INSERT_ID
[ Info: SELECT "todos"."id" AS "todos_id", "todos"."todo" AS "todos_todo", "todos"."completed" AS "todos_completed" FROM "todos" WHERE "id" = 1 ORDER BY todos.id ASC

Todo
| KEY             | VALUE                       |
|-----------------|-----------------------------|
| completed::Bool | false                       |
| id::DbId        | 1                           |
| todo::String    | Build the Genie TodoMVC app |
```

The `save!` function will persist the todo data to the database, modifying our todo object by setting its `id` field to the row id that was retrieved from the database operation. If the database operation fails, an exception is thrown.

SearchLight is smart and runs the correct queries, depending on context: in this case it generated an `INSERT` query to add a new row -- but when changing an object that already has data loaded from the database, it will generate an `UPDATE` query instead. Let's see it in action.

```julia
julia> save!(my_first_todo)
```

Output

```
[ Info: UPDATE todos SET  "id" = '1', "todo" = 'Finish my first Genie app', "completed" = false WHERE todos.id = '1' ; SELECT 1 AS LAST_INSERT_ID
[ Info: SELECT "todos"."id" AS "todos_id", "todos"."todo" AS "todos_todo", "todos"."completed" AS "todos_completed" FROM "todos" WHERE "id" = 1 ORDER BY todos.id ASC

Todo
| KEY             | VALUE                     |
|-----------------|---------------------------|
| completed::Bool | false                     |
| id::DbId        | 1                         |
| todo::String    | Finish my first Genie app |
```

We are now done setting up the database interaction layer (the Model layer). Next we'll discuss the View and the Controller layers of our Genie Todo MVC application.

## Controller and views

In MVC applications, the views format and display the data (from the model layer) to the user. However, the views do not interact directly with the model layer. Instead, they interact with the controller layer. The controller layer is responsible for handling user input and updating the model data as well. Every time a web request is made to the server, first the controller is invoked, reading and/or modifying the model data. This model data is then passed to the view layer, which formats and displays the data to the user. Let's see this in action in our app.

Genie's generator will create a controller for us:

```julia
julia> Genie.Generator.newcontroller("Todo")
```

The controller file is in the same location as our model, as indicated by the output:

```
[ Info: New controller created at TodoMVC/app/resources/todos/TodosController.jl
```

Let's add logic to display all the todos. We'll start by adding a function (let's call it `index`) that retrieves all the todos from the database and renders them to the user.

```julia
module TodosController

using TodoMVC.Todos
using Genie.Renderers, Genie.Renderers.Html

function index()
  html(:todos, :index; todos = all(Todo))
end

end
```

It's as simple as this: we retrieve all the todo items using the `all` function from SearchLight, and pass them to the `index` view, within the `todos` resource folder.

Time to add a simple view file - create the `app/resources/todos/views` folder and create a `index.jl.html` file:

```julia
julia> mkdir("app/resources/todos/views")
julia> touch("app/resources/todos/views/index.jl.html")
```

Genie supports a variety of languages for views, including pure Julia, Markdown, and HTML with embedded Julia. Our `index.jl.html` file will be written mostly with HTML, and we'll use Julia language constructs (`if`, `for`, etc) and Julia variables interpolation to make the output dynamic.

Now, edit the `index.jl.html` file and add the following code:

```html
<% if isempty(todos) %>
  <p>Nothing to do!</p>
<% else %>
  <ul>
    <% for_each(todos) do todo %>
      <li>
        <input type="checkbox" checked="$(todo.completed ? true : false)" />
        <label>$(todo.todo)</label>
      </li>
    <% end %>
  </ul>
<% end %>
```

In the HTML code above we use a series of Julia language constructs to dynamically generate the HTML. The `if` statement checks if the todos vector is empty, and if so, displays a message to the user. Otherwise, it iterates over the todos vector and displays each todo item. Julia code blocks are delimited by `<% %>` tags, while for outputting values we resort to the `$(...)` syntax for string interpolation. Also notice the use of the `for_each` function - this is a helper provided by Genie to iterate over a collection and automatically concatenate the output of the loop and render it into the view.

We're almost ready to view our todos on the web. But there is one thing missing: we need to register a _route_ - that is, a mapping between a URL that will be requested by the users and the (controller) function that will return the response. Let's add a route to our app. Edit the `routes.jl` file inside the top `TodoMVC` folder and edit it to look like this:

```julia
using Genie
using TodoMVC.TodosController

route("/", TodosController.index)
```

Now we can access our todos at `http://localhost:8000/` - and we should see the one todo item we previously created.

### The layout file

When rendering a view file, by default, it is automatically wrapped by a layout file. The role of the layout is to render generic UI elements that are present on multiple pages, such as the main navigation or the footer. The default layout file is located in the `app/layouts` folder, and it is called `app.jl.html`. Let's use it to style our todos a bit.

Edit the `app.jl.html` file and make it look like this

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Genie Todo MVC</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.2/dist/css/bootstrap.min.css" rel="stylesheet">
  </head>
  <body>
    <div class="container">
      <h1>What needs to be done?</h1>
      <%
        @yield
      %>
    </div>
  </body>
</html>
```

Arguably one of the most important elements of the layout file is the `@yield` macro. This is a special macro that is used to render the content of the view file. In the above example, the `@yield` macro is used to render the content of the `index.jl.html` file.

We have included the `bootstrap` library in our `app.jl.html` file. This library provides a lot of useful styles and components for our todo app and we'll use some of them in our view. We've added a div with the class `container` to make our layout responsive and centered. We also have a `h1` element to display the title of our app.

Next, make sure that the `index.jl.html` file is updated as follows:

```html
<% if isempty(todos) %>
  <p>Nothing to do!</p>
<% else %>
  <div class="row">
    <ul class="list-group">
      <% for_each(todos) do todo %>
        <li class="list-group-item form-check form-switch">
          <input type="checkbox" checked="$(todo.completed ? true : false)" class="form-check-input" id="todo_$(todo.id)"  value="$(todo.id)" />
          <label class="form-check-label" for="todo_$(todo.id)">$(todo.todo)</label>
        </li>
      <% end %>
    </ul>
  </div>
<% end %>
```

Our todo list looks much better already!

### View partials

Genie provides yet another feature for building complex views. View partials are small pieces of code that can be reused in multiple views. Let's add a view partial to our app that contains a form for creating new todos. We'll create this file in the `app/resources/todos/views` folder and name it `_form.jl.html`.

```julia
julia> touch("app/resources/todos/views/_form.jl.html")
```

We can now add the following content to the `_form.jl.html` file:

```html
<div class="row">
  <form method="POST" action="/todos">
    <div class="input-group mb-3">
      <input type="text" class="form-control" placeholder="Add a new todo">
      <input type="submit" class="btn btn-outline-secondary" value="Add">
    </div>
  </form>
</div>
```

We are adding a form with one text input for entering the new todo item and a submit button. In order to include the partial into our view, we'll use the `partial` function. Add the following code at the end of the `index.jl.html` file:

```html
<% partial("app/resources/todos/views/_form.jl.html") %>
```

In order for our form to work as expected, we need to add the corresponding route and the controller function. To add the route, edit the `routes.jl` file and add the following code:

```julia
route("/todos", TodosController.create, method = POST)
```

And for the controller function, edit the `TodosController.jl` file and add the following code:

```julia
using Genie.Router
using SearchLight

function create()
  todo = Todo(todo = params(:todo))

  if save(todo)
    redirect("/?success=Todo created")
  else
    redirect("/?error=Could not save todo&todo=$(params(:todo))")
  end
end
```

In the above code, after adding a few extra `using` statements that give us access to the `redirect` and the `save` methods, we create a new `Todo` object and save it to the database. If the save operation succeeds, we redirect the user to the index page with a success message. Otherwise, we redirect the user to the index page with an error message and the current todo item, to fill up the new todo field with the todo's description.

Let's now add the extra code to the frontend. First, to handle success and error messages in the `index.jl.html` file. Let's add another view partial to handle the messages. Add this on the very first line of `index.jl.html`:

```html
<% partial("app/resources/todos/views/_messages.jl.html") %>
```

Now, create the file with `julia> touch("app/resources/todos/views/_messages.jl.html")` and edit it as follows:

```html
<% if ! isempty(params(:success, "")) %>
  <div class="alert alert-success" role="alert">
    <% params(:success) %>
  </div>
<% elseif ! isempty(params(:error, "")) %>
  <div class="alert alert-danger" role="alert">
    <% params(:error) %>
  </div>
<% else %>
  <br/>
<% end %>
```

In the `_messages.jl.html` partial, we are checking if there is a `:success` parameter in the query string. If there is, we display a success message. Otherwise, we check if there is a `:error` parameter in the query string. If there is, we display an error message. Otherwise, we display nothing.

Finally, in the `_form.jl.html` file, we need to update the input tag to automatically display the todo item that the user entered. Replace the line where the text input tag is defined with the following code (we've added the `value` attribute at the end):

```html
<input type="text" class="form-control" placeholder="Add a new todo" name="todo" value='$(params(:todo, ""))' />
```

Notice that we're using `'` single quotes for the `value` attribute as we're using double quotes inside it.

## Adding validation

So far everything looks great - but, there is a problem. Our application allows users to create new todos, but they can create empty todos -- which is not very useful. We need to add some validation to our application to prevent users from creating empty todos.

Validations are performed by model validators. They represent a collection of validation rules that are applied to a model's data. The `TodosValidator.jl` file should already be included in our application as it was created together with the model. If we open it, we'll see that it already includes a few common validation rules, including a `not_empty` rule.

```julia
function not_empty(field::Symbol, m::T, args::Vararg{Any})::ValidationResult where {T<:AbstractModel}
  isempty(getfield(m, field)) && return ValidationResult(invalid, :not_empty, "should not be empty")

  ValidationResult(valid)
end
```

All we need to do is to update our `Todo` model to declare that the `todo` field should be validated by the `not_empty` rule. Add the following code to the `Todos.jl` model file:

```julia
using SearchLight
using TodoMVC.TodosValidator
import SearchLight.Validation: ModelValidator, ValidationRule

SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
])
```

Now, in the `TodosController.jl` file, we modify the `create` function to enforce validations:

```julia
using SearchLight
using SearchLight.Validation

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
```

Now the application will no longer allow the creation of empty todo items.

## Updating todos

The most satisfying part of having a todo list, is marking the items as completed. As it is right now, the application allows us to toggle the completed status of a todo item, but the change is not persisted to the database. Let's fix this.

First let's add a new route and the associated controller function to allow us to toggle the completed status of our todo items. Add the following code to the `routes.jl` file:

```julia
route("/todos/:id::Int/toggle", TodosController.toggle, method = POST)
```

Notice the `:id::Int` component of the route. This is a dynamic route that will contain the id of the todo item that we want to toggle. Also, the route only matches integer values, making sure that incorrect values can not be passed to the controller function.

Now, for the controller function, edit the `TodosController.jl` file and add the following code:

```julia
using Genie.Renderers.Json

function toggle()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.completed = ! todo.completed

  save(todo) && json(:todo => todo)
end
```

In the `toggle` function we are finding the todo item with the given id. If the todo item is not found, we return an error page. Otherwise, we toggle the completed status of the todo item and save it to the database, before returning the todo's data as json.

### Enhancing our app with custom JavaScript and CSS

The reason for returning a JSON response from the `toggle` function is that we want to update the todo item in the browser without reloading the page, by using JavaScript to make an AJAX request and then consume the response data in JavaScript. The simplest way to achieve this is by returning a JSON response which can be easily parsed by our JS code. The `json` function is a helper function (available in the `Genie.Renderers.Json` module) that will return a JSON response with the given data. Let's see how we can enhance our app with custom JavaScript!

For making the AJAX request we'll use a library called Axios (<https://axios-http.com>). First, we'll load the script from the CDN, by adding this tag to our layout file (`app/layouts/app.jl.html`) right above the closing `</body>` tag:

```html
<script src="https://unpkg.com/axios/dist/axios.min.js"></script>
```

While we're at it, let's also include Cash.js, a very small utility library that makes manipulating the DOM a breeze (<https://github.com/fabiospampinato/cash>). Again, let's load it right above the closing `</body>` tag:

```html
<script src="https://cdn.jsdelivr.net/npm/cash-dom@8.1.1/dist/cash.min.js"></script>
```

We also need to create and include an extra JavaScript file where we will put our own code. Any file that we place inside the `public/` folder, in the root of our app, will be available to include in our HTML views. We'll create a new file called `app.js` in `public/js/` (`julia> touch("public/js/app.js")`) and we'll add it to our layout file (you guessed it, also right before the closing `</body>` tag):

```html
<script src="/js/app.js"></script>
```

Edit the file and put this in:

```js
$(function() {
  $('input[type="checkbox"]').on('change', function() {
    if ( this.checked) {
      $(this).siblings('label').addClass('completed');
    } else {
      $(this).siblings('label').removeClass('completed');
    }
  });
})
```

In addition, we'll add a CSS file to our app (`julia> touch("public/css/app.css")`), right before the closing `</head>` tag in our layout file.

Let's start with the custom CSS, and use it to style our todo items. Add the following code to the `app.css` file:

```html
<link href="/css/app.css" rel="stylesheet" />
```

Then edit the `app.css` file and add the following CSS rules:

```css
.completed {
  text-decoration: line-through;
  color: #d9d9d9;
}
```

Now refresh the page with the todo list and toggle the checkboxes - you should see how the todo items are styled when they are marked as completed. However, the actual state of the todo items is not persisted to the database yet. Add the following code snippet to the `app.js` file to perform a POST request via AJAX to the `/todos/:id/toggle` route and update the todo item's completed status:

```js
$(function() {
  $('input[type="checkbox"]').on('change', function() {
    axios({
      method: 'post',
      url: '/todos/' + $(this).attr('value') + '/toggle',
      data: {}
    })
    .then(function(response) {
      $('#todo_' + response.data.id.value).first().checked = response.data.completed;
    });
  });
});
```

## Updating todo items

Now that we can change the completed status of todo items, we can also allow the users to edit the todo items themselves. We can do this by adding a double click event on our todo items that enable editing mode. Then we capture the `<ENTER>` key to save the changes (while the `<ESC>` key will cancel the changes). Add the following code to the `app.js` file to enable this functionality:

```js
$(function() {
  $('li > label').on('dblclick', function() {
    $(this).attr('contenteditable', true);
  });
  $('li > label').on('keyup', function(event) {
    if (event.keyCode === 13) {
      $(this).removeAttr('contenteditable');
      axios({
        method: 'post',
        url: '/todos/' + $(this).data('todo-id') + '/update',
        data: { todo: $(this).html() }
      })
      .then(function(response) {
        $('label[data-todo-id="' + response.data.id.value + '"]').first().html(response.data.todo);
      });
    } else if (event.keyCode === 27) {
      $(this).removeAttr('contenteditable');
      $(this).text($(this).attr('data-original'));
    }
  });
});
```

In order for the JavaScript code to work, we need to make a modification to our `app/resources/todos/views/index.jl.html` view. Replace the line that adds the `<label>` element with the following:

```html
<label class='form-check-label $(todo.completed ? "completed" : "")' data-original="$(todo.todo)" data-todo-id="$(todo.id)">$(todo.todo)</label>
```

Let's now add a new route and controller function to allow us to update the description of the todo items. Add the following code to the `routes.jl` file:

```julia
route("/todos/:id::Int/update", TodosController.update, method = POST)
```

Then in the `TodosController.jl` file, add the `update` function:

```julia
using Genie.Requests

function update()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  todo.todo = replace(jsonpayload("todo"), "<br>"=>"")

  save(todo) && json(todo)
end
```

You'll notice that the function is very similar to the `toggle` function. The only difference is that we are updating the todo item's description instead of its completed status. The value of the `todo` parameter is the value of the `todo` field in the JSON payload which we access through the aptly named function `jsonpayload` provided by the `Genie.Requests` module. In addition we also do some basic input cleaning, by removing any `<br>` tags from the description.

## Deleting todo items

It can be useful to also allow the users to remove todos, either completed or not. We can do this by adding a delete button to each todo item. Update the `index.jl.html` view to add the following code on the line under the `<label>` tag (above the closing `</li>` tag):

```html
<button class="btn btn-outline-danger invisible" type="button" value="$(todo.id)">Delete</button>
```

Next, add the following code to the `app.js` file:

```js
$(function() {
  $('li').on('mouseenter', function() {
    $(this).children('button').removeClass('invisible');
  });
  $('li').on('mouseleave', function() {
    $(this).children('button').addClass('invisible');
  });
  $('li > button').on('click', function() {
    if ( confirm("Are you sure you want to delete this todo?") ) {
      axios({
        method: 'post',
        url: '/todos/' + $(this).attr('value') + '/delete',
        data: {}
      })
      .then(function(response) {
        $('#todo_' + response.data.id.value).first().parent().remove();
      });
    }
  });
});
```

What have we done so far? We have added a new button to each todo item that allows the user to delete the todo item. The button is invisible by default, but when the user hovers over the todo item, the button becomes visible. When the user clicks the button, a confirmation dialog is displayed. If the user confirms, an AJAX request is sent to the `/todos/:id/delete` route to delete the todo item. The response from the server is then used to remove the todo item from the page.

Now, to add the server side logic. First add the following code to the `routes.jl` file:

```julia
route("/todos/:id::Int/delete", TodosController.delete, method = POST)
```

Then in the `TodosController.jl` file, add the `delete` function:

```julia
function delete()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return Router.error(NOT_FOUND, "Todo item with id $(params(:id))", MIME"text/html")
  end

  SearchLight.delete(todo)

  json(Dict(:id => (:value => params(:id))))
end
```

The `SearchLight.delete` function removes the todo item from the database and returns the modified todo item, setting its `id` value to `nothing` (to indicate that the object is no longer persisted in the database). However, our frontend needs the todo item's `id` value to be returned so that it can be removed from the page. We can accomplish this by returning the todo item's `id` value in the JSON response.

## Aggregate values and filters

The last piece of functionality of our TodoMVC application, is to allow the users to filter the todo items by their status. We can accomplish this by adding a new toolbar with 3 buttons (representing the 3 possible filters for our list: all, completed, and todo). For each of the buttons, we also want to show a count of the actual number of todos that match the filter.

To keep our view code clean and easy to maintain, we'll create a new view partial to host our new UI elements. Add the following code to the `index.jl.html` view, right at the bottom:

```html
<% partial("app/resources/todos/views/_filters.jl.html") %>
```

Now, create the above view partial:

```julia
julia> touch("app/resources/todos/views/_filters.jl.html")
```

Edit the `_filters.jl.html` file and add the following code:

```html
<div class="btn-group" role="group">
  <a class="btn btn-outline-primary $(active())" href="/">
    All <span class="badge bg-secondary">$(alltodos)</span>
  </a>
  <a class='btn btn-outline-primary $(active("notdone"))' href="/?filter=notdone">
    Not done <span class="badge bg-secondary">$(notdonetodos)</span>
  </a>
  <a class='btn btn-outline-primary $(active("done"))' href="/?filter=done">
    Completed <span class="badge bg-secondary">$(donetodos)</span>
  </a>
</div>
```

Let's unpack this code. We have 3 `<a>` elements, styled as buttons, and rendered as a toolbar (thanks to the Twitter Bootstrap library we included in our page). Within the HTML code we interpolate a few pieces of Julia code that make our output dynamic. That is, for each button, we invoke a function called `active` which adds an "active" CSS class if the button matches the active filter. And within each button, inside the nested `<span>` tag, we interpolate the number of todos that match the filter.

As such, we need to make sure that these values are defined and available in the view layer. We can do this by adding the following code to the `TodosController.jl` file (update the `index` function to look like this and add the extra `using` statement):

```julia
using TodoMVC.ViewHelper

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
```

In the above snippet we use `SearchLight.count` to run a `count` query against the database, matching the filters from the request `params`. We also reference a new module, `TodoMVC.ViewHelper` and pass `ViewHelper.active` into the view, together with all the count values that we computed. In an MVC application, helpers are modules that bundle functions which are used in the view layer, in order to keep the view code DRY and simple. In order for our code to work, we need to define the new module and the `active` function.

First, create the helper file:

```julia
julia> touch("app/helpers/ViewHelper.jl")
```

Next, edit it and add the following code:

```julia
module ViewHelper

using Genie

function active(filter::String = "")
  params(:filter, "") == filter ? "active" : ""
end

end
```

The `active` function is pretty simple. It takes a single optional argument, `filter`. If this matches the current GET request's `filter` parameter, the function returns the string "active", which adds the background color to the button.

## Adding tests to our application

Tests are a critical part of developing high-quality software, that is easy to scale and maintain. Some developers take this to the extreme and prefer to write the tests before the code is written -- starting with failing tests that describe the desired behaviour and APIs, and making sure that the tests pass as they implement the minimum necessary feature. This is a good idea, but it may not be always possible or efficient. My theses is that it's fine whether the tests are written before or after the actual code it tests -- but that if the tests are written after, the project should not be considered complete until it has proper test coverage and all the tests pass.

The Julia community recognizes the importance of tests and for this reason Julia has a built-in testing framework under the `Test` module. In addition, there are multiple packages that improve upon the `Test` API.

### Running tests with Genie

Genie uses the testing features available in Julia and some third party packages to set up a ready to use testing environment for Genie applications. Genie handles most of the configuration and boilerplate code for you, so you can focus on writing your tests. How does it work?

When a new Genie MVC app is created, a `test/` folder is automatically added. Inside the `test/` folder, Genie creates a new Julia project, with all the necessary files and dependencies to test the Genie app. The main file for running the tests is `runtests.jl` (which is also the standard file for running tests in the Julia ecosystem). The `runtests.jl` file loads the Genie application, making its various MVC parts available to the tests. In addition, Genie adds and configures `TestSetExtensions`, a convenient package that improves upon Julia's default testing capabilities (<https://github.com/ssfrr/TestSetExtensions.jl>) and makes the running of the tests easier and more modular. With `TestSetExtensions` all we need to do is add test files in the `test/` folder and they will be automatically executed.

#### Writing and running our first tests

There are multiple types of tests, some of the most common ones being unit tests and integration tests. Unit tests are tests that test the behavior of a single piece of code. Integration tests are tests that test the behavior of a whole application. When it comes to MVC applications, unit tests are usually focused on testing the models, while integration tests cover larger features that involve at least two layers of the MVC stack.

If you check the `test/` folder, you will see that a test file has already been added, called `todos_test.jl`. This was created automatically by `SearchLight` when we created our model. The file doesn't include any meaningful tests (that's our job!), but we already have more than enough to get us started.

The `todos_test.jl` test file includes the necessary dependencies and defines a test set with a basic test.

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos

@testset "Todo unit tests" begin

  ### Your tests here
  @test 1 == 1

end;
```

Let's make sure that everything is working as expected. We can run the tests by running the `runtests.jl` file.

```bash
julia --project runtests.jl
```

Our tests run successfully:

```bash
todos_test: .


Test Summary: | Pass  Total  Time
TodoMVC tests |    1      1  0.8s
```

##### Configuring the test database

But looking at our output, we can see that an exception has been thrown while loading the app's initializers:

```julia
Loading initializers
ERROR: SearchLight.Exceptions.MissingDatabaseConfigurationException("DB configuration for test not found")
...output omitted ...
in expression starting at TodoMVC/config/initializers/searchlight.jl:13
```

What Genie is telling us is that we have not configured a test database for SearchLight. This is a very important point: Genie automatically sets up and runs the application in a `test` environment, to make sure that we don't accidentally run tests against our development or production databases. However, because our tests don't use the database yet, none of the tests were impacted. Nevertheless, let's make sure that we have a test database configured.

Setting up the test database is straight forward. Edit the `db/connection.yml` file and add the following lines:

```yaml
test:
  adapter:  SQLite
  database: db/test.sqlite3
```

Now if we run the tests again, we should not get any error.

##### Adding `Todo` unit tests

However, the included test is not very useful beyond making sure that our testing environment is working. We need to write some tests that actually test the behavior of our model. Our `Todo` model is quite simple but it's still very valuable to cover our basics by testing that:

* The model is correctly initialized with the correct attributes (this will prevent accidental changes of the model's structure and defaults)
* The model is correctly validated

Let's proceed!

Update the `todos_test.jl` file and make it look like this:

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation

@testset "Todo unit tests" begin
  t = Todo()

  @testset "Todo is correctly initialized" begin
    @test t.todo == ""
    @test t.completed == false
  end

  @testset "Todo validates correctly" begin

    @testset "Todo is invalid" begin
      v = validate(t)
      @test haserrors(v) == true
      @test haserrorsfor(v, :todo) == true
      @test errorsfor(v, :todo)[1].error_type == :not_empty
    end

    @testset "Todo is valid" begin
      t.todo = "Buy milk"
      v = validate(t)

      @test haserrors(v) == false
      @test haserrorsfor(v, :todo) == false
      @test errorsfor(v, :todo) |> isempty == true
    end

  end

end;
```

We have defined multiple (nested) test sets that group testing logic by area of focus. Within each test set, we can define multiple tests, that cover `Todo` models initialisation and validation. All the 8 tests should pass.

##### Interacting with the database

Notice that we haven't touched the database yet. Let's add a few tests to make sure that our `Todo` items can be correctly persisted. Let's create a new file in the `test/` folder, named `todos_db_test.jl`.

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation, SearchLight.Exceptions

@testset "Todo DB tests" begin
  t = Todo()

  @testset "Invalid todo is not saved" begin
    @test save(t) == false
    @test_throws(InvalidModelException{Todo}, save!(t))
  end

end;
```

If we run the tests now, we'll see that all 10 tests pass. To make our tests execution faster, we can run just the tests we're currently working on:

```bash
julia --project runtests.jl todos_db_test
```

Our tests confirm that invalid todos are not persisted to the database. Now let's make sure that the valid ones do. Append the following code above the final `end;` of the `todos_db_test.jl` file:

```julia
@testset "Valid todo is saved" begin
  t.todo = "Buy milk"
  @test save(t) == true

  tx = save!(t)
  @test ispersisted(tx) == true

  tx2 = findone(Todo, todo = "Buy milk")
  @test pk(tx) == pk(tx2)
end
```

We have set the `todo` field of our model to the string "Buy milk", making it valid. Then we attempt to save it to, and retrieve it from, the database, making sure that it was correctly persisted. Let's run the tests.

Oh no, our new tests are failing! Fortunately the error is quite easy to debug.

```julia
Got exception outside of a @test
  SQLite.SQLiteException("no such table: todos")
```

Of course: we previously configured our DB connection, but we haven't actually initialized the database -- nor did we run the migrations. In addition to setting up the test db, we must also make sure that we clean it up after we finish our tests -- otherwise future tests will find a database that contains data from previous tests.

Here is the final version of our `todos_db_test.jl` file, that sets up the test db and cleans it up at the end of the test run:

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation, SearchLight.Exceptions

try
  SearchLight.Migrations.init()
catch
end

SearchLight.config.db_migrations_folder = abspath(normpath(joinpath("..", "db", "migrations")))
SearchLight.Migrations.all_up!!()

@testset "Todo DB tests" begin
  t = Todo()

  @testset "Invalid todo is not saved" begin
    @test save(t) == false
    @test_throws(InvalidModelException{Todo}, save!(t))
  end

  @testset "Valid todo is saved" begin
    t.todo = "Buy milk"
    @test save(t) == true

    tx = save!(t)
    @test ispersisted(tx) == true

    tx2 = findone(Todo, todo = "Buy milk")
    @test pk(tx) == pk(tx2)
  end

end;

SearchLight.Migrations.all_down!!(confirm = false)
```

##### Adding integration tests

Next, let's take a look at how to add a few integration tests, checking that the interactions between views, controller and model are correct.

Let's add a new file to the `test/` folder, named `todos_integration_test.jl`.

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using Genie
import Genie.HTTPUtils.HTTP

try
  SearchLight.Migrations.init()
catch
end

cd("..")
SearchLight.Migrations.all_up!!()
Genie.up()

@testset "TodoMVC integration tests" begin

  @testset "No todos by default" begin
    response = HTTP.get("http://localhost:8000/")
    @test response.status == 200
    @test contains(String(response.body), "Nothing to do")
  end

  t = save!(Todo(todo = "Buy milk"))

  @testset "Todo is listed" begin
    response = HTTP.get("http://localhost:8000/")
    @test response.status == 200
    @test contains(String(response.body), "Buy milk")
  end

  @test t.completed == false

  @testset "Status toggling" begin
    HTTP.post("http://localhost:8000/todos/$(t.id)/toggle")
    @test findone(Todo, id = t.id).completed == true
  end

  @testset "Status after deleting" begin
    HTTP.post("http://localhost:8000/todos/$(t.id)/delete")
    response = HTTP.get("http://localhost:8000/")
    @test contains(String(response.body), "Nothing to do")
  end

end

Genie.down()
SearchLight.Migrations.all_down!!(confirm = false)
cd(@__DIR__)
```

In the newly added file we configure the database access and start the web server. Then we use the `HTTP` web client to make requests to the server. Our tests call some of the URLs defined by our app and check that the responses are correct, looking for relevant text in the response body. Run the new tests (`julia --project runtests.jl todos_integration_test`), they should all pass.

Finally, we can run all our tests to make sure that everything is working correctly.

```bash
julia --project runtests.jl

todos_db_test: .....
todos_integration_test: .......
todos_test: ........


Test Summary: | Pass  Total   Time
TodoMVC tests |   20     20  23.3s
```

## Adding a REST API

REST APIs allow other applications and software to access the data in our application. Just like the regular Julia libraries, REST APIs are meant to be employed by developers in order to build applications that are interoperable.

### API versioning

There are a few main ways to version REST APIs and we'll use what's arguably the most popular approach: versioning through URI path. This means that we'll place the major version of our API into the URL of the requests. Ex: mytodos.com/api/v1/todos. This is the preferred approach for Genie apps as it's easy to use and easy to understand, while at the same time promoting a modular architecture (as we're about to see).

### Architecting our API

Taking into account the versioning requirements, our API requests will be prefixed with `/api/v1` indicating that the current major version of the API is v1. In the future, if we'll introduce breaking changes into our API (meaning different endpoints, different HTTP methods, different request parameters, different responses and response structures, etc.), we'll need to introduce a new major version of the API (`v2`, `v3` and so on).

Under the hood, each part of the URI will be implemented into a distinct Julia module, making our code modular and composable, for easier maintenance and extensibility. By encapsulating the API logic, as well as the specific version into dedicated modules and submodules we make our code future-proof and easy to maintain.

### Defining our routes

The REST API will expose similar endpoints to the web application itself. We want to allow the consumers of our API to create, retrieve, update and delete todos. The only difference is that we will not include a dedicated `toggle` endpoint, as REST APIs, by convention have a different update mechanism. That being said, let's define our routes (add these at the bottom of the file):

```julia
route("/api/v1/todos", TodosController.API.V1.list, method = GET)
route("/api/v1/todos/:id::Int", TodosController.API.V1.item, method = GET)
route("/api/v1/todos", TodosController.API.V1.create, method = POST)
route("/api/v1/todos/:id::Int", TodosController.API.V1.update, method = PATCH)
route("/api/v1/todos/:id::Int", TodosController.API.V1.delete, method = DELETE)
```

### The implementation plan

We're defining four routes to handle the main four operations of the API: listing, creating, updating and deleting todos. Per the REST API best practices, we'll use dedicated HTTP methods for each of these operations. In addition, again per best practices, we'll use JSON to handle both requests and responses. Finally, to be good citizens of the web, we'll also extend our current set of features to add support for pagination to the list of todos.

### Listing todos

Lets begin with the first operation, the retrieval and listing of todo items. Add this at the bottom of the `TodosController.jl` file, right above the closing `end`.

```julia
### API

module API
module V1

using TodoMVC.Todos
using Genie.Router
using Genie.Renderers.Json
using ....TodosController

function list()
  all(Todo) |> json
end

function item()

end

function create()

end

function update()

end

function delete()

end

end # V1
end # API
```

In the above snippet we define a new module called `API` and a submodule, `V1`. Inside `V1` we declare references to various dependencies with `using` statements. Very important, we bring into scope `Genie.Renderers.Json`, which will do all the heavy-lifting for building JSON responses for our API. You can think of it as the counterpart of `Genie.Renderers.HTML` that we used in our `TodosController` to generate HTML responses. And just like in the main controller, we'll leverage the features in `Genie.Router` to handle the requests data. We have also included a reference to the main TodosController module, using a relative namespace two levels up (notice the four dots `....`).

Finally we define placeholder functions for each of the operations, matching the handlers we defined in our routes file. The `index` function even includes a bit of logic, to allow us to check that everything is well set up. Try it out at `http://localhost:8000/api/v1/todos`, you should get a JSON response with the list of todos.

If everything works well it's time to refine our todos listing. It's important to keep our code DRY and reuse as much logic as possible between the HTML rendering in `TodosController.jl` and our JSON outputting API. Right now `TodosController.index` includes both the filtering and retrieval of the todo items, as well as the rendering of the HTML. The filtering and retrieval operations can be reused by the API, so we should decouple them from the HTML rendering.

Replace the `TodosController.index` function with the following code:

```julia
function count_todos()
  notdonetodos = count(Todo, completed = false)
  donetodos = count(Todo, completed = true)

  (
    notdonetodos = notdonetodos,
    donetodos = donetodos,
    alltodos = notdonetodos + donetodos
  )
end

function todos()
  todos = if params(:filter, "") == "done"
    find(Todo, completed = true)
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false)
  else
    all(Todo)
  end
end

function index()
  html(:todos, :index; todos = todos(), count_todos()..., ViewHelper.active)
end
```

Here we refactor the `index` function to simple handle the HTML rendering, while we prepare the data in two new functions, `count_todos` and `todos`. We'll reuse these functions to prepare the JSON response for our API. It's worth noticing the flexibility of Julia in the way we pass the keyword arguments to the `html` function inside `index()`: we explicitly pass the `todos` keyword argument with the `todos()` value, we splat the `NamedTuple` received from `count_todos()` into three keyword arguments, and finally we pass the `ViewHelper.active` value as the last implicit keyword argument.

Next, we can use these newly created function in our `API.V1.list` function, to retrieve the actual data:

```julia
function list()
  TodosController.todos() |> json
end
```

We can check that our refactoring hasn't broken anything by checking some URLs for both app and API:

* <http://localhost:8000/>
* <http://localhost:8000/?filter=notdone>
* <http://localhost:8000/api/v1/todos>
* <http://localhost:8000/api/v1/todos?filter=done>

I haven't forgotten about our integration tests and you're welcome to run those as well - but they will be more useful once we add tests for the API too.

#### Adding pagination

I'm hoping that our todo list will not be that long to actually need pagination, but pagination is a common and very useful feature of REST APIs and it's worth seeing how it can be implemented. Especially as SearchLight makes it very straightforward. We want to accept two new optional query params, `page` and `limit`, to allow the consumer to paginate the list of todos. The `page` parameter will indicate the number of the page (starting with `1`) and `limit` will indicate the number of todos per page.

As mentioned, the implementation is extremely simple, we only need to pass the extra arguments, with some reasonable defaults, to the `SearchLight.all` function that we use to get the todos. Update the `else` branch in the `TodosController.todos` function as follows:

```julia
function todos()
  todos = if params(:filter, "") == "done"
    find(Todo, completed = true)
  elseif params(:filter, "") == "notdone"
    find(Todo, completed = false)
  else
    # this line has changed
    all(Todo; limit = params(:limit, SearchLight.SQLLimit_ALL) |> SQLLimit,
              offset = (parse(Int, params(:page, "1"))-1) * parse(Int, params(:limit, "0")))
  end
end
```

All we need to do is pass the `limit` and `offset` arguments to the `all` function, and we're done. Given that these are optional (the users can make requests without pagination) we also set some good defaults: if there is no `limit` argument, we include all the todos by passing the `SearchLight.SQLLimit_ALL` constant to the `limit` argument. As for `offset`, this indicates how many items to skip - which are calculated by multiplying the page number by the number of items per page. If there is no `page` argument, we start with the first page by using `1` as the default -- but do notice that when we calculate the offset we use `page - 1` (this way on page 1 the offset is 0). This is because the `offset` argument in the database query represents the number of todos to skip, and for page 1 we want to skip 0 todos. As for the `limit`, the default here is 0 (meaning that if no `limit` argument is passed, we'll include all the todos with an offset of 0).

We can test the new functionality by getting a couple of pages and limiting the number of todos per page to one:

* <http://localhost:8000/api/v1/todos?page=1&limit=1>
* <http://localhost:8000/api/v1/todos?page=2&limit=1>

Also, no pagination will return all the todos, as expected <http://localhost:8000/api/v1/todos>.

Please note that the web app does not support pagination yet. We'll skip it but if you want, you can do it as an exercise: add a new element to the UI to allow the users to navigate between pages of todos -- and set the `limit` to a reasonable constant value, like 20.

### Creating todos

We want to allow the consumer of our API to add new todos. We already have the route and the corresponding route handler -- it's now time to add the actual code. Update the `API.V1.create` function as follows:

```julia
using Genie.Requests
using SearchLight.Validation
using SearchLight

function check_payload(payload = Requests.jsonpayload())
  isnothing(payload) && throw(JSONException(status = BAD_REQUEST, message = "Invalid JSON message received"))

  payload
end

function persist(todo)
  validator = validate(todo)
  if haserrors(validator)
    return JSONException(status = BAD_REQUEST, message = errors_to_string(validator)) |> json
  end

  try save!(todo)
    json(todo, status = CREATED, headers = Dict("Location" => "/api/v1/todos/$(todo.id)"))
  catch ex
    JSONException(status = INTERNAL_ERROR, message = string(ex)) |> json
  end
end

function create()
  payload = try
    check_payload()
  catch ex
    return json(ex)
  end

  todo = Todo(todo = get(payload, "todo", ""), completed = get(payload, "completed", false))

  persist(todo)
end
```

First we declare that we'll be `using` three extra modules. `Genie.Requests` provides a higher level API to handle requests data, and we'll rely on it to help us work with the JSON payloads. The other is `SearchLight.Validation`, which we've already seen in action and help us to validate the data we receive from the consumer of the API. While `SearchLight` gives us access to the `save!` method.

In the `create` function, first we check if the request payload is valid by invoking the `check_payload` function. Given that we expect a JSON payload, in the `check_payload` we verify if the body of the request can be converted to JSON. We use the `Requests.jsonpayload` function to do that. If the payload is not valid JSON, the `Requests.jsonpayload` function will return `nothing`. In this case, we throw an exception in the `check_payload`, informing the user that the message received is not valid JSON.

Once we are sure that we have received a valid JSON payload, we parse it, looking for relevant data to create a new todo item. We provide some good defaults and create a new instance of our `Todo` model, using the provided payload. We then attempt to persist the newly created model to the database, by passing it to the `persist` function, where we apply our model validations. If there are any validation errors, we return an exception with the errors details. If the validations pass, we save the todo in the database and return a JSON response with the newly created todo and the status code `CREATED`. As a best practice, we also pass an additional `Location` header, which is the URL of the newly created todo. If for some reason the todo could not be saved, we return an exception with the error details.

We can test the various scenarios using an HTTP client like Postman or Paw. But we'll skip that for now and just add integration tests in a few minutes.

### Updating todos

Updating todos should be a breeze, especially as we've already implemented our validation logic. First, we need to update the `API.V1.persist` function as follows:

```julia
function persist(todo)
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
```

This change allows us to detect if the todo we're attempting to save was already persisted to the database or not. If it was, we'll update the todo in the database, otherwise we'll create a new one -- and we need to return the correct response, based on the database operation we performed.

Now, for the `API.V1.update` function:

```julia
function update()
  payload = try
    check_payload()
  catch ex
    return json(ex)
  end

  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  todo.todo = get(payload, "todo", todo.todo)
  todo.completed = get(payload, "completed", todo.completed)

  persist(todo)
end
```

We start by checking if the payload is valid. If it is, we continue by retriving the corresponding todo from the database, using the `id` passed as part of the URL. If the todo is not found, we return an exception. Otherwise, we update the todo with the provided data, again, applying some good defaults (in this case, keeping the existing value if a new value was not provided). Finally, we attempt to persist the todo in the database.

### Deleting todos

The last opperation that our API should support is the deletion of the todo items. We'll update the `API.V1.delete` function as follows:

```julia
function delete()
  todo = findone(Todo, id = params(:id))
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

The code attempts to retrieve the todo from the database, based on the `id` passed as part of the URL. If the todo is not found, we return an exception. Otherwise, we delete the todo from the database and return it.

### Retrieving todos

For retrieving individual todo items from the database, we only need to check that the corresponding todo item exists by looking it up by id. If it does not, we return a 404 error. If it does, we return the todo. Here is the code:

```julia
function item()
  todo = findone(Todo, id = params(:id))
  if todo === nothing
    return JSONException(status = NOT_FOUND, message = "Todo not found") |> json
  end

  todo |> json
end
```

## Writing tests for our API

It's time to see our API in action by writing a test suite to check all the endpoints and the various scenarious we've implemented. Let's start by adding a new tast file for our API:

```julia
julia> touch("test/todos_API_test.jl")
end

Next, we'll add the test suite to our newly created file:

```julia
using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using Genie
import Genie.HTTPUtils.HTTP
import Genie.Renderers.Json.JSONParser.JSON3

try
  SearchLight.Migrations.init()
catch
end

cd("..")
SearchLight.Migrations.all_up!!()
Genie.up()

const API_URL = "http://localhost:8000/api/v1/todos"

@testset "TodoMVC REST API tests" begin

  @testset "No todos by default" begin
    response = HTTP.get(API_URL)
    @test response.status == Genie.Router.OK
    @test isempty(JSON3.read(String(response.body))) == true
  end

end

Genie.down()
SearchLight.Migrations.all_down!!(confirm = false)
cd(@__DIR__)
```

Besides the declaration of the used dependencies, the first and the last parts of the file are the setup and teardown of the tests, just like we did in the integration tests. It's where we setup the test database and the API server -- while at the end we remove the test data and stop the web server.

All our tests will be placed inside a main testset called "TodoMVC REST API tests". And our first test simply checks that when initiating our test suit our database does not contain any todos. We make a GET request to our `/todos` endpoint which lists the todo items, and we verify that the response is a 200 OK status code and that the response body is empty.

Next let's add tests for todo creation. Append this under the "No todos by default" testset:

```julia
@testset "Todo creation" begin

  @testset "Incorrect content-type should fail todo creation" begin
    response = HTTP.post(API_URL, ["Content-Type" => "text/plain"], JSON3.write(Dict("todo" => "Buy milk")); status_exception = false)
    @test response.status == Genie.Router.BAD_REQUEST
    @test JSON3.read(String(response.body)) == "Invalid JSON message received"
  end

  @testset "Invalid JSON should fail todo creation" begin
    response = HTTP.post(API_URL, ["Content-Type" => "application/json"], "Surrender your data!"; status_exception = false)
    @test response.status == Genie.Router.BAD_REQUEST
    @test JSON3.read(String(response.body)) == "Invalid JSON message received"
  end

  @testset "Valid JSON with invalid data should fail todo creation" begin
    response = HTTP.post(API_URL, ["Content-Type" => "application/json"], JSON3.write(Dict("todo" => "", "completed" => true)); status_exception = false)
    @test response.status == Genie.Router.BAD_REQUEST
    @test JSON3.read(String(response.body)) == "Todo should not be empty"
  end

  @testset "No todos should've been created so far" begin
    response = HTTP.get(API_URL)
    @test response.status == Genie.Router.OK
    @test isempty(JSON3.read(String(response.body))) == true
  end

  @testset "Valid payload should create todo" begin
    response = HTTP.post(API_URL, ["Content-Type" => "application/json"], JSON3.write(Dict("todo" => "Buy milk")))
    @test response.status == Genie.Router.CREATED
    @test Dict(response.headers)["Location"] == "/api/v1/todos/1"
    @test JSON3.read(String(response.body))["todo"] == "Buy milk"
  end

  @testset "One todo should be created" begin
    response = HTTP.get(API_URL)
    @test response.status == Genie.Router.OK
    todos = JSON3.read(String(response.body))
    @test isempty(todos) == false
    @test length(todos) == 1
    @test todos[1]["todo"] == "Buy milk"

    response = HTTP.get("$API_URL/1")
    @test response.status == Genie.Router.OK
    todo = JSON3.read(String(response.body))
    @test todo["todo"] == "Buy milk"
  end

end # "Todo creation"
```

Here we have a multitude of tests that verify all the assumptions related to todo creation. The first test verifies that when we send a request with an incorrect content-type, the response has a 400 Bad Request status code and that the response body the error message "Invalid JSON message received". The second test checks that when we send a request with an invalid JSON payload, the API responds in the same manner, with a BAD_REQUEST status and the same error message.

The third test checks that despite the valid content-type and JSON payload, if the todo data is not valid, the request will fail with a BAD_REQUEST status and the error message "Todo should not be empty". The fourth test makes an extra check that despite the previous error responses, indeed, no todos have been created up to this point.

Finally, the last two tests confirm that when we send a valid payload, the API successfully creates a new todo, returns it with a 201 Created status code and the location header set to the new todo's URL, and that we can retrive it.

Next, for the todo updating tests:

```julia
@testset "Todo updating" begin

    @testset "Incorrect content-type should fail todo update" begin
      response = HTTP.patch("$API_URL/1", ["Content-Type" => "text/plain"], JSON3.write(Dict("todo" => "Buy soy milk")); status_exception = false)
      @test response.status == Genie.Router.BAD_REQUEST
      @test JSON3.read(String(response.body)) == "Invalid JSON message received"
    end

    @testset "Invalid JSON should fail todo update" begin
      response = HTTP.patch("$API_URL/1", ["Content-Type" => "application/json"], "Surrender your data!"; status_exception = false)
      @test response.status == Genie.Router.BAD_REQUEST
      @test JSON3.read(String(response.body)) == "Invalid JSON message received"
    end

    @testset "Valid JSON with invalid data should fail todo update" begin
      response = HTTP.patch("$API_URL/1", ["Content-Type" => "application/json"], JSON3.write(Dict("todo" => "", "completed" => true)); status_exception = false)
      @test response.status == Genie.Router.BAD_REQUEST
      @test JSON3.read(String(response.body)) == "Todo should not be empty"
    end

    @testset "One existing todo should be unchanged" begin
      response = HTTP.get(API_URL)
      @test response.status == Genie.Router.OK
      todos = JSON3.read(String(response.body))
      @test isempty(todos) == false
      @test length(todos) == 1
      @test todos[1]["todo"] == "Buy milk"
    end

    @testset "Valid payload should update todo" begin
      response = HTTP.patch("$API_URL/1", ["Content-Type" => "application/json"], JSON3.write(Dict("todo" => "Buy vegan milk")))
      @test response.status == Genie.Router.OK
      @test JSON3.read(String(response.body))["todo"] == "Buy vegan milk"
    end

    @testset "One existing todo should be changed" begin
      response = HTTP.get(API_URL)
      @test response.status == Genie.Router.OK
      todos = JSON3.read(String(response.body))
      @test isempty(todos) == false
      @test length(todos) == 1
      @test todos[1]["todo"] == "Buy vegan milk"
    end

    @testset "Updating a non existing todo should fail" begin
      response = HTTP.patch("$API_URL/100", ["Content-Type" => "application/json"], JSON3.write(Dict("todo" => "Buy apples")); status_exception = false)
      @test response.status == Genie.Router.NOT_FOUND
      @test JSON3.read(String(response.body)) == "Todo not found"
    end

  end # "Todo updating"
  ```

These tests follow the logic of the todo creation testset, just adapted to the todo updating scenario -- so we won't get into many details about these.

Now, let's add the todo deletion tests:

```julia
@testset "Todo deletion" begin

  @testset "Deleting a non existing todo should fail" begin
    response = HTTP.delete("$API_URL/100", ["Content-Type" => "application/json"]; status_exception = false)
    @test response.status == Genie.Router.NOT_FOUND
    @test JSON3.read(String(response.body)) == "Todo not found"
  end

  @testset "One existing todo should be deleted" begin
    response = HTTP.delete("$API_URL/1")
    @test response.status == Genie.Router.OK
    @test JSON3.read(String(response.body))["todo"] == "Buy vegan milk"
    @test HTTP.get("$API_URL/1"; status_exception = false).status == Genie.Router.NOT_FOUND
  end

  @testset "No todos should've been left" begin
    response = HTTP.get(API_URL)
    @test response.status == Genie.Router.OK
    @test isempty(JSON3.read(String(response.body))) == true
  end

end # "Todo deletion"
```

The logic should be pretty clear by now. The first test checks that when we try to delete a non-existing todo, the API responds with a NOT_FOUND status and the error message "Todo not found". The second test checks that when we delete an existing todo, the API responds with a OK status and the todo data. While the last test in this testset makes sure that no todos are left in the database.

And finally, to complete our testsuite, we'll add the pagination tests:

```julia
@testset "Todos pagination" begin
  todo_list = [
    Dict("todo" => "Buy milk", "completed" => false),
    Dict("todo" => "Buy apples", "completed" => false),
    Dict("todo" => "Buy vegan milk", "completed" => true),
    Dict("todo" => "Buy vegan apples", "completed" => true),
  ]

  for todo in todo_list
    response = HTTP.post(API_URL, ["Content-Type" => "application/json"], JSON3.write(todo))
  end

  @testset "No pagination should return all todos" begin
    response = HTTP.get(API_URL)
    @test response.status == Genie.Router.OK
    todos = JSON3.read(String(response.body))
    @test isempty(todos) == false
    @test length(todos) == length(todo_list)
  end

  @testset "One per page" begin
    index = 1
    for page in 1:length(todo_list)
      response = HTTP.get("$API_URL?page=$(page)&limit=1")
      todos = JSON3.read(String(response.body))
      @test length(todos) == 1
      @test todos[1]["todo"] == todo_list[index]["todo"]
      index += 1
    end
  end

  @testset "Two per page" begin
    response = HTTP.get("$API_URL?page=1&limit=2")
    todos = JSON3.read(String(response.body))
    @test length(todos) == 2
    @test todos[1]["todo"] == todo_list[1]["todo"]
    @test todos[2]["todo"] == todo_list[2]["todo"]

    response = HTTP.get("$API_URL?page=2&limit=2")
    todos = JSON3.read(String(response.body))
    @test length(todos) == 2
    @test todos[1]["todo"] == todo_list[3]["todo"]
    @test todos[2]["todo"] == todo_list[4]["todo"]
  end

  @testset "Three per page" begin
      response = HTTP.get("$API_URL?page=1&limit=3")
      todos = JSON3.read(String(response.body))
      @test length(todos) == 3
      @test todos[1]["todo"] == todo_list[1]["todo"]
      @test todos[2]["todo"] == todo_list[2]["todo"]
      @test todos[3]["todo"] == todo_list[3]["todo"]

      response = HTTP.get("$API_URL?page=2&limit=3")
      todos = JSON3.read(String(response.body))
      @test length(todos) == 1
      @test todos[1]["todo"] == todo_list[4]["todo"]
    end

    @testset "Four per page" begin
      response = HTTP.get("$API_URL?page=1&limit=4")
      todos = JSON3.read(String(response.body))
      @test length(todos) == 4
      @test todos[1]["todo"] == todo_list[1]["todo"]
      @test todos[2]["todo"] == todo_list[2]["todo"]
      @test todos[3]["todo"] == todo_list[3]["todo"]
      @test todos[4]["todo"] == todo_list[4]["todo"]

      response = HTTP.get("$API_URL?page=2&limit=4")
      todos = JSON3.read(String(response.body))
      @test isempty(todos) == true
    end

    @testset "Five per page" begin
      response = HTTP.get("$API_URL?page=1&limit=5")
      todos = JSON3.read(String(response.body))
      @test length(todos) == 4
      @test todos[1]["todo"] == todo_list[1]["todo"]
      @test todos[2]["todo"] == todo_list[2]["todo"]
      @test todos[3]["todo"] == todo_list[3]["todo"]
      @test todos[4]["todo"] == todo_list[4]["todo"]
    end
end # "Todos pagination"
```

These are a bit more involved. First, we create a todo list, which is some fake data to mock our tests. Next, we iterate over this list and use the API itself to create all the todos. Once our data is in, it's time for the actual tests. The first test checks that when we don't specify any pagination parameters, the API returns all todos. Then we test the outputted data with various pagination scenarios, making sure that the data is split correctly between the various pages, according to the limit parameter.

## Documenting our API with Swagger UI

Swagger UI employs the OpenAPI standard and allows us to document our API in code, and at the same time to publish it via a web-based human-readable interface. In order to add support for Swagger UI we need to add two new packages to our project: `SwagUI` and `SwaggerMarkdown`.

```julia
pkg> add SwagUI, SwaggerMarkdown
```

We will set up the Swagger comments and the API documentation functionality into the `routes.jl` file. The routes for the web application remain the same, but the API routes are now augmented with `swagger"..."` annotations which are used to build the API documentation. The updated `routes.jl` file should look like this:

```julia
using Genie
using TodoMVC.TodosController
using SwagUI, SwaggerMarkdown

route("/", TodosController.index)
route("/todos", TodosController.create, method = POST)
route("/todos/:id::Int/toggle", TodosController.toggle, method = POST)
route("/todos/:id::Int/update", TodosController.update, method = POST)
route("/todos/:id::Int/delete", TodosController.delete, method = POST)

### API routes

swagger"
/api/v1/todos:
  get:
    summary: Get todos
    description: Get the list of todos items with their status
    parameters:
      - in: query
        name: filter
        description: Todo completed filter with the values 'done' or 'notdone'
        schema:
          type: string
          example: 'done'
      - in: query
        name: page
        description: Page number used for paginating todo items
        schema:
          type: integer
          example: 2
      - in: query
        name: limit
        description: Number of todo items to return per page
        schema:
          type: integer
          example: 10
    responses:
      '200':
        description: A list of todos items
  post:
    summary: Create todo
    description: Create a new todo item
    requestBody:
      description: Todo item to create
      required: true
      content:
        application/json:
          schema:
            type: object
            example:
              todo: Buy milk
              completed: false
    responses:
      '201':
        description: Todo item created
      '400':
        description: Invalid todo item
      '500':
        description: Could not create todo item
"
route("/api/v1/todos", TodosController.API.V1.list, method = GET)
route("/api/v1/todos", TodosController.API.V1.create, method = POST)

swagger"
/api/v1/todos/{id}:
  get:
    summary: Get todo
    description: Get a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
          example: 1
    responses:
      '200':
        description: A todo item
      '404':
        description: Todo item not found
  patch:
    summary: Update todo
    description: Update a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
        example: 1
    requestBody:
      description: Todo item to update
      required: true
      content:
        application/json:
          schema:
            type: object
            example:
              todo: Buy milk
              completed: false
    responses:
      '200':
        description: Todo item updated
      '400':
        description: Invalid todo item
      '404':
        description: Todo item not found
      '500':
        description: Could not update todo item
  delete:
    summary: Delete todo
    description: Delete a todo item by id
    parameters:
      - in: path
        name: id
        description: Todo item id
        required: true
        schema:
          type: integer
          example: 1
    responses:
      '200':
        description: Todo item deleted
      '404':
        description: Todo item not found
      '500':
        description: Could not delete todo item
"
route("/api/v1/todos/:id::Int", TodosController.API.V1.item, method = GET)
route("/api/v1/todos/:id::Int", TodosController.API.V1.update, method = PATCH)
route("/api/v1/todos/:id::Int", TodosController.API.V1.delete, method = DELETE)

### Swagger UI route

route("/api/v1/docs") do
  render_swagger(
    build(
      OpenAPI("3.0", Dict("title" => "TodoMVC API", "version" => "1.0.0")),
    ),
    options = Options(
      custom_favicon = "/favicon.ico",
      custom_site_title = "TodoMVC app with Genie",
      show_explorer = false
    )
  )
end
```

First, we have grouped the routes by path, differentiating them by method. We have two distinct paths, `/api/v1/todos` and `/api/v1/todos/:id`. The first path accepts GET and POST requests to list and create todos, while the second path accepts GET, PATCH and DELETE requests to retrieve, update and delete a todo item.

The swagger documentation is built by annotating the individual paths, sub-differentiating them by method. Then, for each path and method combination, we detail the request and response information, including properties like `summary`, `description`, `requestBody` and `responses`.

In addition, at the end of the file we now have a new route to render the Swagger UI. The route invokes the `render_swagger` function, passing various configuration options to build the docs.

This was all! Our API is now documented and we can use the Swagger UI to browse the API by accessing the `/api/v1/docs` route at <http://localhost:8000/api/v1/docs>. Not only that, but the browser is fully interactive, allowing us to run queries against the API and see the results in real time.
