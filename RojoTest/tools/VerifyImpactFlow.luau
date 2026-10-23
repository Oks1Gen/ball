-- Studio MCP Client in Play. Local decorative shots only, no server requests.
local Flight = require(game.Players.LocalPlayer.PlayerScripts.Client.FlightVisuals)
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Motion = require(Shared.ShotMotion)
local center = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * 12
local report = {}
for i, id in { "None", "White", "Red", "Blue", "Purple", "Rainbow" } do
	local hits = {}
	local handle = Flight.start({
		userId = "ImpactQA" .. i,
		trail = id,
		stone = "Pebble",
		duration = 0.5,
		distance = 15,
		startedAt = workspace:GetServerTimeNow() - Config.KickWindup,
		startPosition = center,
		direction = -Vector3.zAxis,
		world = 1,
	}, {
		me = false,
		effects = function()
			return true
		end,
		ripple = function() end,
		bounce = function(position, style, contact, intensity)
			assert(style == id, "Wrong audio family")
			assert(typeof(position) == "Vector3" and intensity >= 0, "Invalid impact payload")
			assert(not hits[contact], "Duplicate audio contact")
			hits[contact] = true
		end,
	})
	task.wait(0.65)
	local count = 0
	for _ in hits do
		count += 1
	end
	handle.cancel()
	assert(count == Motion.BounceCount, "Missing contacts: " .. id .. " " .. count)
	table.insert(report, { id = id, contacts = count })
	task.wait()
end
local stale, ripples = 0, 0
local handle = Flight.start({
	userId = "ImpactQALate",
	trail = "Red",
	stone = "Pebble",
	duration = 0.5,
	distance = 15,
	startedAt = workspace:GetServerTimeNow() - Config.KickWindup - 2,
	startPosition = center,
	direction = -Vector3.zAxis,
	world = 1,
}, {
	me = false,
	effects = function()
		return false
	end,
	ripple = function()
		ripples += 1
	end,
	bounce = function()
		stale += 1
	end,
})
task.wait(0.1)
handle.cancel()
assert(stale == 0 and ripples == 0, "Old contacts replayed")
return { families = report, lateSounds = stale, lateRipples = ripples, profileWrites = 0 }
