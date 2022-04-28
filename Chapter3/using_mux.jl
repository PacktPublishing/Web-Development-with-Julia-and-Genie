# add Mux    # pkg mode

using Interact, Mux

ddn = dropdown(["Getting groceries",
                "Visiting my therapist",
                "Getting a haircut",
                "Paying the energy bill",
                "Blog about workspace management"])

ui = dom"div"(ddn)
WebIO.webio_serve(page("/", req -> ui), 8080) # serve on port 8080