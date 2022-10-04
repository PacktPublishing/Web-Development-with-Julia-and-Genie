using Genie

using GenieAuthentication
import ..Main.UserApp.AuthenticationController
import ..Main.UserApp.Users
import SearchLight: findone

export current_user
export current_user_id

current_user() = findone(Users.User, id = get_authentication())
current_user_id() = current_user() === nothing ? nothing : current_user().id

route("/login", AuthenticationController.show_login, named = :show_login)
route("/login", AuthenticationController.login, method = POST, named = :login)
route("/success", AuthenticationController.success, method = GET, named = :success)
route("/logout", AuthenticationController.logout, named=:logout)

route("/register", AuthenticationController.show_register, named = :show_register)
route("/register", AuthenticationController.register, method=POST, named=:register)

# basic auth
basicauth(req, res, params) = begin
  if GenieAuthentication.isbasicauthrequest(params)
    try
      user = findone(Users.User, username = params[:username], password = Users.hash_password(params[:password]))
      user === nothing && return req, res, params
      login(user, authenticate(user.id, GenieAuthentication.GenieSession.session(params)))
    catch _
    end
  end

  req, res, params
end
basicauth in Genie.Router.pre_match_hooks || push!(Genie.Router.pre_match_hooks, basicauth)