using CSV, DataFrames
fname = "todos.csv"
df = CSV.read(fname, DataFrame)