module CreateDefaultUser

using Genie
using SearchLight
using ..Main.TodoMVC.Users

function up()
  Genie.Configuration.istest() || return

  Users.User( username  = "testuser",
              password  = "testpass" |> Users.hash_password,
              name      = "Test user",
              email     = "testuser@test.test") |> save!
end

function down()
  Genie.Configuration.istest() || return

  findone(Users.User, username = "testuser") |> delete
end

end
