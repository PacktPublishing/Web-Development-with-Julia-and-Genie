# type these lines in the REPL:
using Sockets
errormonitor(@async begin                            # 1
  server = listen(8080)
  while true
    conn = accept(server)
    @async while isopen(conn)
      write(conn, readline(conn, keep=true))         # 2
    end
  end
end)
# Task (runnable) @0x0000000008d40da0

sleep(1) # give the server time to start
client = connect(8080)                               # 3
# TCPSocket(Base.Libc.WindowsRawSocket(0x000000000000039c) open, 0 bytes waiting)

errormonitor(@async while isopen(client)             # 4
  write(stdout, readline(client, keep=true))
end)
# Task (runnable) @0x0000000008d41370

println(client, "Hello World from the Echo Server")  # 5
sleep(1) # give the server time to respond 
# Hello World from the Echo Server

close(client)                                        # 6
