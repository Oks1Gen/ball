-- Read-only Edit simulation: no PivotTo, bone writes, or landscape rebuilds.
assert(game:GetService("RunService"):IsStudio() and not game:GetService("RunService"):IsRunning())
_G.OceanWildlifeStress = { running = true }
task.spawn(function()
	local source = game.StarterPlayer.StarterPlayerScripts.Client.Controllers.OceanWildlifeController
	local module = source:Clone()
	module.Parent = source.Parent
	local C = require(module)
	local shared = game.ReplicatedStorage:WaitForChild("Shared")
	local coreFolder = shared:WaitForChild("Core")
	local core = coreFolder:WaitForChild("OceanSwimming"):Clone()
	core.Parent = coreFolder
	C:Init({ swim = require(core) })
	C:Scan(workspace.Map.World2)
	local first = {}
	for _, g in C.groups do
		for _, a in g.members do
			first[a] = a.offset
		end
	end
	local minGap, maxRatio = math.huge, 0
	local ok, err = pcall(function()
		for frame = 1, 1800 do
			for _, g in C.groups do
				for _ = 1, g.motionRate do
					C:Simulate(g, 1 / (30 * g.motionRate))
				end
				for i, a in g.members do
					if #g.members > 1 then
						maxRatio = math.max(maxRatio, a.offset.Magnitude / g.memberLimit)
					end
					for j = i + 1, #g.members do
						local b = g.members[j]
						local gap = (a.offset - b.offset).Magnitude - a.radius - b.radius
						minGap = math.min(minGap, gap)
						assert(gap >= 0.249, g.model.Name .. ": fish overlap")
					end
				end
			end
			if frame % 30 == 0 then
				task.wait()
			end
		end
	end)
	local changed = 0
	for a, p in first do
		if (a.offset - p).Magnitude > 0.5 then
			changed += 1
		end
	end
	_G.OceanWildlifeStress = {
		running = false,
		ok = ok,
		error = if not ok then tostring(err) else nil,
		groups = #C.groups,
		seconds = 60,
		minGap = minGap,
		maxEnvelopeRatio = maxRatio,
		membersReshuffled = changed,
		steps = C.stats.steps,
		blockedSteps = C.stats.blockedSteps,
	}
	module:Destroy()
	core:Destroy()
end)
return "Full-world simulation started"
