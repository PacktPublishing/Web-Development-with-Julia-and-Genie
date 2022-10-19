ENV["GENIE_ENV"] = "dev"

using Genie
Genie.loadapp(pwd())

import HTTP

@info "Hitting routes"
for r in Genie.Router.routes()
  try
    r.action()
  catch
  end
end

const PORT = 50515

try
  @info "Starting server"
  up(PORT)
catch
end

try
  @info "Making requests"
  HTTP.request("GET", "http://localhost:$PORT")
catch
end

try
  @info "Stopping server"
  Genie.Server.down!()
catch
end

