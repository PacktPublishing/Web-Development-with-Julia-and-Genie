# explore these commands in the REPL:
using HTTP

## Request:
req = HTTP.Request(         
"GET", 		                         # 1 - Could be GET, POST, UPDATE etc
"http://localhost:8081/search",       # 2 - URL - 		            
["Content-Type" => "text/plain"],  # 3 - Header fields -                  
"Hi there!"                        # 4 - Payload/body
)

# 1
req.method           # "GET"
# 2
req.target           # "http://localhost:8081/search"
# 3
req.headers
# 1-element Vector{Pair{SubString{String}, SubString{String}}}:
#  "Content-Type" => "text/plain"
# or more specific:
req["Content-Type"]   # "text/plain" 
# same as: HTTP.header(req, "Content-Type")
# 4
HTTP.payload(req)
# 9-element Vector{UInt8}:
#  0x48
#  0x69
#  0x20
#  0x74
#  0x68
#  0x65
#  0x72
#  0x65
#  0x21
String(HTTP.payload(req))
# "Hi there!"

## Response:
resp = HTTP.Response(
   200,                       # 1 - Status code, 200 means success.
   ["Content-Type" => "text/plain"], # 2 - Header fields -
   body = "Hi there!"         # 3 - Payload/body
)

# 1:
resp.status   # 200
# 2:
resp.headers
# 1-element Vector{Pair{SubString{String}, SubString{String}}}:
#  "Content-Type" => "text/plain"
# or more specific:
resp["Content-Type"]   # "text/plain" 
# same as: HTTP.header(resp, "Content-Type")
# 3:
String(resp.body)          # "Hi there!"
# or:
String(HTTP.payload(resp)) # "Hi there!"