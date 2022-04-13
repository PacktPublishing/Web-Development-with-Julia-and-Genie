# start with julia echoserver.jl
using Sockets
server = listen(8080)               # 1
while true                          # 2
  conn = accept(server)             # 3
  @async begin                      # 4
    try                             # 5
      while true
        line = readline(conn)       # 6
        println(line)
        if chomp(line) == "S"       # 7
          println("Stopping TCP server...")
          close(conn)
          exit(0)
        else
          write(conn, line)         # 8 - here is the echo
        end
      end
    catch ex                        # 9
      print("connection lost with error $ex")
      close(conn)
    end
  end # end coroutine block
end
close(conn)