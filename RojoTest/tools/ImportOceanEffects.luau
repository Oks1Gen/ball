-- Studio Edit. Restore VfxForge-authored templates from LocationKit/effects.json.
return function(data)
	assert(not game:GetService("RunService"):IsRunning(), "Import in Edit")
	local ocean = game.ServerStorage.Assets.OceanDepths
	local pack = ocean:FindFirstChild("Effects") or Instance.new("Folder")
	pack.Name = "Effects"
	pack.Parent = ocean
	local function numbers(points)
		local keys = {}
		for _, v in points do
			table.insert(keys, NumberSequenceKeypoint.new(v[1], v[2], v[3]))
		end
		return NumberSequence.new(keys)
	end
	local function colors(points)
		local keys = {}
		for _, v in points do
			table.insert(keys, ColorSequenceKeypoint.new(v[1], Color3.new(v[2], v[3], v[4])))
		end
		return ColorSequence.new(keys)
	end
	for _, recipe in data do
		local carrier = Instance.new("Part")
		carrier.Name = recipe.name
		carrier.Size = Vector3.one
		carrier.Anchored = true
		carrier.Transparency = 1
		carrier.CanCollide = false
		carrier.CanQuery = false
		carrier.CanTouch = false
		carrier:SetAttribute("PartRole", "EffectAnchor")
		carrier:SetAttribute("Purpose", "Ocean Depths " .. recipe.name)
		local instances = { [recipe.name] = carrier }
		for _, spec in recipe.descendants do
			local instance = Instance.new(spec.class)
			instance.Name = spec.name
			instances[spec.name] = instance
		end
		for _, spec in recipe.descendants do
			local n = instances[spec.name]
			n.Parent = instances[spec.parent]
			if spec.class == "Attachment" then
				n.Position = Vector3.new(table.unpack(spec.position))
			elseif spec.class == "ParticleEmitter" or spec.class == "Beam" then
				n.Texture = spec.texture
				n.Color = colors(spec.color)
				n.Transparency = numbers(spec.transparency)
				n.LightEmission = spec.lightEmission
				n.LightInfluence = spec.lightInfluence
				if spec.class == "ParticleEmitter" then
					n.Rate = spec.rate
					n.Lifetime = NumberRange.new(table.unpack(spec.lifetime))
					n.Speed = NumberRange.new(table.unpack(spec.speed))
					n.SpreadAngle = Vector2.new(table.unpack(spec.spread))
					n.Acceleration = Vector3.new(table.unpack(spec.acceleration))
					n.Size = numbers(spec.size)
					n.FlipbookLayout = Enum.ParticleFlipbookLayout[spec.flipbookLayout]
					n.FlipbookMode = Enum.ParticleFlipbookMode[spec.flipbookMode]
					n.FlipbookFramerate = NumberRange.new(table.unpack(spec.flipbookFramerate))
				else
					n.Width0 = spec.width0
					n.Width1 = spec.width1
					n.FaceCamera = spec.faceCamera
					n.Segments = spec.segments
					n.Attachment0 = instances[spec.attachment0]
					n.Attachment1 = instances[spec.attachment1]
				end
			end
		end
		local old = pack:FindFirstChild(recipe.name)
		if old then
			old:Destroy()
		end
		carrier.Parent = pack
	end
	return #data
end
