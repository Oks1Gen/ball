-- Run through Studio MCP in Edit mode after Rojo sync; no profile or network actions.
local Client = game.StarterPlayer.StarterPlayerScripts.Client
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Effects = require(Client.BallEffects)
local Themes = require(Client.TrailThemes)
local camera = assert(workspace.CurrentCamera)
local position = camera.CFrame.Position + camera.CFrame.LookVector * 12
-- Red's flight and kick use the built-in flame; its Volcanic impact uses the
-- library fire flipbook. No other family may show either.
local FLAME = "fire_main"
local LIBRARY_FIRE = "13818306392"
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
local function hasTexture(root, needle)
	for _, item in root:GetDescendants() do
		if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
			if string.find(item.Texture, needle, 1, true) then
				return true
			end
		end
	end
	return false
end
local function checkCosmetic(root)
	for _, part in root:GetDescendants() do
		if part:IsA("BasePart") then
			check(not part.CanCollide and not part.CanTouch and not part.CanQuery, "Cosmetic physics")
		end
	end
end
local ids = {}
for _, trail in Config.Trails do
	table.insert(ids, trail.id)
	check(trail.id == "None" or trail.id == "Red" or Themes[trail.id] ~= nil, "Every trail has a theme: " .. trail.id)
end
for _, id in ids do
	local name = id == "Red" and "BallFireFlight" or "Ball" .. id .. "Flight"
	check(not workspace:FindFirstChild(name), "Run verifier without live flights")
	local flight = Effects.flight(id)
	flight.update(position, Vector3.new(0, 2, -40), true, 0.5)
	local rig = workspace:FindFirstChild(name)
	if id == "None" then
		check(rig == nil, "None has no cosmetic flight")
	else
		check(rig ~= nil and rig:GetAttribute("TrailStyle") == id, "Selected family owns the flight: " .. id)
		check(hasTexture(rig, FLAME) == (id == "Red"), "Flame belongs only to Red: " .. id)
		checkCosmetic(rig)
		-- A slow shot keeps the look players liked: no speed extras at pace 0.
		local comet = rig:FindFirstChild("CometTail")
		check(comet and comet:IsA("Beam") and not comet.Enabled, "No comet on a slow shot: " .. id)
		-- Fast shot: comet and locked streaks, per-distance fill, carried burst, pitch skid.
		local before = #rig:GetDescendants()
		flight.update(position - Vector3.zAxis * 5, Vector3.new(0, 2, -280), true, 0.5, 1)
		flight.update(position - Vector3.zAxis * 10, Vector3.new(0, 2, -280), true, 0.5, 1)
		check(comet.Enabled, "Comet on a fast shot: " .. id)
		local streaks = rig:FindFirstChild("CometStreaks", true) :: ParticleEmitter
		check(streaks.Enabled and streaks.Rate > 0 and streaks.LockedToPart, "Streaks ride with the ball: " .. id)
		flight.contact(position - Vector3.new(0, 2, 10), Vector3.yAxis, 1, 1)
		local carried = 0
		for _, item in rig:GetDescendants() do
			if item:IsA("ParticleEmitter") and item.Name ~= "CometStreaks" and item.LockedToPart then
				carried += 1
			end
		end
		check(carried > 0 and #rig:GetDescendants() > before, "Bounce burst carried by the ball: " .. id)
		flight.update(position - Vector3.zAxis * 14, Vector3.new(0, 2, -280), true, 0.5, 1)
		local wake = rig:FindFirstChild("PitchWake") :: Trail
		check(wake.Enabled and not wake.FaceCamera, "Skid lies on the pitch after a bounce: " .. id)
		check(
			math.abs(wake.Attachment0.WorldPosition.Y - (position.Y - 2 + 0.06)) < 0.01,
			"Skid at pitch height: " .. id
		)
		flight.update(position, Vector3.new(0, 2, -40), false, 0.5)
		for _, item in rig:GetDescendants() do
			if item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
				check(not item.Enabled, "Effects off disables every emitter: " .. id)
			end
		end
		flight.update(position + Vector3.xAxis, Vector3.new(0, 2, -40), true, 0.5)
	end
	flight.stop()
	flight.destroy()
	flight.destroy()
	check(not workspace:FindFirstChild(name), "Idempotent cleanup")
	-- Earthquake drops pebbles next to the flight, outside the rig.
	for _, item in workspace:GetChildren() do
		if item.Name == "QuakeRock" then
			check(id == "Earthquake", "Pebbles belong only to Earthquake")
			check(not item.CanCollide and not item.CanTouch and not item.CanQuery, "Cosmetic pebbles")
			item:Destroy()
		end
	end
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
			check(item:GetAttribute("TrailStyle") == id, "Selected family owns the burst: " .. id)
			check(id == "Red" or not hasTexture(item, FLAME), "No flame in another family burst: " .. id)
			check(id == "Red" or not hasTexture(item, LIBRARY_FIRE), "No fire in another family impact: " .. id)
			if id ~= "None" and item:GetAttribute("Surface") ~= nil then
				check(item:FindFirstChild(id .. "Impact") ~= nil, "Themed impact on bounce: " .. id)
			end
			checkCosmetic(item)
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
check(count == 6, "Themed family flight budget")
for _, f in flights do
	f.destroy()
end
return { assertions = assertions, families = #ids, profilesChanged = false }
