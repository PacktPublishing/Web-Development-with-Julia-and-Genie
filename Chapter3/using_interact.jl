# add Interact   # pkg mode

using Interact, Blink

ddn = dropdown(["Getting groceries",
                "Visiting my therapist",
                "Getting a haircut",
                "Paying the energy bill",
                "Blog about workspace management"])

w = Window()
ui = dom"div"(ddn)
body!(w, ui)

