# (@v1.8) pkg> add WebSockets
using WebSockets

function main()
    WebSockets.open("wss://wsaws.okex.com:8443/ws/v5/public") do ws   # 1
        for i = 1:100
            a = time_ns()                   # 2
            write(ws, "ping")               # 3
            data, success = readguarded(ws) # 4
            !success && break               # 5
            b = time_ns()
            println(String(data), " ", (b - a) / 1000000) # 6
            sleep(0.1)
        end
    end
end

main()