# paste code in the REPL:
using WebSockets, JSON3
url = "wss://www.bitmex.com/realtime?subscribe=trade:XBT"

function open_websocket()
    WebSockets.open(url) do ws
        while isopen(ws)                   # 1
            data, success = readguarded(ws)
            !success && break
            data = JSON3.read(String(data))  # 2
            print(data, "\n")
        end

        if !isopen(ws)                     # 3
            @async open_websocket()
        end

    end
end

@async open_websocket()
# Task (runnable) @0x000000000c6eeca0

# Sample output:
# Dict{String, Any}("docs" => "https://ws.bitmex.com/app/wsAPI", "info" => "Welcome to the BitMEX Realtime API.", "version" => "2022-04-29T04:21:29.000Z", "timestamp" => "2022-05-01T11:24:31.350Z", "limit" => Dict{String, Any}("remaining" => 179))
# Dict{String, Any}("success" => true, "request" => Dict{String, Any}("args" => "trade:XBT", "op" => "subscribe"), "subscribe" => "trade:XBTUSD")
# Dict{String, Any}("types" => Dict{String, Any}("grossValue" => "long", "homeNotional" => "float", "price" => "float", "tickDirection" => "symbol", "side" => "symbol", "trdMatchID" => "guid", "foreignNotional" => "float", "symbol" => "symbol", "size" => "long", "timestamp" => "timestamp"), "action" => "partial", "keys" => Any[], "attributes" => Dict{String, Any}("symbol" => "grouped", "timestamp" => "sorted"), "filter" => Dict{String, Any}("symbol" => "XBTUSD"), "data" => Any[Dict{String, Any}("grossValue" => 3682994, "homeNotional" => 0.03682994, "price" => 38012.5, "tickDirection" => "ZeroMinusTick", "side" => "Sell", "trdMatchID" => "a0695101-e4fb-8b27-422c-c168cf25779d", "foreignNotional" => 1400, "symbol" => "XBTUSD", "size" => 1400, "timestamp" => "2022-05-01T11:23:45.185Z")], "table" => "trade", "foreignKeys" => Dict{String, Any}("side" => "side", "symbol" => "instrument"))
# Dict{String, Any}("action" => "insert", "data" => Any[Dict{String, Any}("grossValue" => 263075, "homeNotional" => 0.00263075, "price" => 38012, "tickDirection" => "MinusTick", "side" => "Sell", "trdMatchID"