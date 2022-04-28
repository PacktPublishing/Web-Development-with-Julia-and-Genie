using Mux

@app test = (                                       # 1
  Mux.defaults,
  page(respond("<h1>Hello World from Mux!</h1>")),  
  page("/about", respond("<h1>About Mux</h1>")),    # 2
  page("/user/:user", req -> "<h1>Hello, $(req[:params][:user])!</h1>"),
  Mux.notfound())

serve(test)                                         # 3