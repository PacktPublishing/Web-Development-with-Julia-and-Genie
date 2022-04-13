using Sockets

# IP addresses:
addr = ip"185.43.124.6"    # this uses the @ip_str macro  
typeof(addr)               # IPv4

# URIs:
req = HTTP.Request(         
"GET", 		                         
"https://www.google.com/search?q=mammoth",                   
["Content-Type" => "text/plain"],                    
"Hi there!"                        
)

uri = URI(HTTP.uri(req))  # URI("https://www.google.com/search?q=mammoth")
uri.scheme # "https"
uri.host   # "www.google.com"
uri.path   # "/search"
uri.query  # "q=mammoth"
queryparams(uri) # Dict{String, String} with 1 entry: "q" => "mammoth"
