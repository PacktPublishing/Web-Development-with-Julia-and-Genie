using Test, SearchLight, Main.UserApp, Main.UserApp.Todos
using SearchLight.Validation

@testset "Todo unit tests" begin
  t = Todo()

  @testset "Todo is correctly initialized" begin
    @test t.todo == ""
    @test t.completed == false
  end

  @testset "Todo validates correctly" begin

    @testset "Todo is invalid" begin
      v = validate(t)
      @test haserrors(v) == true
      @test haserrorsfor(v, :todo) == true
      @test errorsfor(v, :todo)[1].error_type == :not_empty
    end

    @testset "Todo is valid" begin
      t.todo = "Buy milk"
      v = validate(t)

      @test haserrors(v) == false
      @test haserrorsfor(v, :todo) == false
      @test errorsfor(v, :todo) |> isempty == true
    end

  end

end;