# Deploying Genie applications in production

Genie, together with some of the packages available in the Genie ecosystem provide a multitude of useful features for deploying
and running applications in demanding production environments, with a focus on performance, stability and security.

## Genie app environments

Genie applications run in the context of an environment, which is a way of configuring a Genie application with a group of settings that
optimized for a certain task (for instance optimized for development, or testing, or high performance execution in production).
In other words, we can define multiple environments, each with its specific configuration, and then we can easily swap the environment
to enable all the corresponding settings at once.

Out of the box Genie apps come with three environments: `dev` (which stands for development), `prod` (for production), and `test` (for testing).
Each environment has its own configuration file with the same name, placed inside the `config/env/` folder of the app. These
environments come with preconfigured settings for running tasks optimized for the three common situations: development,
testing and high performance production runtime.

The environment that is used the most by developers is `dev`, which is also the default environment that the app uses,
and is optimised for running the application for development. It provides features that make the development process
more efficient and productive, such as code reloading and recompilation every time files are saved (by automatically
setting up file loading with the `Revise.jl` package), extensive and rich error messages and error stacks, and
automatic serving of assets like images, stylesheets and scripts.
The `dev` environment also has sensible settings for running the application locally, such as using the `127.0.0.1` host and the
default Genie port, 8000.

However, the development features such as code reloading, rich error messages, or asset serving are not appropriate when we run
the application in production -- either because they slow down the application or because they can expose sensitive information
that can be exploited by attackers. For such situations we use the `prod` environment which provides configurations that are optimised
for running the application in production. The `prod` environment disables code reloading and recompilation,
disables detailed error messages, and recommends the disabling of assets serving. In addition, productions apps will use by
default the host `0.0.0.0`, which is usually what's expected when deploying on most hosting platforms.

Finally, the third bundled environment, `test`, is optimized for testing the application, and we've already seen it in action
in the section about unit tests.

### Customizing the environments

We can edit the environment files in order to change, remove, or add configuration elements. Take for instance the default `dev.jl` file:

```julia
using Genie, Logging

Genie.Configuration.config!(
  server_port                     = 8000,
  server_host                     = "127.0.0.1",
  log_level                       = Logging.Info,
  log_to_file                     = false,
  server_handle_static_files      = true,
  path_build                      = "build",
  format_julia_builds             = true,
  format_html_output              = true,
  watch                           = true
)

ENV["JULIA_REVISE"] = "auto"
```

The `config!` method modifies and returns the `Genie.config` object, which is an instance of `Genie.Configuration.Settings` and
represents the application's configuration. You can probably recognize here some of the configurations we have already mentioned,
like for instance the host and the port of the application, the logging settings, handling of assets (static files), or various
formatting options that are useful in development.

We can also use the environment files to add environment dependent settings, like for instance the `JULIA_REVISE`
configuration which sets automatic file re-compilation when files change, by employing the `Revise.jl` package.

By contrast, take a look at the default `prod.jl` file:

```julia
using Genie, Logging

Genie.Configuration.config!(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Error,
  log_to_file                     = false,
  server_handle_static_files      = true, # for best performance set up Nginx or Apache web proxies and set this to false
  path_build                      = "build",
  format_julia_builds             = false,
  format_html_output              = false
)

if Genie.config.server_handle_static_files
  @warn("For performance reasons Genie should not serve static files (.css, .js, .jpg, .png, etc) in production.
         It is recommended to set up Apache or Nginx as a reverse proxy and cache to serve static assets.")
end

ENV["JULIA_REVISE"] = "off"
```

We can see the differences in server configuration (host and port), logging, formatters, and automatic recompilation.

### Creating extra environments

The three default environments cover some of the most common use cases, but we can define other environments as needed. For
instance, many development teams commonly use a staging environment, as an intermediary stage between development and production.
All we need to do in order to enable a new environment is to create the corresponding env file. For instance, we can create a
copy of our `prod.jl` file and name it `staging.jl` to define a staging environment -- and modifying it as necessary:

```julia
# config/env/staging.jl
using Genie, Logging

Genie.Configuration.config!(
  server_port                     = 8000,
  server_host                     = "0.0.0.0",
  log_level                       = Logging.Debug,
  log_to_file                     = true,
  server_handle_static_files      = true, # for best performance set up Nginx or Apache web proxies and set this to false
  path_build                      = "build",
  format_julia_builds             = true,
  format_html_output              = true
)

ENV["JULIA_REVISE"] = "off"
```

The snippet shows a possible `staging` configuration where we keep some of the production settings but enable more comprehensive
logging and some extra formatting to help us debug potential issues before we release the application in production.

### SearchLight database environments

Equally important is the ability to automatically configure the database connection based on environments. SearchLight integrates
with Genie's environments to automatically pick the right database connection. This is very important in order to avoid that we
accidentally pollute or destroy production data when we run our application in development or test.

Remember that we have already configured a distinct test database in our db/connection.yml file.

```yaml
env: ENV["GENIE_ENV"]

dev:
  adapter:  SQLite
  database: db/dev.sqlite3

test:
  adapter:  SQLite
  database: db/test.sqlite3
```

See how at the top of the file we set `env` to automatically pick the application's environment, which in turn allows SearchLight
to connect to the corresponding database.

### Changing the active environment

In the section about unit tests, we have seen how the very first thing in the `test/runtests.jl` file, our test runner,
is to change the environment of the application to `test`. Now we understand why this is important: to apply the right
configuration during tests and to connect to the right database.

As such, one way of changing the applications' environment is by passing the env's name as a Julia environment variable, either by
setting it in the `ENV` global, or by passing it as a command line argument when starting the app. We'll see in just a minute
how to switch our application to run in production -- but before we can do that, there's one thing we need to do: prepare the database.

We have not defined a database configuration for our prod environment, and this will cause the app to error out at startup.
So let's make sure we add it first. Append the following to the end of the `db/connection.yml` file:

```yaml
prod:
  adapter:  SQLite
  database: db/prod.sqlite3
```

SearchLight will create the `prod.sqlite3` database next time we start the app in the `prod` environment.

#### Starting the application in production

By default Genie apps start in development, as that is the logical first step once an app is created: to develop it. But we
can easily change the active environment at any time - however, this must be done when the app is started, in order to allow
the proper loading of the environment's settings. Otherwise, changing the environment when the app is running requires restarting the app.

##### Using environment variables

One way to change the active environment is by passing the app's active env as a command line environment variable.
Environment variables are key-value pairs, stored by Julia in the `ENV` collection, which offer information
about the current context of the Julia execution. We can access these variables from within our app as `ENV["<variable_name>"]`.
We can define our environment variables when starting our app, by passing them as extra command line arguments. For instance,
we can configure our Genie app to not show the Genie loading banner and overwrite the web server port by running our app as:

```bash
GENIE_BANNER=false PORT=9999 bin/server
```

This will disable the Genie banner and will start the application on port 9999, producing the following output:

```bash=
Ready!

┌ Info: 2022-08-07 16:21:56
└ Web Server starting at http://127.0.0.1:9999 - press Ctrl/Cmd+C to stop the server.
```

In the same way, we can pass the `GENIE_ENV` environment variable to our script in order to start the app with the
designated environment, for example:

```bash
> GENIE_ENV=prod bin/server
```

or maybe

```bash
> GENIE_ENV=test bin/repl
```

##### Using `config/env/global.jl`

You may have noticed that in the `config/env` folder there is a `global.jl` file that by default only contains a comment.
As the comment indicates, we can use this file to define and apply _global_ configuration variables - that is, settings that
will be applied to all the environments. Think of it as a way to avoid copying the same settings in all the environment files.

However, as this file is loaded right before the specific environment file for the app, we can actually use it to change the
active environment. For instance, if we add this line to the `global.jl` file, our application will always run in `prod` env:

```julia
ENV["GENIE_ENV"] = "prod"
```

**Setting the active env in the `global.jl` file will always overwrite the configuration set via `GENIE_ENV`.**

#### Running the app in production

Let's restart our app now in production, for example by using the `GENIE_ENV` environment variable:

```bash
> GENIE_ENV=prod bin/repl
```

Upon restarting the app in production our database was automatically created, but SearchLight has only created an empty db.
We need to set up the database structure by running the database migrations.

```julia
julia> using SearchLight

julia> SearchLight.Migration.init()

julia> SearchLight.Migration.allup()
```

Now everything is ready for our app to run in production. We can test it by starting the server (`julia> up()`) and visiting
<http://localhost:8000>. Our todo app should run as expected - but of course, you won't be able to see any of the todo items
you may have added in development, as in production the app is using the new production db. You'll find the todo items when
restarting the app in `dev` mode again. This level of data isolation provided by application environments ensures that we
don't accidentally run dev or test code using the production data.

With our app fully configured for running in production, we're now ready to deploy on the internet.

## Containerizing Genie apps with Docker and GenieDeployDocker.jl

Docker deployments are the most common way of releasing and scaling web applications as part of devops workflows. Genie has
official support for Docker containerization via the `GenieDeployDocker` plugin. Let's use it to containerize our app.

We'll start by adding the `GenieDeployDocker` package: `pkg> add GenieDeployDocker`

Once installed we'll use it to generate a `Dockerfile` for our application (the `Dockerfile` is the configuration file that
tells Docker how to containerize our app):

```julia
julia> using GenieDeployDocker

julia> GenieDeployDocker.dockerfile()
Docker file successfully written at /path/to/your/app/TodoMVC/Dockerfile
```

If you're familiar with Docker you can take a look at the resulting `Dockerfile`. Right out of the box it contains everything
that is needed to set up a Linux container with preinstalled Julia, set up our application and its dependencies, and start
the server to listen on the designated ports. You can read more about the `Dockerfile` in the official Docker documentation at
<https://docs.docker.com/engine/reference/builder/>.

We'll need to make only one change in the `Dockerfile` - towards the bottom there is a line that reads `ENV GENIE_ENV "dev"`.
This sets the environment used by the app. By default it's set to `dev` - edit this line and set the app's environment to
`prod`.

Now that we have a `Dockerfile` we can ask Docker to build our container.

```julia
julia> GenieDeployDocker.build()
```

This process can take a bit as Docker will pull the linux OS image from the internet, install and precompile our app's
dependencies, copy our application into the linux container, and finally run the app by starting the server. As you run the
`build` command you'll be able to follow the progress of the various steps as the REPL's output.

Once the build finishes, we can "deploy" our application in the Docker container locally - that is, run the container and
access the application within the container running on our computer. Let's do it to confirm that everything works as expected:

```julia
julia> GenieDeployDocker.run()
```

This will start our Genie application inside the Docker container, in the production environment, by running the `bin/server`
script -- as configured by the line `CMD ["bin/server"]` in the Dockerfile. In addition, it will bind the app's port inside the container (port 8000) to
the port 80 of the Docker host (that is, your computer). This means that, after the familiar Genie loading screen, once confirmed
that the application is ready, you can access it by simply visiting <http://localhost> in your browser.

## Setting up our Github repo

In this step we'll set up a Github repo for our TodoMVC app. We'll use Github to for two main actions: to set up CI (Continuous
Integration) and have Github Actions run our test suite every time we push to the repo; and to serve as a public repo that
we can access from our deployment servers.

For the following actions you will need a free Github account. Login to your Github account and create a new repo to host the app at
<https://github.com/new>. Give it a good name, like `GenieTodoMVC`. Put a description too if you want then click on "Create repository".

Once the Github repo is created we need to configure your local Genie app to use it. Going back to your computer, in the terminal, in
the app's folder, run the following (you will need to have `git` installed on your computer):

```bash
> git init
> git add .
> git commit -m "initial commit"
> git branch -M main
> git remote add origin <HTTPS URL OF YOUR GITHUB REPO>
> git push -u origin main
```

### Setting up Github CI

Once our app's code has been pushed to Github we can set up our CI workflow to take advantage of our test suite. This integration
will automatically run every time we push code to our repo.

Inside the root of our app create a new folder named `.github` -- and inside this create a new folder named `workflows`. Next,
within the `workflows` folder create a new file, `ci.yml` and add the following content to it:

```yml
name: ci
on:
  - push
  - pull_request
jobs:
  test:
    name: Julia ${{ matrix.version }} - ${{ matrix.os }} - ${{ matrix.arch }}
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        version:
          - '1.6'
          - '1.7'
          - 'nightly'
        os:
          - ubuntu-latest
          - macOS-latest
          - windows-latest
        arch:
          - x64
    steps:
      - uses: actions/checkout@v2
      - uses: julia-actions/setup-julia@latest
        with:
          version: ${{ matrix.version }}
          arch: ${{ matrix.arch }}
      - uses: julia-actions/julia-buildpkg@latest
      - uses: julia-actions/julia-runtest@latest
```

This configuration file will run our test suite on every git push and git pull request, on three Julia versions (1.6, 1.7, and nightly),
on the three main operating systems. Our testing strategy covers all the relevant Julia versions: 1.6 is LTS, 1.7 is stable, and 1.8 is
nightly. At the moment of writing this, Julia 1.8 is still pre-release (nightly), but if by the time you read this the Julia
1.8 version is released, make sure to also explicitly add it.

When you finish don't forget to push the changes to Github:

```bash
> git add .
> git commit -m "CI"
> git push -u origin main
```

That's it, now our application is fully configured on Github.

## Deploying Genie apps with Git and Docker containers

Now that we have confirmed that our application runs correctly in a Docker container, we can deploy our application on any of
the multitude of web hosting services that support Docker container deployments. By using Docker containers, we can be sure
that the exact setup described in the `Dockerfile` and tested on our machine will be run and configured on the hosting service.

### AWS EC2 hosting

AWS is the most popular hosting platform at the moment so let's see how to deploy our Genie app there. AWS has a multitude of
services (over 100) providing a huge array of possible deployment setups. Most of the AWS configurations are quite complex and
go beyond the scope of this chapter, with large books and month long certifications programs being dedicated to teach AWS usage.
We'll go with one of the simplest and most straightforward way to get the application up and running.

To follow through with the next section you will need a free AWS account -- a credit card is required in order to open the AWS account.

Start by going to <https://signin.aws.amazon.com> and login -- if you don't have an account already, sign up. Once you sign in
into the AWS console go to the EC2 dashboard <https://console.aws.amazon.com/ec2/v2/home> and click on "Launch instances".
In the "Launch Instance" wizard first give the instance a name, like "GenieTodoMVC". Then for the OS image search for
"Amazon linux 2 ami". From the search results pick the 64-bit (x86) "Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type"
(or newer kernel version if available at the time of reading).

We'll use the `t2.micro` with 1 vCPU and 1 GB of RAM. This image is free tier eligible - meaning that if you qualify for the
free tier offer, you'll use this for free.

Next create a SSH key pair - to keep things simple we won't use it now but download it and store it safely so you can login to
your server over SSH in the future.

Then go ahead a create a security group - leave the SSH access and make sure to allow HTTP and HTTPs traffic from the internet.

That's it, we can now launch the instance and go back to the EC2 dashboard. It might take a couple of minutes to see our
newly created server in the instances table. Once it's visible, select its row and click Actions > Connect (or right click
on the row and chose "Connect" from the contextual menu). This will open a terminal into the EC2 instance in a new browser
tab.

#### Installing and configuring Docker

Now that our web server is online we need to install Docker and git to run our deployment workflow:

```bash
> sudo yum install -y docker
> sudo yum install -y git
```

With Docker and git installed, let's make sure that our Docker service runs correctly -- as by default it is disabled:

```bash
> sudo service docker status
```

If this command reports that the status is `Active: inactive (dead)` it means that the Docker service has been installed but
it hasn't been correctly started. We'll start it manually to make sure that all goes well:

```bash
> sudo service docker start
```

If no errors, we can check the status again -- we should see `Active: active (running)`.

Now, to set Docker to autostart:

```bash
> sudo systemctl enable docker
> sudo usermod -aG docker ec2-user
```

Finally, restart the EC2 instance:

```bash
> sudo reboot
```

This can take a couple of minutes - after restarting, just reconnect back to the server from the EC2 dashboard as described above.

#### Cloning the Github repo

With Docker up and running it's time to clone our app's source code onto the server. We'll use our public Github repo. Run
this into the EC2 instance terminal:

```bash
> git clone <URL TO YOUR GITHUB REPO>
```

If you're having problems with accessing your repo, you can use the public repo we have created while writing the
book, available at <https://github.com/essenciary/GenieTodoMVC>.

Next, move into the app's directory that we just cloned: `cd <YOUR REPO NAME>` -- ex `> cd GenieTodoMVC`.

Time to build our docker container:

```bash
> docker build . -t todomvc
```

Once the build completes, we can run our container, mapping our app's port (8000) to port 80 (HTTP) of our EC2 instance:

```bash
> docker run -d -p 80:8000 todomvc
```

Now the application will be accessible on the public IPv4 address as well as on the public IPv4 DNS indicated for your
instance in the EC2 dashboard.

**You need to access the application over HTTP not HTTPS, as we have not configured an SSL certificate for our app.
Setting up SSL certificates on AWS for EC2 instances goes beyond the scope of this chapter but you can find the
information by reading the various guides and tutorials that are publicly available.**

#### Setting up the production database on AWS

Our application runs well, however there is an issue with our current configuration. Because we're using a SQLite database,
our database is now inside the container, which exposes our data to be lost if our container is destroyed. In addition,
SQLite is not the best choice for production databases, for instance due to limitations when it comes to concurrent writes.
Finally, in general the best practice is to set up the database outside the application's container so that they won't
compete over resources, especially in a high load scenario.

As we're using AWS, let's employ one of the available cloud database services available. We'll use RDS which stands for
Relational Database Service. RDS give us access to managed relational databases in the AWS cloud, including commonly used
backends like MySQL/MariaDB, PostgreSQL and Oracle. SearchLight supports all three of these, so we have multiple choices -
we'll go with MariaDB.

Start by visiting the RDS home page at <https://eu-west-3.console.aws.amazon.com/rds/home> and click "Create database". In
the next step pick "Standard create" for database creation method, "MariaDB" for the engine options, and "Free tier" for the
template. Then in the "Settings" section you can give a name to the instance (database server) using the "DB Instance Identifier"
field, and set up the Master username and the Master password. Make sure to write down the user and the pass
as we'll need them to connect. Leave the rest of the options as default until you get to "Public access" and set that to "Yes".
Then for the "VPC security group" leave "Choose existing" and pick the security group you have already setup for the web app.
For the "Database authentication" leave "Password authentication" -- then open "Additional configuration" and put a name for the
"Initial database name". Leave the rest of the options as defaults and click "Create database" at the bottom of the page.

After this you will be redirected to the Dashboard page <https://console.aws.amazon.com/rds/home?#databases:>.
You may have to wait a few minutes for the database to be ready, as indicated in the "Status" column showing "Creating".

Once the database instance becomes available you can click on it to see its details. In the "Connectivity and security"
section you will find the endpoint and the port that can be used to connect to the db. We can now test that our DB is
set up and accessible by connecting from our computer, using a MySQL client. If you don't have one you can try DbGate, a
free database client supported on all major operating systems <https://dbgate.org/database/mysql-client.html>.

Open the MySQL client and configure it to use the "endpoint" as the host, use the default port 3306, and input the master user
and master password for username and password. If you have the option to configure the default database, put the name of the
db you have configured when setting up the RDS instance. If all went well you will be able to confirm the correct setup by
successfully connecting to the RDS database.

#### Preparing our production app to use the RDS database

Now that we have configured our database we need to ensure that it can be used by our app. There are two things we need to
address: connecting to the RDS database, and ensuring that all database migrations are run.

##### Automating database migrations

Let's start with the migrations. We want to make sure that all the migrations are automatically run in production for every
build we release. The simplest way to do this is to configure this to be run every time the application is started, and we
can achieve this by adding the following code at the bottom of the `config/initializers/searchlight.jl` file:

```julia
try
  SearchLight.Migration.init()
catch
end
SearchLight.Migration.allup()
```

Now every time the app starts it will ensure that the migrations are configured and that all the available migrations are up.
The `Migration.init` method will through an exception if it has already been run, so we put it in a `try/catch` block. The
`Migration.allup` function however will not through any exception if the migrations are already up, it will simply not run
any migrations if all are up.

##### Configuring the RDS database connection

Now it's time to configure our application to use the RDS database. You might be tempted to just go and add the
connection info to the `db/connection.yml` file. This can be a viable option in most situations, but give our flow, where
we use a public Github repo, it's a bad idea. Our `db/connection.yml` is pushed to the Github repo, exposing the connection
info to our publicly accessible database, meaning that anybody would be able to connect to our db!
Instead we'll pass the database connection info as environment variables for our Docker container on AWS.

What we need to configure though is the fact that we'll use the MySQL adapter -- and we can also safely set the name of the
database. So comment out or delete the current `prod` connection that uses SQLite and add the following MySQL connection:

```yml
prod:
  adapter:  MySQL
  database: <name of your database>
```

We also need to add `SearchLightMySQL` as a dependency of our app, otherwise SearchLight won't be able to connect to the
MariaDB backend. In the app's Julia REPL run:

```julia
(GenieTodoMVC) pkg> add SearchLightMySQL
```

When finished, push the changes to Github:

```bash
> git commit -am "MySQL support and autorun migrations"
> git push -u origin main
```

Next go to AWS > EC2 Dashboard > Instances <https://console.aws.amazon.com/ec2/v2/home?#Instances:instanceState=running> and
connect to the EC2 instance we created earlier (the web server).

Once connected check if the container is running -- and if yes, get its name:

```bash
> docker container ls
```

Stop the running container using:

```bash
> docker stop <name of container>
```

Now make sure that you move into the applications' folder, ex `cd GenieTodoMVC` and pull the changes from the Github repo
with `git pull`.

Almost done. The last step is to make the database information available to our container. One way is to pass all the info
as environment variables to the `docker` command, like this:

```bash
SEARCHLIGHT_USERNAME=<master username> SEARCHLIGHT_PASSWORD=<master password> SEARCHLIGHT_HOST=<database endpoint> docker run -d -p 80:8000 todomvc
```

However, this is a bit verbose - but also, it creates a potential security issue as the command, including the database login info,
would be stored in the terminal's history. We're better off using another docker feature, namely the `env-file` option. This
allows us to pass an environment text file that includes all the connection data. Let's create this env file and use it.
We'll use the `nano` text editor which should already be available on the Linux instance (if it's not, add it with `sudo yum install nano`).

```bash
> nano ../env.list
```

The nano editor will create the file and open it up for editing. Type in the following content, putting your actual connection
data:

```cmd
SEARCHLIGHT_HOST=<database endpoint>
SEARCHLIGHT_USERNAME=<master username>
SEARCHLIGHT_PASSWORD=<master password>
```

Save the file (Ctr+O) and exit (Ctrl+X).

That's all - now we can start the server by running the docker container:

```bash
> docker run -d -p 80:8000 --env-file=../env.list todomvc
```

It might take a bit to start. If you want to peek into the running logs of the app, you can check the container's logs as follows:

```bash
 > docker container ls
```

and get the name of the container -- then:

```bash
> docker logs <name of container>
```

Once the app is ready you can access it on the container's public IPv4 address or on the public IPv4 DNS, as listed in the
EC2 instance summary page.

**Remember to use HTTP not HTTPS, as we have not configured an SSL certificate for our app. Setting up SSL certificates on
AWS for EC2 instances goes beyond the scope of this chapter but you can find the information by reading the various guides
and tutorials that are publicly available.**

##### Auto-generating the secrets.jl file

If you looked at the Docker container's logs, you may have noticed that the production app shows a warning that "No secret
token is defined". The secret token is a unique random sequence of characters, that is different for each Genie app, and is
used to encrypt data used by the application, like sessions and cookies. This token is stored in the `config/secrets.jl` file
which is by default added to `.gitignore` meaning that it won't be pushed to our Github repo and it won't be pulled onto our
server. The reason for this is to avoid that we accidentally push sensitive data to public Github repos.

The problem however is that if the `secrets.jl` file is missing, Genie will generate a temporary one and use it to encrypt the
data. Every time the app is restarted, a new secret token is generated -- and when it changes, data encrypted with a different
secret, can't be decrypted. So let's extend our application to make sure that production apps automatically generate their
secret file, by adding the following line at the bottom of `config/env/prod.jl`:

```julia
Genie.Secrets.secret_file_exists() || Genie.Generator.write_secrets_file()
```

## Improving application startup time with PackageCompiler.jl

Because Julia uses Just-In-Time compilation, the application's code is automatically compiled while the application is running,
the compilation being triggered as needed, every time a piece of code that has not been already compiled is invoked. As such,
when an application is started, a large part of the codebase will need to be compiled. Understandably, this initial compilation
time, during which the application is unresponsive, can be a problem -- and even more so for a web application, where response
times are critical.

**It's important to understand that we're talking only about the initial response times, after the application is started,
when most of the codebase is JIT compiled. This is known in Julia parlance as "time to first plot". Once the initial
compilation is completed the application will run and respond very fast, which is a great feature for web applications which
can run for weeks and months between restarts.**

Thanks to the efforts of the Julia stewards and the community, time to first plot kept going down -- and work is being done
to allow ahead of time compilation for Julia apps. Meanwhile, one of the best solutions available today is to use
`PackageCompiler.jl` <https://github.com/JuliaLang/PackageCompiler.jl> to create a custom Julia library, called a sysimage,
that is optimized for our specific application, to reduce the startup latency of our app.

**Technically this process is about creating a custom sysimage. The details of this process are beyond the scope of this
chapter but you can read about it at <https://julialang.github.io/PackageCompiler.jl/stable/sysimages.html>**

### Extending our Docker flow to include sysimage creation

We'll use our `Dockerfile` to define the steps for generating the sysimage so that it's automatically created each time we
build our app in the docker container. Edit the `Dockerfile` and add the following lines of code. After
`RUN useradd --create-home --shell /bin/bash genie` add

```dockerfile
# C compiler for PackageCompiler
RUN apt-get update && apt-get install -y g++
```

This simply instructs Docker to install the `g++` compiler which is needed by `PackageCompiler.jl`.

Then after `RUN julia -e "using Pkg; Pkg.activate(\".\"); Pkg.instantiate(); Pkg.precompile(); "` add

```dockerfile
# Compile sysimage
RUN julia --project compiled/make.jl
```

This line runs a Julia script which handles the sysimage creation process. Let's set it up. Create the `compiled/` folder
inside the app's directory and inside it add the `make.jl` file with the following content:

```julia
using PackageCompiler

include("packages.jl")

PackageCompiler.create_sysimage(
  PACKAGES,
  sysimage_path = "compiled/sysimg.so",
  precompile_execution_file = "compiled/precompile.jl",
  cpu_target = PackageCompiler.default_app_cpu_target()
)
```

This file calls the `PackageCompiler.create_sysimage` function, passing the packages that need to be added to the sysimage,
the path to where the sysimage should be saved, and the path to the precompilation file. The precompilation file is
a file that runs the app to trigger the JIT compilation our code and store the compiled parts in the sysimage.

Now create the `compiled/packages.jl` file with the following content:

```julia
const PACKAGES = [
  "Genie",
  "HTTP",
  "Inflector",
  "Logging",
  "SearchLight",
  "SearchLightMySQL",
  "SwagUI",
  "SwaggerMarkdown"
```

Here we define a constant `PACKAGES` that lists the packages we want included in the custom sysimage. These are the specific
packages used by the app when running in production.

And the `compiled/precompile.jl` like this:

```julia
ENV["GENIE_ENV"] = "dev"

using Genie
Genie.loadapp(pwd())

import HTTP

@info "Hitting routes"
for r in Genie.Router.routes()
  try
    r.action()
  catch
  end
end

const PORT = 50515

try
  @info "Starting server"
  up(PORT)
catch
end

try
  @info "Making requests"
  HTTP.request("GET", "http://localhost:$PORT")
catch
end

try
  @info "Stopping server"
  Genie.Server.down!()
catch
end
```

This is a simple script that invokes the route handlers in the "Hitting routes" section, before starting the server, making
a request to the home page and then stopping the server.

Next, as our application will use the custom sysimage, we must configure it to load it. For this, we'll edit the `bin/server`
file to add the `--sysimage` option, pointing to the location of our custom `sysimage` file. Make the file look like this:

```bash
julia --color=yes --depwarn=no --project=@. --sysimage=compiled/sysimg.so -q -i -- $(dirname $0)/../bootstrap.jl -s=true "$@"
```

Finally, going back to our app's Julia REPL, we'll need to add `PackageCompiler.jl` as a dependency:

```julia
(GenieTodoMVC) pkg> add PackageCompiler
```

If you want, you can now run build in Docker to make sure that everything is right (but beware that the sysimage generation
step can take quite a long time, depending on the performance of your computer).

### Deploying our optimized app on Heroku

In the last part of the chapter let's see how to deploy our containerized application to another hosting provider: Heroku.
Heroku has less features compared to AWS and can be more expensive to host applications there -- however, it is much easier
to set up and configure, providing a friendly UI for common tasks such as setting up an SSL certificate or configuring a
custom domain name. Another good part is that it provides smalls servers for free.

If you don't have an account already, start by creating a free Heroku account by visiting <https://www.heroku.com>.

Genie greatly simplifies Heroku deployments thanks to the `GenieDeployHeroku.jl` package, so let's add it:

```julia
(GenieTodoMVC) pkg> add GenieDeployHeroku
```

The package uses the Heroku CLI, which needs to be installed manually. Follow the instructions for your operating system
from <https://devcenter.heroku.com/articles/heroku-cli#install-the-heroku-cli>. Once the CLI is installed, in the app's
Julia REPL run:

```julia
julia> GenieDeployHeroku.login()
```

Follow the instructions to login to your Heroku account.

Once logged in we can create a new app instance on Heroku to host our application, with:

```julia
julia> GenieDeployHeroku.createapp("<name of the app>")
```

Now we're ready to build our container:

```julia
julia> GenieDeployHeroku.push("<name of the app>")
```

This will trigger the Docker build process, which will also include the sysimage create step.

When finished (this can take a long time -- even half an hour or more, depending on the performance of your computer), we can
release the application in production.

But before we do that, remember, we need to configure the database connection. Heroku offers less control over the server
environment, so we can't open an SSH session and run docker manually. However, similar features are offered by Heroku using
its web UI. Go to <heroku.com> and check your app's list: <https://dashboard.heroku.com/apps>. You should see there the newly
created app. Click on it to see its details. Go to the "Settings" tab and click on "Reveal Config Vars". This is the place
where we can add environment variables that will be passed to the docker process. Go ahead and add three config vars:
`SEARCHLIGHT_HOST`, `SEARCHLIGHT_USERNAME`, and `SEARCHLIGHT_PASSWORD` -- and for the values set the RDS database endpoint for the
host, and the master username and password for the other two. As you can see we will be using the same database as before --
but if you want to try for yourself, Heroku also provides a similar managed cloud database service.

Now we can deploy the app in production:

```julia
julia> GenieDeployHeroku.release("<name of the app>")
```

And finally, we can open the browser to navigate to our live app using:

```julia
julia> GenieDeployHeroku.open("<name of the app>")
```

**If you want to run an application that uses a custom sysimage on AWS, beware that the compilation part of the Docker build
process needs quite a lot of resources. In my tests, building the docker container with custom sysimage failed on a 4 GB `t2.medium` EC2
instance, and was successful on a 8 GB `t2.large` instance.**

## Conclusions

Containerized deployments using Docker are some of the most commonly used application deployment strategies today. Virtually
all the modern hosting platforms provide support for Docker deployment, from basic to very complex configurations that use
container orchestration frameworks like Docker Compose or Kubernetes.

Docker deployments are very useful because using the Dockerfile we can implement complex build and release workflow that
will run the same everywhere. This is especially useful for Genie applications where we want to take advantage of
environments and apply optimisation techniques, including the building of custom sysimage.

Custom sysimages help by greatly reducing compilation and thus compilation time, decreasing the
so called "time to first plot" -- and also reduces memory and CPU needs for the app, allowing us to deploy on small
servers, like the free Heroku ones. Finally, the Genie package ecosystem greatly simplifies the productionizing of Genie web
apps through easy to use deployment plugins like `GenieDeployDocker` and `GenieDeployHeroku`.
