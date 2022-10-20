module GenerateFakeTodos

using ..Main.TodoMVC.Todos
using SearchLight
import Dates
import Faker
import Genie

randcategory() = rand(Todos.CATEGORIES)
randdate() = Dates.today() - Day(rand(0:90))
randduration() = rand(10:240)

function up()
  Genie.Configuration.isdev() || return

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
  Genie.Configuration.isdev() || return
  throw(SearchLight.Migration.IrreversibleMigrationException(@__MODULE__))
end

end
