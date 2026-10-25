--!strict
local Log = {}

local function literal(value: string): string
	return (value:gsub("(%W)", "%%%1"))
end

function Log.redact(message: string, userId: number?, key: string?): string
	local result = message
	if key and key ~= "" then
		local embeddedId = key:match("^Player_(-?%d+)$") or key:match("^u_(-?%d+)$")
		result = result:gsub(literal(key), "<key>")
		if embeddedId then
			result = result:gsub(literal(embeddedId), "<user>")
		end
	end
	result = result:gsub("Player_%-?%d+", "<key>"):gsub("u_%-?%d+", "<key>")
	if userId then
		result = result:gsub(literal(tostring(userId)), "<user>")
	end
	return result
end

return Log
