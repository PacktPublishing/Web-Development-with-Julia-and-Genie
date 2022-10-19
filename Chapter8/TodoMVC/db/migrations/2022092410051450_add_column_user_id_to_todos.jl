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
