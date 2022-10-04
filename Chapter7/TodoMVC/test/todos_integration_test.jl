using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using Genie
import Genie.HTTPUtils.HTTP

const APP_PORT = rand(8100:8900)
const APP_URL = "http://localhost:$APP_PORT"

cd("..")
SearchLight.Migrations.alldown!(confirm = false, context = @__MODULE__)
SearchLight.Migrations.allup(context = @__MODULE__)
Genie.up(APP_PORT)

@testset "TodoMVC integration tests" begin

  @testset "No todos by default" begin
    response = HTTP.get(APP_URL, DEFAULT_HEADERS)
    @test response.status == 200
    @test contains(String(response.body), "Nothing to do")
  end

  t = save!(Todo(todo = "Buy milk", user_id = 1))

  @testset "Todo is listed" begin
    response = HTTP.get(APP_URL, DEFAULT_HEADERS)
    @test response.status == 200
    @test contains(String(response.body), "Buy milk")
  end

  @test t.completed == false

  @testset "Status toggling" begin
    HTTP.post("$APP_URL/todos/$(t.id)/toggle", DEFAULT_HEADERS)
    @test findone(Todo, id = t.id).completed == true
  end

  @testset "Status after deleting" begin
    HTTP.post("$APP_URL/todos/$(t.id)/delete", DEFAULT_HEADERS)
    response = HTTP.get(APP_URL)
    @test contains(String(response.body), "Nothing to do")
  end

end

Genie.down()
SearchLight.Migrations.alldown!(confirm = false, context = @__MODULE__)
cd(@__DIR__)