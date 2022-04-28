# add Dash   # in package mode

using Dash

app = dash()                             # 1

app.layout = html_div() do               # 2
    html_h1("Hello from Dash!"),
    html_div("Dash: A web application framework for your data."),
    dcc_graph(
        id = "example-graph-1",
        figure = (
            data = [
                (x = ["Chocolate", "Strawberry", "Vanilla"], y = [21, 19, 33], type = "bar", name = "Male"),
                (x = ["Chocolate", "Strawberry", "Vanilla"], y = [38, 18, 12], type = "bar", name = "Female"),
            ],
            layout = (title = "Flavor Preferences by Gender", barmode="group")
        )
    )
end

run_server(app, "0.0.0.0", debug=true)   # 3