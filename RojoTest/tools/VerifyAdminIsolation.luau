-- Run in Edit. Uses plain mock state; never touches player saves or currency.
local source = game.ServerScriptService.Server.AdminService:Clone()
source.Name = "AdminPersistenceCheck"
source.Parent = game.ServerScriptService.Server
local Service = require(source)
source:Destroy()
local Access = require(game.ServerScriptService.Server.AdminAccess)
local H = game:GetService("HttpService")
local owner = { UserId = 11792184677 }
local original = {
	wins = 17,
	skill = 23,
	rebirths = 1,
	pets = {},
	equipped = {},
	world = 1,
	stone = "Pebble",
	stones = { Pebble = true },
	trail = "None",
	trails = { None = true },
	perks = {},
	receipts = {},
	settings = {},
}
local gifts = { [2] = true }
local state = {
	data = original,
	gifts = gifts,
	joined = 12,
	sessionOnly = false,
	saving = false,
	busyUntil = 0,
	-- The service counts the version of the inventory, the mock has to carry it.
	inventoryVersion = 0,
}
local states = { [owner] = state }
local saves = 0
local context = {
	save = function(player)
		assert(states[player].data == original, "Grants must keep the persistent data table")
		saves += 1
		return true
	end,
	equipBest = function(s)
		s.inventoryVersion += 1
	end,
	states = states,
	stopTraining = function() end,
	rootFor = function()
		return nil
	end,
	arenaFor = function()
		return workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("World1")
	end,
	publish = function() end,
	effect = { FireClient = function() end },
}
-- The mock carries the same fields as the real service: without the
-- counters the rate limiter of the handle path has nothing to count, and
-- without the secrets the log of the service has nothing to mask.
local service = setmetatable({ context = context, logs = {}, last = {}, counters = {}, secrets = {} }, Service)
local before = H:JSONEncode(original)
assert(Access.isAuthorized(owner.UserId))
assert(not Access.isAuthorized(0) and not Access.isAuthorized("11792184677"))
-- The handle path of an authorised player: the command is counted by the
-- rate limiter and the answer carries the message of the service.
local answered = service:handle(owner, "Status")
assert(answered.ok, "The admin service must answer an authorised player")
assert(answered.message == "Панель готова.", "Unexpected message of the admin status")
assert(
	service.counters[owner] and service.counters[owner].count == 1,
	"The rate limiter must count the command of the player"
)
assert(not service:handle({ UserId = 1234 }, "SetStat", { key = "wins", amount = 99 }).ok)
assert(H:JSONEncode(original) == before and saves == 0)
service:dispatch(owner, "SetStat", { key = "wins", amount = 1000000 })
assert(state.data == original and original.wins == 1000000 and saves == 1)
service:dispatch(owner, "GivePet", require(game.ReplicatedStorage.Shared.GameConfig).AdminPet.id)
assert(#original.pets == 1 and saves == 2 and state.inventoryVersion == 1)
service:dispatch(owner, "Stone", "Pebble")
service:dispatch(owner, "Trail", "None")
assert(saves == 4 and original.stones.Pebble and original.trails.None)
original.receipts.fakeReceipt = true
for _, command in { "Begin", "End", "Reset" } do
	assert(not pcall(service.dispatch, service, owner, command), "Retired test commands must be rejected")
end
assert(original.receipts.fakeReceipt and saves == 4)
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = math.huge }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = 0 / 0 }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "wins", amount = -1 }))
assert(not pcall(service.dispatch, service, owner, "SetStat", { key = "adminOriginal", amount = 1 }))
assert(state.data == original and state.gifts == gifts and state.joined == 12)
assert(saves == 4, "Rejected commands must not save")
return {
	unauthorizedDenied = true,
	directPersistentGrants = true,
	immediateSave = true,
	invalidStatsDenied = true,
	retiredCommandsDenied = true,
	receiptsPreserved = true,
}
