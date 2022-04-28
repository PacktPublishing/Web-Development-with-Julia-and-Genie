# add Merly    # pkg mode

using Merly

@page "/" HTTP.Response(200,"Hello World from Merly!")    # 1
@page "/hello/:user" HTTP.Response(200,string("<b>Hello ",request.params["user"],"!</b>")) # 2

@route POST "/post" HTTP.Response(200,"I did something!")  # 3

start(host = "127.0.0.1", port = 8086, verbose = true)    # 9