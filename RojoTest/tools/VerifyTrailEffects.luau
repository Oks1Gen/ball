-- Run through Studio MCP in Edit mode after Rojo sync; no profile or network actions.
local Effects = require(game.StarterPlayer.StarterPlayerScripts.Client.BallEffects)
local camera = assert(workspace.CurrentCamera)
local position = camera.CFrame.Position + camera.CFrame.LookVector * 12
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
local function hasFire(root)
	for _, item in root:GetDescendants() do
		if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
			if string.find(item.Texture, "fire_main", 1, true) then
				return true
			end
		end
	end
	return false
end
for _, id in { "None", "White", "Red", "Blue", "Purple", "Rainbow" } do
	local name = id == "Red" and "BallFireFlight" or "Ball" .. id .. "Flight"
	check(not workspace:FindFirstChild(name), "Run verifier without live flights")
	local flight = Effects.flight(id)
	flight.update(position, Vector3.new(0, 2, -40), true, 0.5)
	local rig = workspace:FindFirstChild(name)
	if id == "None" then
		check(rig == nil, "None has no cosmetic flight")
	else
		check(rig ~= nil and rig:GetAttribute("TrailStyle") == id, "Selected family owns the flight")
		check(hasFire(rig) == (id == "Red"), "Fire belongs only to Red")
		for _, part in rig:GetDescendants() do
			if part:IsA("BasePart") then
				check(not part.CanCollide and not part.CanTouch and not part.CanQuery, "Cosmetic physics")
			end
		end
		flight.update(position, Vector3.new(0, 2, -40), false, 0.5)
		for _, item in rig:GetDescendants() do
			if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
				check(not item.Enabled, "Effects off disables every emitter")
			end
		end
		flight.update(position + Vector3.xAxis, Vector3.new(0, 2, -40), true, 0.5)
	end
	flight.stop()
	flight.destroy()
	flight.destroy()
	check(not workspace:FindFirstChild(name), "Idempotent cleanup")
	local before = {}
	for _, item in workspace:GetChildren() do
		before[item] = true
	end
	Effects.kick(position, -Vector3.zAxis, Color3.new(1, 1, 1), 0.5, id)
	Effects.bounce(position, position.Y - 2, 1, 0.5, id)
	Effects.bounce(position, position.Y - 2, 8, 0, id)
	local bursts = 0
	for _, item in workspace:GetChildren() do
		if not before[item] and item.Name == "BallEffectBurst" then
			check(item:GetAttribute("TrailStyle") == id, "Selected family owns the impact")
			check(hasFire(item) == (id == "Red"), "No fire in another family impact")
			item:Destroy()
			bursts += 1
		end
	end
	check(bursts == 3, "Kick and strong/weak bounces created")
	-- Studio defers Destroying callbacks; allow the burst/flight budget to release.
	task.wait()
end
local flights = {}
for i = 1, 8 do
	local f = Effects.flight("White")
	f.update(position + Vector3.xAxis * i, -Vector3.zAxis * 40, true, 0.5)
	table.insert(flights, f)
end
local count = 0
for _, item in workspace:GetChildren() do
	if item.Name == "BallWhiteFlight" then
		count += 1
	end
end
check(count == 6, "Non-fire family flight budget")
for _, f in flights do
	f.destroy()
end
return { assertions = assertions, families = 6, profilesChanged = false }
