using HTTP, Sockets, JSON3, Dates

mutable struct ToDo                      # 1
    id::Int64
    description::String
    completed::Bool
    created::Date
    priority::Int8
end

const ToDos = Dict{Int,ToDo}()          # 2   

function initToDos()                     # 3
    todo1 = ToDo(1, "Getting groceries", false, Date("2022-04-01", "yyyy-mm-dd"), 5)
    todo2 = ToDo(2, "Visiting my therapist", false, Date("2022-04-02", "yyyy-mm-dd"), 4)
    todo3 = ToDo(3, "Getting a haircut", true, Date("2022-03-28", "yyyy-mm-dd"), 6)
    todo4 = ToDo(4, "Paying the energy bill", false, Date("2022-04-04", "yyyy-mm-dd"), 8)
    todo5 = ToDo(5, "Blog about workspace management", true, Date("2022-03-29", "yyyy-mm-dd"), 4)
    todo6 = ToDo(6, "Book a flight to Israel", false, Date("2022-04-04", "yyyy-mm-dd"), 3)
    todo7 = ToDo(7, "Conquer the world", true, Date("2022-03-29", "yyyy-mm-dd"), 1)
    ToDos[1] = todo1
    ToDos[2] = todo2
    ToDos[3] = todo3
    ToDos[4] = todo4
    ToDos[5] = todo5
    ToDos[6] = todo6
    ToDos[7] = todo7
end

function getToDo(req::HTTP.Request)                     # 4
    todoId = HTTP.URIs.splitpath(req.target)[3]         # 4A
    todoId = parse(Int64, todoId)
    # println(todoId)
    # println(haskey(ToDos, todoId))
    if haskey(ToDos, todoId)                            # 4B
        todo = ToDos[todoId]                            # 4C
        return HTTP.Response(200, JSON3.write(todo))    # 4D
    else
        return HTTP.Response(200, JSON3.write("No ToDo with that key exists."))
    end
end

function deleteToDo(req::HTTP.Request)                  # 5
    todoId = HTTP.URIs.splitpath(req.target)[3]
    todo = ToDos[parse(Int64, todoId)]
    delete!(ToDos, todo.id)                             # 5A
    return HTTP.Response(200)                           # 5B
end

function createToDo(req::HTTP.Request)                      # 6
    todo = JSON3.read(IOBuffer(HTTP.payload(req)), ToDo)    # 6A
    println(todo)
    todo.id = maximum(collect(keys(ToDos))) + 1             # 6B
    ToDos[todo.id] = todo                                   # 6C
    println(ToDos)
    return HTTP.Response(200, JSON3.write(todo))            # 6D
end

function updateToDo(req::HTTP.Request)                       # 7    
    todo = JSON3.read(IOBuffer(HTTP.payload(req)), ToDo)
    ToDos[todo.id] = todo                                    # 7A
    return HTTP.Response(200, JSON3.write(todo))             # 7B
end

JSON3.StructType(::Type{<:ToDo}) = JSON3.Struct() # - needed to be able to work with JSON3
# for more info see:
# https://discourse.julialang.org/t/ann-json3-jl-yet-another-json-package-for-julia/25625?u=abhimanyuaryan
initToDos()
# println(ToDos)

const HOST = ip"127.0.0.1"
const PORT = 8080
const ROUTER = HTTP.Router()
HTTP.@register(ROUTER, "POST", "/api/todos", createToDo)        # 8A
HTTP.@register(ROUTER, "GET", "/api/todos/*", getToDo)          # 8B
HTTP.@register(ROUTER, "PUT", "/api/todos", updateToDo)         # 8C
HTTP.@register(ROUTER, "DELETE", "/api/todos/*", deleteToDo)    # 8D

HTTP.serve(ROUTER, HOST, PORT)

# tests:
# using HTTP, Dates, JSON
# GET
# r = HTTP.get("http://localhost:8080/api/todos/3")
# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Transfer-Encoding: chunked

# {"id":3,"description":"Getting a haircut","completed":true,"created":"2022-03-28","priority":6}"""

# DELETE
# julia> HTTP.delete("http://localhost:8080/api/todos/3")
# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Transfer-Encoding: chunked

# """
# julia> HTTP.get("http://localhost:8080/api/todos/3")
# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Transfer-Encoding: chunked

# "No ToDo with that key exists.""""

# CREATE
# julia> JSON.json(ToDo(8, "Listening music", false, Date("2022-04-07", "yyyy-mm-dd"), 7))
# "{\"id\":8,\"description\":\"Listening music\",\"completed\":false,\"created\":\"2022-04-07\",\"priority\":7}"

# HTTP.post("http://localhost:8080/api/todos", [], "{\"id\":8,\"description\":\"Listening music\",\"completed\":false,\"created\":\"2022-04-07\",\"priority\":7}")

# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Transfer-Encoding: chunked

# {"id":8,"description":"Listening music","completed":false,"created":"2022-04-07","priority":7}"""

# Response from webserver:
# D:\Julia_Docs\Julia-Web-Development-with-Genie\Chapter2>julia webserver_json3.jl
# ToDo(8, "Listening music", false, Date("2022-04-07"), 7)
# Dict{Int64, ToDo}(
# 5 => ToDo(5, "Blog about workspace management", true, Date("2022-03-29"), 4), 
# 4 => ToDo(4, "Paying the energy bill", false, Date("2022-04-04"), 8), 
# 6 => ToDo(6, "Book a flight to Israel", false, Date("2022-04-04"), 3), 
# 7 => ToDo(7, "Conquer the world", true, Date("2022-03-29"), 1), 
# 2 => ToDo(2, "Visiting my therapist", false, Date("2022-04-02"), 4), 
# 8 => ToDo(8, "Listening music", false, Date("2022-04-07"), 7), 
# 3 => ToDo(3, "Getting a haircut", true, Date("2022-03-28"), 6), 
# 1 => ToDo(1, "Getting groceries", false, Date("2022-04-01"), 5)

# test with curl , postman