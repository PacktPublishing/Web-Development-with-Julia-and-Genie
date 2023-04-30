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
