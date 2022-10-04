module AuthenticationController

using Genie, Genie.Renderer, Genie.Renderer.Html
using SearchLight
using Logging

using ..Main.UserApp.Users
using ..Main.UserApp.GenieAuthenticationViewHelper

using GenieAuthentication
using GenieAuthentication.GenieSession
using GenieAuthentication.GenieSession.Flash
using GenieAuthentication.GenieSessionFileSession


function show_login()
  html(:authentication, :login, context = @__MODULE__)
end

function login()
  try
    user = findone(User, username = params(:username), password = Users.hash_password(params(:password)))
    authenticate(user.id, GenieSession.session(params()))

    redirect(:success)
  catch ex
    flash("Authentication failed! ")

    redirect(:show_login)
  end
end

function success()
  html(:authentication, :success, context = @__MODULE__)
end

function logout()
  deauthenticate(GenieSession.session(params()))

  flash("Good bye! ")

  redirect(:show_login)
end

function show_register()
  html(:authentication, :register, context = @__MODULE__)
end

function register()
  try
    user = User(username  = params(:username),
                password  = params(:password) |> Users.hash_password,
                name      = params(:name),
                email     = params(:email)) |> save!

    authenticate(user.id, GenieSession.session(params()))

    redirect("/?success=Registration successful")
  catch ex
    @error ex

    if hasfield(typeof(ex), :msg)
      flash(ex.msg)
    else
      flash(string(ex))
    end

    redirect(:show_register)
  end
end

end