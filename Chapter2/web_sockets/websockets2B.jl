# paste code in the REPL:
using WebSockets, JSON3

url = "wss://www.bitmex.com/realtime"

payload = Dict(                         # 1
    :op => "subscribe",
    :args => "trade:XBT"
)

function open_websocket()
    WebSockets.open(url) do ws
        if isopen(ws)
            write(ws, JSON3.write(payload))    # 2
        end

        while isopen(ws)
            data, success = readguarded(ws)
            !success && break
            data = JSON3.read(String(data))
            print(data, "\n")
        end

        if !isopen(ws)
            @async open_websocket()
        end

    end
end

@async open_websocket()