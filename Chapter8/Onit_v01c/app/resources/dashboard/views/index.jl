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
        #=
        cell(class="st-br", [
          bignumber("Total time completed", :total_time_completed, icon="format_list_numbered", color="positive")
        ])
        cell(class="st-br", [
          bignumber("Total time incomplete", :total_time_incompleted, icon="format_list_numbered", color="negative")
        ])
        =#
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
#=
  row([ # stacked bar chart -- duration of todos by status
    cell(class="st-module col-12", [
      plot(:todos_by_status_time, layout = "{ barmode: 'stack', title: 'Todos by status and duration', xaxis: { title: 'Date' }, yaxis: { title: 'Total duration' } }")
    ])
  ])  # end stacked bar chart -- duration of todos by status
=#
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