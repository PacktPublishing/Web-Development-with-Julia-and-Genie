module MyPkg

PROJECT_ROOT = abspath(".")
Settings = []

import Dance


#=
    STEP 1
    If apart from `static_dir` as defined in `routes.jl` there are dirs to ignore adding to LOAD_PATH
        => add to `ignore_dirs`
    By default all other sub-dirs of project structure will be added
=#
ignore_dirs = [""]
if Dance.populate_settings(PROJECT_ROOT)
    global Settings
    Settings = Dance.Configuration.Settings
    for item in Dance.populate_load_path(PROJECT_ROOT; ignore_dirs=ignore_dirs)
        push!(LOAD_PATH, item)
    end
end


#=
    STEP 2
    Import modules here below, not above
    (STEP 1 populated `LOAD_PATH`)
=#
function main(args)
    if Dance.populate_router(PROJECT_ROOT)
        include(Settings[:routes_filename]*".jl")

        ## STEP 3: Add custom scripts here that need be run before launching Dance ##
        ##############################################

        start_server::Bool = true
        if length(args)>0
            if args[1]=="repl"
                start_server = false
            end
        end
        Dance.launch(start_server)
    end
end

end
