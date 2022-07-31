using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using Genie
import Genie.HTTPUtils.HTTP
import Genie.Renderers.Json.JSONParser.JSON3

try
    SearchLight.Migrations.init()
catch
end

cd("..")
SearchLight.Migrations.all_up!!()
Genie.up()

const API_URL = "http://localhost:8000/api/v1/todos"

@testset "TodoMVC REST API tests" begin

    @testset "No todos by default" begin
        response = HTTP.get(API_URL)
        @test response.status == Genie.Router.OK
        @test isempty(JSON3.read(String(response.body))) == true
    end

    @testset "Todo creation" begin

        @testset "Incorrect content-type should fail todo creation" begin
            response = HTTP.post(
                API_URL,
                ["Content-Type" => "text/plain"],
                JSON3.write(Dict("todo" => "Buy milk"));
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Invalid JSON message received"
        end

        @testset "Invalid JSON should fail todo creation" begin
            response = HTTP.post(
                API_URL,
                ["Content-Type" => "application/json"],
                "Surrender your data!";
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Invalid JSON message received"
        end

        @testset "Valid JSON with invalid data should fail todo creation" begin
            response = HTTP.post(
                API_URL,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("todo" => "", "completed" => true));
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Todo should not be empty"
        end

        @testset "No todos should've been created so far" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            @test isempty(JSON3.read(String(response.body))) == true
        end

        @testset "Valid payload should create todo" begin
            response = HTTP.post(
                API_URL,
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("todo" => "Buy milk")),
            )
            @test response.status == Genie.Router.CREATED
            @test Dict(response.headers)["Location"] == "/api/v1/todos/1"
            @test JSON3.read(String(response.body))["todo"] == "Buy milk"
        end

        @testset "One todo should be created" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            todos = JSON3.read(String(response.body))
            @test isempty(todos) == false
            @test length(todos) == 1
            @test todos[1]["todo"] == "Buy milk"

            response = HTTP.get("$API_URL/1")
            @test response.status == Genie.Router.OK
            todo = JSON3.read(String(response.body))
            @test todo["todo"] == "Buy milk"
        end

    end # "Todo creation"

    @testset "Todo updating" begin

        @testset "Incorrect content-type should fail todo update" begin
            response = HTTP.patch(
                "$API_URL/1",
                ["Content-Type" => "text/plain"],
                JSON3.write(Dict("todo" => "Buy soy milk"));
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Invalid JSON message received"
        end

        @testset "Invalid JSON should fail todo update" begin
            response = HTTP.patch(
                "$API_URL/1",
                ["Content-Type" => "application/json"],
                "Surrender your data!";
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Invalid JSON message received"
        end

        @testset "Valid JSON with invalid data should fail todo update" begin
            response = HTTP.patch(
                "$API_URL/1",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("todo" => "", "completed" => true));
                status_exception = false,
            )
            @test response.status == Genie.Router.BAD_REQUEST
            @test JSON3.read(String(response.body)) == "Todo should not be empty"
        end

        @testset "One existing todo should be unchanged" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            todos = JSON3.read(String(response.body))
            @test isempty(todos) == false
            @test length(todos) == 1
            @test todos[1]["todo"] == "Buy milk"
        end

        @testset "Valid payload should update todo" begin
            response = HTTP.patch(
                "$API_URL/1",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("todo" => "Buy vegan milk")),
            )
            @test response.status == Genie.Router.OK
            @test JSON3.read(String(response.body))["todo"] == "Buy vegan milk"
        end

        @testset "One existing todo should be changed" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            todos = JSON3.read(String(response.body))
            @test isempty(todos) == false
            @test length(todos) == 1
            @test todos[1]["todo"] == "Buy vegan milk"
        end

        @testset "Updating a non existing todo should fail" begin
            response = HTTP.patch(
                "$API_URL/100",
                ["Content-Type" => "application/json"],
                JSON3.write(Dict("todo" => "Buy apples"));
                status_exception = false,
            )
            @test response.status == Genie.Router.NOT_FOUND
            @test JSON3.read(String(response.body)) == "Todo not found"
        end

    end # "Todo updating"

    @testset "Todo deletion" begin

        @testset "Deleting a non existing todo should fail" begin
            response = HTTP.delete(
                "$API_URL/100",
                ["Content-Type" => "application/json"];
                status_exception = false,
            )
            @test response.status == Genie.Router.NOT_FOUND
            @test JSON3.read(String(response.body)) == "Todo not found"
        end

        @testset "One existing todo should be deleted" begin
            response = HTTP.delete("$API_URL/1")
            @test response.status == Genie.Router.OK
            @test JSON3.read(String(response.body))["todo"] == "Buy vegan milk"
            @test HTTP.get("$API_URL/1"; status_exception = false).status ==
                  Genie.Router.NOT_FOUND
        end

        @testset "No todos should've been left" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            @test isempty(JSON3.read(String(response.body))) == true
        end

    end # "Todo deletion"

    @testset "Todos pagination" begin
        todo_list = [
            Dict("todo" => "Buy milk", "completed" => false),
            Dict("todo" => "Buy apples", "completed" => false),
            Dict("todo" => "Buy vegan milk", "completed" => true),
            Dict("todo" => "Buy vegan apples", "completed" => true),
        ]

        for todo in todo_list
            response = HTTP.post(
                API_URL,
                ["Content-Type" => "application/json"],
                JSON3.write(todo),
            )
        end

        @testset "No pagination should return all todos" begin
            response = HTTP.get(API_URL)
            @test response.status == Genie.Router.OK
            todos = JSON3.read(String(response.body))
            @test isempty(todos) == false
            @test length(todos) == length(todo_list)
        end

        @testset "One per page" begin
            index = 1
            for page = 1:length(todo_list)
                response = HTTP.get("$API_URL?page=$(page)&limit=1")
                todos = JSON3.read(String(response.body))
                @test length(todos) == 1
                @test todos[1]["todo"] == todo_list[index]["todo"]
                index += 1
            end
        end

        @testset "Two per page" begin
            response = HTTP.get("$API_URL?page=1&limit=2")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 2
            @test todos[1]["todo"] == todo_list[1]["todo"]
            @test todos[2]["todo"] == todo_list[2]["todo"]

            response = HTTP.get("$API_URL?page=2&limit=2")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 2
            @test todos[1]["todo"] == todo_list[3]["todo"]
            @test todos[2]["todo"] == todo_list[4]["todo"]
        end

        @testset "Three per page" begin
            response = HTTP.get("$API_URL?page=1&limit=3")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 3
            @test todos[1]["todo"] == todo_list[1]["todo"]
            @test todos[2]["todo"] == todo_list[2]["todo"]
            @test todos[3]["todo"] == todo_list[3]["todo"]

            response = HTTP.get("$API_URL?page=2&limit=3")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 1
            @test todos[1]["todo"] == todo_list[4]["todo"]
        end

        @testset "Four per page" begin
            response = HTTP.get("$API_URL?page=1&limit=4")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 4
            @test todos[1]["todo"] == todo_list[1]["todo"]
            @test todos[2]["todo"] == todo_list[2]["todo"]
            @test todos[3]["todo"] == todo_list[3]["todo"]
            @test todos[4]["todo"] == todo_list[4]["todo"]

            response = HTTP.get("$API_URL?page=2&limit=4")
            todos = JSON3.read(String(response.body))
            @test isempty(todos) == true
        end

        @testset "Five per page" begin
            response = HTTP.get("$API_URL?page=1&limit=5")
            todos = JSON3.read(String(response.body))
            @test length(todos) == 4
            @test todos[1]["todo"] == todo_list[1]["todo"]
            @test todos[2]["todo"] == todo_list[2]["todo"]
            @test todos[3]["todo"] == todo_list[3]["todo"]
            @test todos[4]["todo"] == todo_list[4]["todo"]
        end
    end # "Todos pagination"

end

Genie.down()
SearchLight.Migrations.all_down!!(confirm = false)
cd(@__DIR__)
