-- Studio Edit: return portable, typed native model geometry; never changes Workspace.
return function(world: Model)
	assert(not game:GetService("RunService"):IsRunning(), "Export in Edit")
	local function value(v)
		local kind = typeof(v)
		if kind == "CFrame" then
			return { type = kind, value = { v:GetComponents() } }
		end
		if kind == "Vector3" or kind == "Color3" then
			return { type = kind, value = if kind == "Color3" then { v.R, v.G, v.B } else { v.X, v.Y, v.Z } }
		end
		if kind == "Vector2" then
			return { type = kind, value = { v.X, v.Y } }
		end
		if kind == "EnumItem" then
			return { type = kind, enum = tostring(v.EnumType):gsub("Enum%.", ""), value = v.Name }
		end
		return v
	end
	local function node(instance)
		if
			not (
				instance:IsA("Model")
				or instance:IsA("Folder")
				or instance:IsA("Part")
				or instance:IsA("WedgePart")
				or instance:IsA("Texture")
				or instance:IsA("SpecialMesh")
			)
		then
			return nil
		end
		local result =
			{ class = instance.ClassName, name = instance.Name, properties = {}, attributes = {}, children = {} }
		local keys = {}
		if instance:IsA("Model") then
			keys = { "WorldPivot" }
		elseif instance:IsA("BasePart") then
			keys = {
				"CFrame",
				"Size",
				"Color",
				"Material",
				"Transparency",
				"Reflectance",
				"Anchored",
				"CanCollide",
				"CanTouch",
				"CanQuery",
				"CastShadow",
				"TopSurface",
				"BottomSurface",
			}
			if instance:IsA("Part") then
				table.insert(keys, "Shape")
			end
		elseif instance:IsA("Texture") then
			keys = {
				"Texture",
				"Face",
				"StudsPerTileU",
				"StudsPerTileV",
				"OffsetStudsU",
				"OffsetStudsV",
				"Transparency",
				"Color3",
			}
		elseif instance:IsA("SpecialMesh") then
			keys = { "MeshType", "Scale", "Offset", "MeshId", "TextureId", "VertexColor" }
		end
		for _, key in keys do
			result.properties[key] = value(instance[key])
		end
		for key, v in instance:GetAttributes() do
			result.attributes[key] = value(v)
		end
		for _, child in instance:GetChildren() do
			local encoded = node(child)
			if encoded then
				table.insert(result.children, encoded)
			end
		end
		return result
	end
	local storage = game.ServerStorage.Assets.OceanDepths
	local pack = storage:FindFirstChild("Architecture") or Instance.new("Folder")
	pack.Name = "Architecture"
	pack.Parent = storage
	local results = {}
	for _, choice in
		{
			{ 3, "SandfilledGalleon" },
			{ 3, "HalfBuriedAnchor" },
			{ 4, "SandstoneColumn" },
			{ 4, "SmallSteppedTemple" },
			{ 4, "DistantCityGateway" },
			{ 6, "HydrothermalChimney" },
			{ 6, "TubeWormColony" },
		}
	do
		local source = world.FootballCourse.Zones[("Zone%02d"):format(choice[1])]:FindFirstChild(choice[2], true)
		assert(source and source:IsA("Model"), choice[2])
		local clone = source:Clone()
		clone:PivotTo(CFrame.identity)
		clone:SetAttribute("Source", "RojoTest/src/server/OceanLocationKit.luau + OceanCourseLocations.luau")
		for _, n in clone:GetDescendants() do
			if n:IsA("ParticleEmitter") or n:IsA("PointLight") then
				n:Destroy()
			end
		end
		local old = pack:FindFirstChild(clone.Name)
		if old then
			old:Destroy()
		end
		clone.Parent = pack
		table.insert(results, node(clone))
	end
	return { version = 1, source = "Studio native parts", models = results }
end
