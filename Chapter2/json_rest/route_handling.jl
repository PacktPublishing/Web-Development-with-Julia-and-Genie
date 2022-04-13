using HTTP, Sockets

todos = """
ToDo 1: Getting groceries
ToDo 2: Visiting my therapist
ToDo 3: Getting a haircut
"""
const HOST = ip"127.0.0.1"
const PORT = 9999
const ROUTER = HTTP.Router()                    # 1
HTTP.@register(ROUTER, "GET", "/*", req -> HTTP.Response(200, "Hello"))  # 2
HTTP.@register(ROUTER, "GET", "/list_todos", req -> HTTP.Response(200, todos))
HTTP.serve(ROUTER, HOST, PORT)                  # 3