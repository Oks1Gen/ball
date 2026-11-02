-- Read-only Edit/Server checks of the actual eight zone seams and shore support.
local world = workspace.Map.World1
local course = world.FootballCourse
local palette = require(game.ServerScriptService.Server.CoursePalette:Clone())
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local supports = {}
for _, p in course:GetDescendants() do
	if
		p:IsA("BasePart")
		and (
			p.Name == "GroundTile"
			or p.Name == "InnerBankEarth"
			or p.Name == "OuterBankEarth"
			or p.Name == "BankExtension"
		)
	then
		table.insert(supports, p)
	end
end
params.FilterDescendantsInstances = supports
params.RespectCanCollide = true
local zones, bodies, seams, floors, details, hidden = 0, 0, 0, 0, 0, 0
local maxFloorGap = 0
for index = 1, 8 do
	local zone = course.Zones[string.format("Zone%02d", index)]
	local field = zone.Field
	local front, back = field.Position.Z + field.Size.Z / 2, field.Position.Z - field.Size.Z / 2
	local bankModels = assert(zone.Geometry:FindFirstChild("Banks"), "Missing shore bodies")
	assert(#bankModels:GetChildren() == 4, "Expected four shore bodies")
	for _, body in bankModels:GetChildren() do
		assert(body:IsA("BasePart") and body.Color == palette[index].earth, "Wrong shore theme")
		assert(not body.CanCollide and not body.CanTouch and not body.CanQuery, "Skin changes physics")
		assert(math.abs(body.Position.Z - field.Position.Z) < 0.001, "Shore body has wrong centre")
		assert(math.abs(body.Size.Z - field.Size.Z) < 0.001, "Shore body has wrong extent")
		local textured = {}
		for _, t in body:GetChildren() do
			if t:IsA("Texture") and t.Transparency < 1 and t.Texture == "rbxassetid://88156646156237" then
				textured[t.Face] = true
			end
		end
		for _, face in { Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back } do
			assert(textured[face], "Shore face has no studs")
		end
		for _, z in { back + 0.1, back + 1, field.Position.Z, front - 1, front - 0.1 } do
			local top = body.Position.Y + body.Size.Y / 2
			local hit = workspace:Raycast(Vector3.new(body.Position.X, top + 12, z), Vector3.new(0, -60, 0), params)
			assert(hit, "Shore has no physical support at " .. z)
			local gap = top - hit.Position.Y
			assert(gap < 1.3 and gap > -0.4, "Visual shore diverges from physical support")
			maxFloorGap = math.max(maxFloorGap, gap)
			floors += 1
		end
		bodies += 1
	end
	for _, detail in zone.Environment:GetChildren() do
		if
			detail:IsA("Model")
			and detail:GetAttribute("CourseNaturalDetail")
			and detail:FindFirstChildWhichIsA("BasePart", true)
		then
			local cf, size = detail:GetBoundingBox()
			assert(
				cf.Z - size.Z / 2 >= back + 0.99 and cf.Z + size.Z / 2 <= front - 0.99,
				"Prop crosses theme boundary"
			)
			assert(detail:GetAttribute("CourseRegionIndex") == index, "Wrong natural prop owner")
			details += 1
		end
	end
	if index < 8 then
		local following = course.Zones[string.format("Zone%02d", index + 1)].Field
		assert(math.abs(back - following.Position.Z - following.Size.Z / 2) < 0.001, "Field seam has a gap")
		local divider = course.Boundaries["Boundary" .. index]
		assert(math.abs(divider.Wall.Position.Z - back) < 0.001, "Divider misses field seam")
		assert(divider.Wall.Color == following.Color, "Divider has wrong theme")
		assert(math.abs(divider.TitleAnchor.Position.Z - back) < 0.001, "Title misses field seam")
		for _, side in { "InnerWest", "InnerEast", "OuterWest", "OuterEast" } do
			local nextBody = course.Zones[string.format("Zone%02d", index + 1)].Geometry.Banks[side]
			local currentBody = bankModels[side]
			assert(
				math.abs(currentBody.Position.Z - currentBody.Size.Z / 2 - nextBody.Position.Z - nextBody.Size.Z / 2)
					< 0.001,
				"Shore colour changes off the field seam"
			)
			seams += 1
		end
	end
	zones += 1
	task.wait()
end
for _, p in course:GetDescendants() do
	if
		p:IsA("BasePart")
		and (p.Name == "GroundTile" or p.Name == "InnerBankEarth_Surface" or p.Name == "OuterBankEarth_Surface")
	then
		assert(p.Transparency == 1, "Old five-zone skin remains visible")
		hidden += 1
	end
end
assert(zones == 8 and bodies == 32 and seams == 28 and floors == 160, "Incomplete course audit")
local crossings = 0
if game:GetService("RunService"):IsRunning() then
	local config = require(game.ReplicatedStorage.Shared.GameConfig)
	local frame = config.arenaFrame(world)
	local transitions = require(game.ServerScriptService.Server.Gameplay.ShotZones).crossings(world, {
		startPosition = frame:PointToWorldSpace(config.ShotStartLocal),
		distance = config.shotLimit(1, world),
		direction = frame.LookVector,
	})
	assert(#transitions == 7, "Shot misses course transitions")
	local previous = 0
	for i, entry in transitions do
		assert(entry.zone == i + 1 and entry.alpha > previous, "Zones crossed out of order")
		assert(math.abs(entry.multiplier - (1 + i / 10)) < 0.0001, "Wrong zone reward multiplier")
		previous = entry.alpha
		crossings += 1
	end
end
return {
	zones = zones,
	bodies = bodies,
	seamPairs = seams,
	supportRays = floors,
	naturalProps = details,
	hiddenLayers = hidden,
	maximumOldSupportGap = maxFloorGap,
	shotCrossings = crossings,
}
