module Todos

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using Dates
using SearchLight
using TodoMVC.TodosValidator
import SearchLight.Validation: ModelValidator, ValidationRule
import SearchLight.DataFrames.DataFrame

export Todo

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

SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
  ValidationRule(:user_id, TodosValidator.dbid_is_not_nothing)
  ValidationRule(:duration, TodosValidator.is_int)
])

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

end
