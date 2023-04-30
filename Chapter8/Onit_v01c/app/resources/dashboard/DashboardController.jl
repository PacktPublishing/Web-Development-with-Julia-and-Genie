module DashboardController

using GenieFramework
using TodoMVC, TodoMVC.Todos
using Dates
using GenieAuthentication

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

  @onchange isready, filter_startdate, filter_enddate begin
    completed_todos = Todos.search(; completed = true, startdate = filter_startdate, enddate = filter_enddate, user_id = current_user_id())
    incompleted_todos = Todos.search(; completed = false, startdate = filter_startdate, enddate = filter_enddate, user_id = current_user_id())
    completed_todos_by_category = Todos.search(; completed = true, group = ["category"], startdate = filter_startdate, enddate = filter_enddate, user_id = current_user_id())
    incompleted_todos_by_category = Todos.search(; completed = false, group = ["category"], startdate = filter_startdate, enddate = filter_enddate, user_id = current_user_id())

    total_completed = sum(completed_todos[!,:total_todos])
    total_incompleted = sum(incompleted_todos[!,:total_todos])
    total_time_completed = sum(completed_todos[!,:total_time]) / 60 |> round
    total_time_incompleted = sum(incompleted_todos[!,:total_time]) / 60 |> round

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
  end # onchangeany
end # handlers

function index()
  authenticated!()

  @page("/dashboard", "app/resources/dashboard/views/index.jl").route.action()
end

end