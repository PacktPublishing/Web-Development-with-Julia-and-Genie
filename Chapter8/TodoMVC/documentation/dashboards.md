# Developing interactive data dashboards with Genie

Julia is a relatively new programming language, but it has already gained a lot of traction in the data science community. It is designed to be easy to learn and use, and has seen great adoption in digital R&D, scientific computing, data analysis and machine learning. A critical part of the data science workflow is the ability to create interactive data dashboards for data exploration and analysis. In this chapter, we will see how to use Genie to create interactive data dashboards.

We will extend our todo app with a new section that will allow us to analyze and visualize our todo list to understand how our time is allocated between various types of activities. However, as it is right now, our data is not very useful for this purpose. We need richer data, and a lot more of it in order to do interesting things. So let's add a few more fields to our todo items, and generate a lot of random data.

To make for an interesting analysis, let's add the following fields:

1) category - we'll make this a string with one of the following values: "work", "personal", "family", "hobby", "errands", "shopping", "accounting", "learning", "other"
2) date - the day the todo item was created
3) duration - an integer representing the duration of the todo item in minutes.

And for our data dashboard, we will allow our users to filter the todos by date interval and visualize their data by date, status, category and duration, exposing interesting stats about the user's productivity.

## Augmenting the data

We'll begin by adding the new fields to our todo items. As usual, we'll use a migration, so let's create it:

```julia
julia> using SearchLight
julia> SearchLight.Migrations.new("add category date and duration to todos")
```

Once the migration is created, edit the new migration file as follows:

```julia
module AddCategoryDateAndDurationToTodos

import SearchLight.Migrations: add_columns, remove_columns, add_indices, remove_indices

function up()
  add_columns(:todos, [
    :category => :string,
    :date => :date,
    :duration => :int
  ])

  add_indices(:todos, [
    :category,
    :date,
    :duration
  ])
end

function down()
  remove_indices(:todos, [
    :category,
    :date,
    :duration
  ])

  remove_columns(:todos, [
    :category,
    :date,
    :duration
  ])
end

end
```

When ready, run the migration to update the database schema:

```julia
julia> SearchLight.Migrations.up()
```

Now that we have the new fields in our database, we need to update our todo model to reflect the new fields. Update the
`app/resources/todos/Todos.jl` file by replacing the declaration of the `Todo` struct with the following:

```julia
using Dates

const CATEGORIES = ["work", "personal", "family", "hobby", "errands", "shopping", "accounting", "learning", "other"]

@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
  todo::String = ""
  completed::Bool = false
  user_id::DbId = DbId()
  category::String = CATEGORIES[end]
  date::Date = Dates.today()
  duration::Int = 30
end
```

We have added a new dependency on the `Dates` module, as our new `date` property is a date instance. This means that
we also need to declare the dependency in our `Project.toml` file, so make sure to run `pkg> add Dates` in the app's repl. We also
define a `CATEGORIES` constant where we stored the list of possible categories. We then update the `Todo` struct to include the new fields,
setting their default values to the last category in the list ("other"), today's date and 30 minutes.

While we're here, let's also add an extra validator to ensure that duration is a valid number:

```julia
SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
  ValidationRule(:user_id, TodosValidator.dbid_is_not_nothing)
  ValidationRule(:duration, TodosValidator.is_int)                    # <--- new validator
])
```

### Generating random data

Now that our database and model definition have been updated, we need to generate some random data to populate our database and make
our dashboard more interesting. We also need to set some random values for the new columns for the todos that already exist in the database.
Let's create a new migration to code and manage our data generation:

```julia
julia> using SearchLight
julia> SearchLight.Migrations.new("generate fake todos")
```

In the resulting migration file, add the following code:

```julia
module GenerateFakeTodos

using ..Main.TodoMVC.Todos
using SearchLight
using Dates
using Faker

randcategory() = rand(Todos.CATEGORIES)
randdate() = Dates.today() - Day(rand(0:90))
randduration() = rand(10:240)

function up()
  for i in 1:1_000
    Todo(
      todo = Faker.sentence(),
      completed = rand([true, false]),
      user_id = DbId(1),
      category = randcategory(),
      date = randdate(),
      duration = randduration()
    ) |> save!
  end

  for t in find(Todo, SQLWhereExpression("category is ?", nothing))
    t.category = randcategory()
    date = randdate()
    duration = randduration()
    save!(t)
  end
end

function down()
  throw(SearchLight.Migration.IrreversibleMigrationException(@__MODULE__))
end

end
```

This migration will generate 1000 new todos with random values, and also update the existing todos with random values
for the new columns. We use the `Faker` package to generate random sentences for the `todo` field, so make sure to add it to the
app as well (`pkg> add Faker`) before running the migration. For the generation of the random categories, dates, and duration values, we declare
three helper functions (`randcategory`, `randdate`, and `randduration`) that we can reuse to both create new todos and update
the existing ones (and keep our code DRY).

Now you can run the migration to generate the fake data:

```julia
julia> using SearchLight
julia> SearchLight.Migrations.up()
```

## Building our data dashboard

Now that we have a lot more data, we can start building our data dashboard. We'll start by creating a new resource (controller)
for our dashboard:

```julia
julia> using Genie
julia> Genie.Generator.newresource("dashboard", pluralize = false)
```

This will create a new controller file `app/resources/dashboard/DashboardController.jl`.

### Using Genie with low-code and reactive programming

For the dashboard component we will introduce a new paradigm of programming, by using low-code to create reactive web user
interfaces. What does this mean? When creating our todo list we used pure web development techniques, writing low level web
user interfaces using HTML, CSS, and JavaScript. However, Genie provides a more productive way of creating web user interfaces
using low-code and reactive programming. This way we can create web UIs without having to write HTML and JavaScript code. We do this
by employing a series of Genie packages that give us access to around 100 UI components covering all necessary elements of a web
application, including inputs and forms (dropdowns, sliders, ranges, etc), text and content, and plots.
These components are reactive, meaning that they automatically update based on user input, without needing to do a page refresh. This is
ideal for data exploration dashboards, where we want to be able to interact with the data and see the results immediately.

These features are provided by a package called `GenieFramework`. Genie is a part of the GenieFramework set of libraries, but in
addition this also exposes the mentioned extra packages for low-code and web UI components and reactive programming.

So let's start working on our dashboard. First, we need to add the `GenieFramework` package to our app's `Project.toml` file:

```julia
pkg> add GenieFramework
```

Now we can edit our `DashboardController.jl` file:

```julia
module DashboardController

using GenieFramework
using TodoMVC.Todos
using Dates
using GenieAuthentication

end
```

We declare the dependencies. Besides the `GenieFramework` package, we also need to import our `Todo` model, the `Dates` module and
the `GenieAuthentication` package, which we will use to protect our dashboard with authentication.

Next, under the last `using` declaration, add the following code:

```julia
@handlers begin
  @in filter_startdate = today() - Month(1)
  @in filter_enddate = today()

  @out total_completed = 0
  @out total_incompleted = 0
  @out total_time_completed = 0
  @out total_time_incompleted = 0

  @out todos_by_status_number = PlotData[]
  @out todos_by_status_time = PlotData[]
  @out todos_by_category_complete = PlotData[]
  @out todos_by_category_incomplete = PlotData[]
end
```

Central to the low-code and reactive programming paradigm is the use of `@handlers` and `@in` and `@out` declarations. The `@handlers`
block designates the code that will be executed when the dashboard is loaded and when the user interacts with the various inputs on the page.
The `@in` and `@out` declarations define the input and output variables that will be used in the dashboard.
The `@in` variables are the ones that will be used to filter the data, and the `@out` variables will be used to display the results.

So we start by declaring the data - what inputs we want to receive and what outputs we want to display. Later on we'll add reactive
handlers to some of these values to update the data and re-output the results when the inputs change.

We said that we want to allow the users to filter the todos by the date range, so we declare two input variables `filter_startdate` and `filter_enddate`.
These are inputs so we use the `@in` declaration. We also declare four output variables, `total_completed`, `total_incompleted`, `total_time_completed`, and `total_time_incompleted`
which will be used to display their corresponding data as "Big Number" components on our dashboard. These values should be pretty
much self-explanatory, but just in case it's not entirely clear, `total_completed` will represent the total number of completed todos,
`total_incompleted` will represent the total number of incompleted todos, and `total_time_completed` and `total_time_incompleted` will
represent the total time spent on completed and incompleted todos, respectively.

In addition, we'll also want to display a number of plots (charts) as follows:
1/ an area chart with 2 overlapping areas showing the number of completed and incompleted todos over time.
2/ a stacked bar chart showing the number of completed and incompleted todos and their duration, also over time.
3/ two pie charts showing the distribution of completed and incompleted todos by category.

The plots use `PlotData` vectors to display their data, so we declare four @out variables, `todos_by_status_number`, `todos_by_status_time`,
`todos_by_category_complete`, and `todos_by_category_incomplete`, one for each of the charts we want to display.

Each of the ten reactive variables we declared will be automatically synchronized between the server and the browser automatically,
every time we update them. The `@in` values accept changes from the browser (but we can also update them from the server and they will be reflected in the UI),
while the `@out` values can not be set from the browser, but only from the server.

Finally, notice that we initialize all our variables to empty default values. We'll use event handlers later on to update them
to their proper values.

However, now that we have setup our reactive variables, we can design our view using Genie's low-code API. Because our values are set to empty default values,
we won't see the actual data -- but it's enough to allow us to build our UI and make sure it works.

### Designing the dashboard view

We'll start by adding a new view file `app/resources/dashboard/views/index.jl`:

```julia
container([

  # section 1 #
  btn(color="primary", flat=true, "⥢ Home", onclick="javascript:window.location.href='/';")
  h1("Todos productivity report")
  # end section 1 #

  # section 2 #
  # date filters row
  row([
    cell(class="col-6", [
      textfield("Start date", :filter_startdate, clearable = true, filled = true, [
        icon(name = "event", class = "cursor-pointer", style = "height: 100%;", [
          popup_proxy(cover = true, [datepicker(:filter_startdate, mask = "YYYY-MM-DD")])
        ])
      ])
    ])

    cell(class="col-6", [
      textfield("End date", :filter_enddate, clearable = true, filled = true, [
        icon(name = "event", class = "cursor-pointer", style = "height: 100%", [
          popup_proxy(ref = "qDateProxy", cover = true, [datepicker(:filter_enddate, mask = "YYYY-MM-DD")])
        ])
      ])
    ])
  ])
  # end date filters row
  # end section 2 #

  # section 3 #
  # big numbers row
  row([
    cell(class="st-module", [
      row([
        cell(class="st-br", [
          bignumber("Total completed", :total_completed, icon="format_list_numbered", color="positive")
        ])
        cell(class="st-br", [
          bignumber("Total incomplete", :total_incompleted, icon="format_list_numbered", color="negative")
        ])
        cell(class="st-br", [
          bignumber("Total time completed", :total_time_completed, icon="format_list_numbered", color="positive")
        ])
        cell(class="st-br", [
          bignumber("Total time incomplete", :total_time_incompleted, icon="format_list_numbered", color="negative")
        ])
      ])
    ])
  ])
  # end big numbers row
  # end section 3 #

  # section 4 #
  row([ # area chart -- number of todos by status
    cell(class="st-module col-12", [
      plot(:todos_by_status_number, layout = "{ title: 'Todos by status', xaxis: { title: 'Date' }, yaxis: { title: 'Number of todos' } }")
    ])
  ]) # end area chart -- number of todos by status

  row([ # stacked bar chart -- duration of todos by status
    cell(class="st-module col-12", [
      plot(:todos_by_status_time, layout = "{ barmode: 'stack', title: 'Todos by status and duration', xaxis: { title: 'Date' }, yaxis: { title: 'Total duration' } }")
    ])
  ])  # end stacked bar chart -- duration of todos by status

  row([
    # pie chart -- number of completed todos by category
    cell(class="st-module col-6", [
      plot(:todos_by_category_complete, layout = "{ title: 'Completed todos by category', xaxis: { title: 'Category' }, yaxis: { title: 'Number of todos' } }")
    ])

    # pie chart -- number of incomplete todos by category
    cell(class="st-module col-6", [
      plot(:todos_by_category_incomplete, layout = "{ title: 'Incompleted todos by category', xaxis: { title: 'Category' }, yaxis: { title: 'Number of todos' } }")
    ])
  ])
  # end section 4 #
])
```

Let's break it down. First, everything is wrapped in a `container`. Containers are used for build responsive layouts, in conjunction with rows and cols.
Rows are used to create horizontal groups of columns, and columns are used to create vertical groups of content. We'll use rows and columns to create
a responsive layout for our dashboard.

Then in the first section we add a button to go back to the home page, and a title. The second section contains the date filters. Section 3 contains
the big numbers row, and section 4 contains the charts.

For the date filters we use a text input field with a date picker. We use the `popup_proxy` component to create a popup that will display the date picker
when the user clicks on the calendar icon. Also we _bind_ the value of the text field and of the date picker to the same reactive variable, `:filter_startdate`, so that
whenever the user changes the date in the date picker or in the text field, our `filter_startdate` reactive variable on the server will be updated.

Big numbers are very commonly used UI elements for data dashboard. As the name suggest, they display important values together with a label and an icon.
We bind them to their corresponding server side values.

Then, in the last section, we have the plots. We display them on 3 rows, one for the area chart, one for the stacked bar chart, and one for the two pie charts.
All we have to do in order to display the plots is to bind them to their corresponding reactive variables. In addition we also customize the layout of the plots passing
in various extra options.

That's all -- our UI is ready! Notice how simple it is to create powerful UIs with Genie's low-code API, using a declarative syntax in pure Julia. We didn't have to write a single line of HTML or JavaScript!

### Updating the dashboard view

Now that we have our UI ready, we need to update it with the actual data. Back to our `DashboardController.jl` file, inside the `@handlers` block, under the last
reactive variable declaration, add the following code:

```julia
@onchangeany isready, filter_startdate, filter_enddate begin

# we'll add more code here

end
```

With this code we declare an event handler that will be triggered whenever any of the reactive variables `isready`, `filter_startdate`, or `filter_enddate` change.
The `filter_startdate` and `filter_enddate` reactive variables are the ones we connected to the date filters in the UI. While `isready` reactive variable is a boolean
value that is automatically provided and updated by Genie itself -- by default it's set to `false` and when the UI is fully rendered and loaded and ready to receive
data from the server, it's automatically set to `true`. So what this event handler means is that whenever the dashboard is loaded or user changes the date filters,
we update the dashboard view with fresh data.

Inside the event handler, add the following code:

```julia
completed_todos = Todos.search(; completed = true, startdate = filter_startdate, enddate = filter_enddate)
incompleted_todos = Todos.search(; completed = false, startdate = filter_startdate, enddate = filter_enddate)
completed_todos_by_category = Todos.search(; completed = true, group = ["category"], startdate = filter_startdate, enddate = filter_enddate)
incompleted_todos_by_category = Todos.search(; completed = false, group = ["category"], startdate = filter_startdate, enddate = filter_enddate)

# more code will come here
```

We start by computing the completed and incomplete todos, and the completed and incomplete todos by category. We will need these values to pull out the various stats
and populate our big numbers and our plots. We use the `Todos.search` function to do that, passing in the `completed` and `group` parameters to filter the todos by status and by category.
We also pass in the `startdate` and `enddate` parameters to filter the todos by date. The `Todos.search` function returns a `DataFrame` object, which is a tabular data structure that is very similar to a spreadsheet.

Let's create the `Todos.search` function. Open our `Todos.jl` model file and add the following code at the end of the module (inside the module, after the validators block):

```julia
function search(; completed = false, startdate = today() - Month(1), enddate = today(), group = ["date"])
  filters = SQLWhereEntity[
      SQLWhereExpression("completed = ?", completed),
      SQLWhereExpression("date >= ? AND date <= ?", startdate, enddate)
  ]

  DataFrame(Todo, SQLQuery(
    columns = SQLColumns(Todo, (
      total_time = SQLColumn("SUM(duration) AS total_time", raw = true),
      total_todos = SQLColumn("COUNT(*) AS total_todos", raw = true),
    )),
    where = filters,
    group = group,
    order = ["date ASC", "category ASC"],
  ))
end
```

Now, going back to our `DashboardController.jl` file, let's add more code to our event handler:

```julia
total_completed = sum(completed_todos[!,:total_todos])
total_incompleted = sum(incompleted_todos[!,:total_todos])
total_time_completed = sum(completed_todos[!,:total_time]) / 60 |> round
total_time_incompleted = sum(incompleted_todos[!,:total_time]) / 60 |> round
```

We compute the total number of completed and incomplete todos, and the total time spent on completed and incomplete todos.
We use the `sum` function to sum up the values in the `total_todos` and `total_time` columns of the `completed_todos` and `incompleted_todos` dataframe.

Next, let's add more code to our event handler:

```julia
todos_by_status_number = [
  PlotData(
    x = completed_todos[!,:todos_date],
    y = completed_todos[!,:total_todos],
    fill = "tozeroy",
    name = "Completed",
    plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
  ),

  PlotData(
    x = incompleted_todos[!,:todos_date],
    y = incompleted_todos[!,:total_todos],
    fill = "tozeroy",
    name = "Incompleted",
    plot = StipplePlotly.Charts.PLOT_TYPE_SCATTER
  ),
]
```

This is the data for the first plot, the area chart that shows the number of completed and incomplete todos over time.

Moving on, let's create the rest of our chart's data:

```julia
todos_by_status_time = [
  PlotData(
    x = completed_todos[!,:todos_date],
    y = completed_todos[!,:todos_duration],
    name = "Completed",
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR
  ),

  PlotData(
    x = incompleted_todos[!,:todos_date],
    y = incompleted_todos[!,:todos_duration],
    name = "Incompleted",
    plot = StipplePlotly.Charts.PLOT_TYPE_BAR
  ),
]

todos_by_category_complete = [
  PlotData(
    values = completed_todos_by_category[!,:total_todos],
    labels = completed_todos_by_category[!,:todos_category],
    plot = StipplePlotly.Charts.PLOT_TYPE_PIE
  )
]

todos_by_category_incomplete = [
  PlotData(
    values = incompleted_todos_by_category[!,:total_todos],
    labels = incompleted_todos_by_category[!,:todos_category],
    plot = StipplePlotly.Charts.PLOT_TYPE_PIE
  )
]
```

### Adding the routes

Now that our controller logic is ready and our UI is built, let's set up the route to render the dashboard view. Go to the
`routes.jl` file and add at the bottom:

```julia
route("/dashboard", DashboardController.index)
```

We indicate that the `/dashboard` route should render the `DashboardController.index` function. So let's create the `index`
function at the bottom of the `DashboardController.jl` file (under the `@handlers` block, inside the module):

```julia
function index()
  authenticated!()

  @page("/dashboard", "app/resources/dashboard/views/index.jl").route.action()
end
```

We want to make sure that access is restricted to authenticated users, so we call the `authenticated!` function. Then we build a "page"
using the `@page` macro (also part of Genie's low-code API). You can think of the page as a mix of routes and views. It abstracts
away a lot of complexity by setting up all the necessary pieces to enable the reactive UI. We create a new instance of a page
indicating that the route is `/dashboard` and the view is `app/resources/dashboard/views/index.jl`. We then call the `action` function on the page's route to render the view.
That's all, our dashboard should now be up and running!