module Conf

"""
Overwrite default config, 1 item per line
See docs or `src/Configuration.jl.Settings` dict

Format: param{Symbol}=value{Any}
    e.g: :dev = false
"""
:dev = false


# Overwrite above values by reading from other file, depending on environment
# E.g: include("dev.jl")

end
