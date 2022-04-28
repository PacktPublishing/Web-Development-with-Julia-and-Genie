# add JSExpr  # in package mode
using JSExpr

# using the @js macro:
@js function cube(arg)
  return arg * arg * arg
end
# JSString("function cube(arg){return (arg*arg*arg)}")

# showing interpolation:
var1 = 108
callback = @js n -> n + $var1
# JSString("(function (n){return (n+108)})")

# using the js" " macro:
js"var 1 is: $var1"
# JSString("var 1 is: 108")

message = "hi"
fun1 = js"
       function () {
           alert($message) // you can interpolate Julia variables!
       }
       "
# JSString("function () {\n    alert(\"hi\") // you can interpolate Julia variables!\n}\n")