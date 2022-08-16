module Todos

using SearchLight
using TodoMVC.TodosValidator

import SearchLight: AbstractModel, DbId
import SearchLight.Validation: ModelValidator, ValidationRule
import Base: @kwdef

export Todo

@kwdef mutable struct Todo <: AbstractModel 
  id::DbId = DbId() 
  todo::String = "" 
  completed::Bool = false 
end 

SearchLight.Validation.validator(::Type{Todo}) = ModelValidator([
  ValidationRule(:todo, TodosValidator.not_empty)
])

end
