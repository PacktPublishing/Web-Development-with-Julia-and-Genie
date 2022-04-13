using HTTP, JSON

todos = Dict(     # type is Dict{Int64, String}
               1 => "Getting groceries",
               2 => "Visiting my therapist",
               3 => "Getting a haircut"
)

json_string = JSON.json(todos)
# "{\"2\":\"Visiting my therapist\",\"3\":\"Getting a haircut\",\"1\":\"Getting groceries\"}"
todos2 = JSON.parse(json_string)
# Dict{String, Any} with 3 entries:
#   "1" => "Getting groceries"
#   "2" => "Visiting my therapist"
#   "3" => "Getting a haircut"

resp = HTTP.Response(
               200,
               ["Content-Type" => "application/json"],
               body=JSON.json(todos)
           )

# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Content-Type: application/json

# {"2":"Visiting my therapist","3":"Getting a haircut","1":"Getting groceries"}"""

body = HTTP.payload(resp) # this gives a Vector of UInt8 bytes
io = IOBuffer(body)
todos = JSON.parse(io)
# Dict{String, Any} with 3 entries:
#   "1" => "Getting groceries"
#   "2" => "Visiting my therapist"
#   "3" => "Getting a haircut"