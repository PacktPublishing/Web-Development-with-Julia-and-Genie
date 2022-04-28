# add Bukdu     # in pkg mode

using Bukdu

struct WelcomeController <: ApplicationController     # 1
  conn::Conn
end

struct RestController <: ApplicationController
  conn::Conn
end

function index(c::WelcomeController)                   # 2
  render(JSON, "Hello World from Bukdu!")
end

function init(c::RestController)
  render(JSON, (:init, c.params.region, c.params.site_id, c.params.channel_id))
end

routes() do                                            
  get("/", WelcomeController, index)                        # 3A
  get("/init/region/:region/site/:site_id/channel/:channel_id/", 
    RestController, init, :site_id=>Int, :channel_id=>Int)  # 3B
end

Bukdu.start(8080)                                       # 4
# Bukdu Listening on 127.0.0.1:8080
# Task (runnable) @0x00000000735447d0

# INFO: GET     WelcomeController   index           200 /