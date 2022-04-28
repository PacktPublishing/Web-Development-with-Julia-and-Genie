# add CSV      # pkg mode
using CSV, DataFrames
fname = "todos.csv"
df = CSV.read(fname, DataFrame)