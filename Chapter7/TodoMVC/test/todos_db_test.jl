using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation, SearchLight.Exceptions

cd("..")
SearchLight.Migrations.alldown!(context = @__MODULE__, confirm = false)
SearchLight.Migrations.allup(context = @__MODULE__)

@testset "Todo DB tests" begin
  t = Todo()

  @testset "Invalid todo is not saved" begin
    @test save(t) == false
    @test_throws(InvalidModelException{Todo}, save!(t))
  end

  @testset "Valid todo is saved" begin
    t.todo = "Buy milk"
    t.user_id = 1
    @test save(t) == true

    tx = save!(t)
    @test ispersisted(tx) == true

    tx2 = findone(Todo, todo = "Buy milk")
    @test pk(tx) == pk(tx2)
  end

end;

SearchLight.Migrations.alldown!(context = @__MODULE__, confirm = false)
cd(@__DIR__)