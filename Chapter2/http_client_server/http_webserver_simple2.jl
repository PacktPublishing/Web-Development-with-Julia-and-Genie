using HTTP

HTTP.serve() do request            # 1
  try                              # 2
    return HTTP.Response("Still lots of ToDos!")
  catch e
    return HTTP.Response(404, "Error: $e")
  end
end

# ::HTTP.Request