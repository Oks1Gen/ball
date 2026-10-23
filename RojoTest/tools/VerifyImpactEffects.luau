-- Run in Studio Edit through MCP after Rojo sync. Temporary geometry is removed.
local Effects = require(game.StarterPlayer.StarterPlayerScripts.Client.BallEffects)
local Impact = require(game.StarterPlayer.StarterPlayerScripts.Client.BallImpactEffects)
local camera = assert(workspace.CurrentCamera)
local origin = camera.CFrame.Position + Vector3.new(0, 40, 0)
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
local expected =
	{ Red = "HotCinder", White = "WindStreak", Blue = "IceImpactShard", Purple = "ImpactRune", Rainbow = "RainbowStar" }
local host = Instance.new("Folder")
host.Name = "ImpactVerification"
host.Parent = workspace
local ok, result = pcall(function()
	for _, id in { "Red", "White", "Blue", "Purple", "Rainbow" } do
		for _, strength in { 0.25, 1.2 } do
			local batch = Instance.new("Folder")
			batch.Parent = host
			Impact.bounce(batch, origin, Vector3.new(0.2, 1, 0).Unit, id, strength)
			local count, stars = 0, 0
			local colors = {}
			for _, item in batch:GetDescendants() do
				if item:IsA("BasePart") then
					check(
						item.Anchored and not item.CanCollide and not item.CanTouch and not item.CanQuery,
						"No gameplay physics"
					)
					if item.Name == expected[id] then
						count += 1
					end
				end
				if item:IsA("TextLabel") then
					check(item.Text == "★", "Actual star silhouette")
					colors[tostring(item.TextColor3)] = true
					stars += 1
				end
				if item:IsA("ParticleEmitter") and string.find(item.Texture, "fire_main", 1, true) then
					check(id == "Red", "Fire only Red")
				end
			end
			check(count == (strength < 0.5 and 4 or 8), "Weaker impacts use fewer accents")
			if id == "Rainbow" then
				local colorCount = 0
				for _ in colors do
					colorCount += 1
				end
				check(stars == count and colorCount == count, "Rainbow stars have distinct colors")
			end
			batch:Destroy()
		end
	end
	local ground = Instance.new("Part")
	ground.Size = Vector3.new(20, 1, 20)
	ground.CFrame = CFrame.new(origin)
	ground.Anchored = true
	ground.Parent = host
	for _, mode in { "Dust", "Water" } do
		local position = origin + (mode == "Dust" and Vector3.yAxis * 0.5 or Vector3.new(50, 0, 0))
		local before = {}
		for _, item in workspace:GetChildren() do
			before[item] = true
		end
		Effects.bounce(position, position.Y - 1, 1, 0.7, "Rainbow")
		local found = false
		for _, item in workspace:GetChildren() do
			if not before[item] and item.Name == "BallEffectBurst" then
				check(item:GetAttribute("Surface") == mode, "Correct surface " .. mode)
				check(item:FindFirstChild("RainbowImpact") ~= nil, "Theme and surface both exist")
				if mode == "Dust" then
					check(item:FindFirstChild("ToonDustPuff", true) ~= nil, "Dust preserved")
				end
				found = true
				item:Destroy()
			end
		end
		check(found, "Surface burst created")
		task.wait()
	end
	return { assertions = assertions, families = 5, surfaces = 2 }
end)
host:Destroy()
assert(ok, tostring(result))
return result
