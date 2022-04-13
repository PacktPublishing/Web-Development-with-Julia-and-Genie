# start in REPL or via: julia htttp_webserver_simple.jl:
using HTTP

HTTP.listen() do http                       # 1
  while !eof(http)                          # 2
      println("body data: ", String(readavailable(http)))   # 3
  end
  HTTP.setstatus(http, 200)
  HTTP.setheader(http, "Content-Type" => "text/html")  # 4
  HTTP.startwrite(http)                         # 5
  write(http, "ToDo 1: Getting groceries<br>")  # 6
  write(http, "ToDo 2: Visiting my therapist<br>")
  write(http, "ToDo 3: Getting a haircut")
end

# const host = # ip-address in string format, like "127.0.0.1"
# const port = 8081
# HTTP.listen(host, port) do http
#   	# code                       
# end
