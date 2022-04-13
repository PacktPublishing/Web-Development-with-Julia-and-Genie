# paste code in the REPL:
using WebSockets, JSON

url = "wss://www.bitmex.com/realtime?subscribe=trade:XBT"

function open_websocket() 
  WebSockets.open(url) do ws
    while isopen(ws)                   # 1
      data, success = readguarded(ws)
      !success && break
      data = JSON.parse(String(data))  # 2
      print(data, "\n")
    end

    if !isopen(ws)                     # 3
      @async open_websocket()
    end

  end
end

@async open_websocket()