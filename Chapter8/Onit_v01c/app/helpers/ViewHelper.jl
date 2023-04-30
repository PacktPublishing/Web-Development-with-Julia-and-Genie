module ViewHelper

using Genie

function active(filter::String = "")
  params(:filter, "") == filter ? "active" : ""
end

end