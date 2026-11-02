-- Read-only Edit/Server verification of the final atmosphere pass.
local world = workspace.Map.World1
local course = world.FootballCourse
local clouds = assert(course.Environment:FindFirstChild("CloudSea"), "Cloud perimeter is missing")
assert(not course.Environment:FindFirstChild("River"), "Old river is still active")
local count, lobes = 0, 0
for _, segment in clouds:GetChildren() do
	assert(segment:IsA("Model"), "Perimeter ownership is missing")
	for _, model in segment:GetChildren() do
		assert(model:IsA("Model"), "A cloud must be one movable object")
		count += 1
		for _, p in model:GetChildren() do
			if p:IsA("BasePart") then
				assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Cloud changes physics")
				assert(
					p.Material == Enum.Material.SmoothPlastic and p.Transparency == 0,
					"Cloud must be solid, smooth geometry"
				)
				assert(p:FindFirstChildWhichIsA("SpecialMesh"), "Cloud lobe is not volumetric")
				assert(not p:FindFirstChildWhichIsA("Texture"), "Cloud has studs")
				lobes += 1
			end
		end
	end
end
assert(#clouds:GetChildren() == 6 and count == clouds:GetAttribute("CloudCount"), "Incomplete perimeter")
for _, p in world:GetDescendants() do
	assert(not p.Name:match("^RiverWater") and not p.Name:match("^VFX_River"), "Retired water returned")
end
assert(not course.Zones.Zone04.Environment.Cityscape:FindFirstChild("HarborTug"), "Water-only prop remains")
local ref = require(game.ReplicatedStorage.Shared.WorldRefs)
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { course }
params.RespectCanCollide = true
local supported = 0
for i = 1, 8 do
	local field = ref.field(world, i)
	local hit = workspace:Raycast(field.Position + Vector3.new(0, 8, 0), Vector3.new(0, -12, 0), params)
	assert(hit and math.abs(hit.Position.Y - field.Position.Y - field.Size.Y / 2) < 0.1, "Field support changed")
	supported += 1
end
return { perimeterSections = 6, cloudModels = count, volumeLobes = lobes, supportedFields = supported }
