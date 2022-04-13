using HTTP
url = "https://julialang.org"
r = HTTP.get(url)
# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Connection: keep-alive
# Content-Length: 36344
# Server: GitHub.com
# Content-Type: text/html; charset=utf-8
# x-origin-cache: HIT
# Last-Modified: Thu, 31 Mar 2022 15:26:14 GMT
# Access-Control-Allow-Origin: *
# ETag: "6245c816-8df8"
# expires: Mon, 04 Apr 2022 08:53:51 GMT
# ...
println(r.status) # 200
println(String(r.body))
# <!doctype html> <html lang=en > <meta charset=utf-8 > 
# <meta name=viewport  content="width=device-width, initial-scale=1, shrink-to-fit=no"> 
# <meta http-equiv=x-ua-compatible  content="ie=edge"> 
# <meta name=author  content="Jeff Bezanson, Stefan Karpinski, Viral Shah, Alan Edelman, et al."> 
# <meta name=description  content="The official website for the Julia Language. Julia is a language that is fast, 
# dynamic, easy to use, and open source.
println(r.headers)
# Pair{SubString{String}, SubString{String}}["Connection" => "keep-alive", "Content-Length" => "36344", "Server" => "GitHub.com", "Content-Type" => "text/html; charset=utf-8", "x-origin-cache" => "HIT", "Last-Modified" => "Thu, 31 Mar 2022 15:26:14 GMT", "Access-Control-Allow-Origin" => "*", "ETag" => "\"6245c816-8df8\"", "expires" => "Mon, 04 Apr 2022 08:53:51 GMT", "Cache-Control" => "max-age=600", "x-proxy-cache" => "MISS", "X-GitHub-Request-Id" => "F5A0:3CB5:DC5B19:E5B057:624AAFC5", "Via" => "1.1 varnish, 1.1 varnish", "X-Fastly-Request-ID" => "7ce247d3564f7d97a13fb235789763f70b46fc0a", "Fastly-Debug-States" => "DELIVER", "Accept-Ranges" => "bytes", "Date" => "Mon, 04 Apr 2022 08:43:51 GMT", "Age" => "0", "X-Served-By" => "cache-bru1480020-BRU, cache-bru1480075-BRU", "X-Cache" => "MISS, MISS", "X-Cache-Hits" => "0, 0", "X-Timer" => "S1649061831.488585,VS0,VE101", "Vary" => "Accept-Encoding", "Strict-Transport-Security" => "max-age=5356800"]

HTTP.post("http://httpbin.org/post", [], "post body data")
# HTTP.Messages.Response:
# """
# HTTP/1.1 200 OK
# Date: Mon, 04 Apr 2022 08:56:03 GMT
# Content-Type: application/json
# Content-Length: 362
# Connection: keep-alive
# Server: gunicorn/19.9.0
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Credentials: true

# {
#   "args": {},
#   "data": "post body data",
#   "files": {},
#   "form": {},
#   "headers": {
#     "Accept": "*/*",
#     "Content-Length": "14",
#     "Host": "httpbin.org",
#     "User-Agent": "HTTP.jl/1.7.0",
#     "X-Amzn-Trace-Id": "Root=1-624ab2a3-0d8397831936742012f8dd3f"
#   },
#   "json": null,
#   "origin": "81.83.67.231",
#   "url": "http://httpbin.org/post"
# }
# """