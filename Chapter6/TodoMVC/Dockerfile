# pull latest julia image
FROM --platform=linux/amd64 julia:latest

# create dedicated user
RUN useradd --create-home --shell /bin/bash genie

# C compiler for PackageCompiler
RUN apt-get update && apt-get install -y g++

# set up the app
RUN mkdir /home/genie/app
COPY . /home/genie/app
WORKDIR /home/genie/app

# configure permissions
RUN chown genie:genie -R *

RUN chmod +x bin/repl
RUN chmod +x bin/server
RUN chmod +x bin/runtask

# switch user
USER genie

# instantiate Julia packages
RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile(); "

# Compile sysimage 
RUN julia --project compiled/make.jl

# ports
EXPOSE 8000
EXPOSE 80

# set up app environment
ENV JULIA_DEPOT_PATH "/home/genie/.julia"
ENV GENIE_ENV "prod"
ENV GENIE_HOST "0.0.0.0"
ENV PORT "8000"
ENV WSPORT "8000"
ENV EARLYBIND "true"

# run app
CMD ["bin/server"]

# or maybe include a Julia file
# CMD julia -e 'using Pkg; Pkg.activate("."); include("IrisClustering.jl"); '
