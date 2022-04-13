# start these lines in the REPL:
using Sockets
errormonitor(@async begin                         # 1
  server = listen(8001)
  while true
      conn = accept(server)
      @async while isopen(conn)
          write(conn, readline(conn, keep=true))  # 2
      end
  end
end)

client = connect(8001)                            # 3 

errormonitor(@async while isopen(client)          # 4
  write(stdout, readline(client, keep=true))
end)

println(client,"Hello World from the Echo Server")  # 5
# Hello World from the Echo Server

close(client)                                       # 6
