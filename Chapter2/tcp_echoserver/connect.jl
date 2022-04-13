#start these commands in the REPL:
using Sockets
connect("julialang.org", 80)
# TCPSocket(Base.Libc.WindowsRawSocket(0x00000000000003ec) open, 0 bytes waiting)
getaddrinfo("julialang.org")
# ip"151.101.130.49"