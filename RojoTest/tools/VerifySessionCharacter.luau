-- Isolated lifecycle regressions. No real players, profiles, or scene objects change.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local sessionModule = game.ServerScriptService.Server.Gameplay.Session
local source = sessionModule.Source
local checks = 0
local function check(value, message)
	assert(value, message)
	checks += 1
end

local function signal()
	local callbacks = {}
	return {
		Connect = function(_, callback)
			table.insert(callbacks, callback)
		end,
		Fire = function(_, ...)
			for _, callback in callbacks do
				callback(...)
			end
		end,
	}
end

local function fixture(waitStage)
	local player = { Parent = true, CharacterAdded = signal(), SetAttribute = function() end }
	local calls = { stopped = 0, streamed = 0, published = 0 }
	local context = {
		states = {},
		Config = { CharacterWalkSpeed = 20 },
		friends = function()
			return 0
		end,
		claimPending = function() end,
		stopTraining = function()
			calls.stopped += 1
		end,
		publish = function()
			calls.published += 1
		end,
		FlightStreaming = {
			stop = function()
				calls.streamed += 1
			end,
		},
		LobbyRankings = {},
		Profiles = {
			Load = function()
				return {
					Data = { progress = {} },
					IsActive = function()
						return true
					end,
					OnAfterSave = signal(),
				}
			end,
			Attach = function() end,
		},
	}
	local function character()
		local hum = { Died = signal() }
		return {
			WaitForChild = function(_, name)
				return if name == "Humanoid" then hum else {}
			end,
			hum = hum,
		}
	end
	local current = character()
	local old = character()
	local ordinaryWait = old.WaitForChild
	old.WaitForChild = function(self, name)
		if name == waitStage then
			player.Character = current
			player.CharacterAdded:Fire(current)
			local state = context.states[player]
			state.kickTiming, state.busyUntil, state.blockedLane = "new timing", 99, 3
			calls.stopped, calls.streamed, calls.published = 0, 0, 0
		end
		return ordinaryWait(self, name)
	end
	local run = assert(loadstring(source))
	setfenv(
		run,
		setmetatable({
			Instance = {
				new = function()
					return {}
				end,
			},
			task = {
				spawn = function(callback, ...)
					callback(...)
				end,
			},
		}, { __index = getfenv() })
	)
	player.Character = old
	run().setup(context, player)
	return player, context, calls, old, current
end

for _, stage in { "HumanoidRootPart", "Humanoid" } do
	local player, context, calls = fixture(stage)
	local state = context.states[player]
	check(
		state.kickTiming == "new timing" and state.busyUntil == 99 and state.blockedLane == 3,
		"Stale wait cannot reset new state: " .. stage
	)
	check(calls.stopped == 0 and calls.streamed == 0, "Stale wait cannot stop new activity: " .. stage)
end

local player, context, calls, old, current = fixture(nil)
player.Character = current
player.CharacterAdded:Fire(current)
local state = context.states[player]
state.kickTiming, state.busyUntil = "new timing", 99
calls.stopped, calls.streamed = 0, 0
old.hum.Died:Fire()
check(state.kickTiming == "new timing" and state.busyUntil == 99, "Old death cannot reset current state")
check(calls.stopped == 0 and calls.streamed == 0, "Old death cannot stop current activity")
player.CharacterAdded:Fire(old)
check(calls.stopped == 0 and calls.streamed == 0, "Stale CharacterAdded cannot stop current activity")
current.hum.Died:Fire()
check(state.kickTiming == nil and calls.stopped == 1 and calls.streamed == 1, "Current death still stops activity")
return { checks = checks, isolated = true }
