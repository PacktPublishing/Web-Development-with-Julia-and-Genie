# add WebIO   # in REPL package mode
using WebIO

using Blink
# showing a text paragraph:
body!(w, dom"p"("Hello from WebIO and Blink!"))

# showing a button with JS alert window on click:
body!(w, dom"button"(
    "Greet",
    events=Dict(
        "click" => js"function() { alert('Hello, World!'); }",
    ),
))
