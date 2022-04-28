using Dance.Router


function hello(headers::Dict{String, String}) :: String
    return "Hello World"
end

route("/", hello; method=GET, endpoint=EP_HTML)
