using Sockets

# IP addresses:
addr = ip"185.43.124.6"    # this uses the @ip_str macro  
typeof(addr)               # IPv4

connect("julialang.org", 80)
# TCPSocket(Base.Libc.WindowsRawSocket(0x00000000000003ec) open, 0 bytes waiting)
getaddrinfo("julialang.org")
# ip"151.101.130.49"

# Installing URIs
# (@v1.8) pkg> add URIs, HTTP
using URIs, HTTP

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
