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
