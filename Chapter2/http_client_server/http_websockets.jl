# start from the REPL of with:
# julia http_websockets.jl
# --> Client says hello! 
using HTTP

@async HTTP.WebSockets.listen("127.0.0.1", UInt16(8081)) do ws  # 1
  while !eof(ws)
    data = readavailable(ws)    # 2
    write(ws, data)             # 3   - echo
  end
end
# Task (runnable) @0x000000000bdd2100

HTTP.WebSockets.open("ws://127.0.0.1:8081") do ws   # 4
  write(ws, "Client says hello!")  # 5
  x = readavailable(ws)            # 6
  println(String(x))               # 7
end

# Response:
# Client says hello!
# HTTP.Messages.Response:
# """
# HTTP/1.1 101 Switching Protocols
# Upgrade: websocket
# Connection: Upgrade
# Sec-WebSocket-Accept: yZuObElXGNUo/FJrtSlJpYuup7g=

# """