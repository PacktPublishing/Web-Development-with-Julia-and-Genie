using HTTP, JSON3
todos = Dict(  # type is Dict{Int64, String}
    1 => "Getting groceries",
    2 => "Visiting my therapist",
    3 => "Getting a haircut"
)

json_string = JSON3.write(todos)
# "{\"2\":\"Visiting my therapist\",\"3\":\"Getting a haircut\",\"1\":\"Getting groceries\"}"
todos2 = JSON3.read(json_string)
# JSON3.Object{Base.CodeUnits{UInt8, String}, Vector{UInt64}} with 3 entries:
#   Symbol("2") => "Visiting my therapist"
#   Symbol("3") => "Getting a haircut"
#   Symbol("1") => "Getting groceries"

todos2[1]  # "Getting groceries"

resp = HTTP.Response(
    200,
    ["Content-Type" => "application/json"],
    body=JSON3.write(todos)     # 1
)

# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Content-Type: application/json

# {"2":"Visiting my therapist","3":"Getting a haircut","1":"Getting groceries"}"""

body = HTTP.payload(resp) # 2 - this gives a Vector of UInt8 bytes
io = IOBuffer(body)       # 3
todos = JSON3.read(io)    # 4
# or combined in one line:
todos = JSON3.read(IOBuffer(HTTP.payload(resp)))
# JSON3.Object{Base.CodeUnits{UInt8, String}, Vector{UInt64}} with 3 entries:
#   Symbol("2") => "Visiting my therapist"
#   Symbol("3") => "Getting a haircut"
#   Symbol("1") => "Getting groceries"