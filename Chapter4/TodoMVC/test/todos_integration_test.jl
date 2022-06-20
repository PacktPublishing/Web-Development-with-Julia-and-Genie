using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using Genie
import Genie.HTTPUtils.HTTP

try
  SearchLight.Migrations.init()
catch
end

cd("..")
SearchLight.Migrations.all_up!!()
Genie.up()

@testset "TodoMVC integration tests" begin

  @testset "No todos by default" begin
    response = HTTP.get("http://localhost:8000/")
    @test response.status == 200
    @test contains(String(response.body), "Nothing to do")
  end

  t = save!(Todo(todo = "Buy milk"))

  @testset "Todo is listed" begin
    response = HTTP.get("http://localhost:8000/")
    @test response.status == 200
    @test contains(String(response.body), "Buy milk")
  end

  @test t.completed == false

  @testset "Status toggling" begin
    HTTP.post("http://localhost:8000/todos/$(t.id)/toggle")
    @test findone(Todo, id = t.id).completed == true
  end

  @testset "After deleting" begin
    HTTP.post("http://localhost:8000/todos/$(t.id)/delete")
    response = HTTP.get("http://localhost:8000/")
    @test contains(String(response.body), "Nothing to do")
  end

end

Genie.down()
SearchLight.Migrations.all_down!!(confirm = false)
cd(@__DIR__)