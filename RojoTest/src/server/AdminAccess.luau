-- Keep authorization on the server. Usernames and client attributes are not trusted.
local Access={}
local owners={[11792184677]=true}
function Access.isAuthorized(userId)
	return type(userId)=="number" and owners[userId]==true
end
return Access
