module Todos

import SearchLight: AbstractModel, DbId
import Base: @kwdef

using SearchLight
using TodoMVC.TodosValidator
import SearchLight.Validation: ModelValidator, ValidationRule

export Todo

@kwdef mutable struct Todo <: AbstractModel
  id::DbId = DbId()
  todo::String = ""
  completed::Bool = false
  user_id::DbId = DbId()
end

SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
  ValidationRule(:user_id, TodosValidator.dbid_is_not_nothing)
])

end
