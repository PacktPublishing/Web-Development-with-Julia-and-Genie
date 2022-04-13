using HTTP, JSON

const HOST = "127.0.0.1"
const PORT = 8080
const ROUTER = HTTP.Router()

function show_factorial(req::HTTP.Request)
  headers = [                                       # 7
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "POST, OPTIONS"
  ]
  if HTTP.method(req) == "OPTIONS"                  # 8
    return HTTP.Response(200, headers)
  end
  body = parse(Int64, String(HTTP.body(req)))       # 4
  fact = factorial(big(body))                       # 5
  HTTP.Response(200, headers; body = string(fact))  # 6
end

function render(req::HTTP.Request)
    HTTP.Response(200, read(raw"index.html"))
end

HTTP.@register(ROUTER, "POST", "/factorial", show_factorial)  # 3
HTTP.@register(ROUTER, "GET", "/", render)        # 2

HTTP.serve(ROUTER, HOST, PORT)                    # 1