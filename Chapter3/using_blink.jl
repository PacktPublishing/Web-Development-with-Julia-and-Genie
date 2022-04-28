# add Blink   # in REPL package mode
using Blink

w = Window()
body!(w, "Hello from Blink!")

loadurl(w, "https://google.com")
load!(w, "ui/app.css")
load!(w, "ui/frameworks/jquery-3.3.1.js")