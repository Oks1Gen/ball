--!strict
-- One-time longitudinal migration of the authored course, before legacy prepare.
-- Rendered pitches/city/clouds are rebuilt from the resulting field footprints.
local Length = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local V = Vector3.new
local FACTOR = 2
local VERSION = 1

local function archive(): Folder
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
	end
	local journal = Instance.new("Folder")
	journal.Name, journal.Parent = "World1BeforeCourseLength", backups
	return journal
end

function Length.apply(world: any): any
	if world:GetAttribute("CourseLengthVersion") == VERSION then
		return { alreadyApplied = true }
	end
	assert(world:GetAttribute("CourseLengthVersion") == nil, "Unknown course length migration")
	assert(world:GetAttribute("WorldLayoutReady"), "Course length requires the final authored layout")
	local course = Refs.course(world)
	local first = Refs.field(world, 1)
	assert(math.abs(first.Size.Z - 216) < 0.01, "Expected the existing 216-stud locations")
	local front = first.Position.Z + first.Size.Z / 2
	local journal = archive()
	journal:SetAttribute("OriginalFinish", course:GetAttribute("ShotFinishPosition"))
	for _, name in { "RouteFrontZ", "RouteEndZ", "RouteLengthStuds", "BiomeLengthStuds", "RouteDistanceMetres" } do
		journal:SetAttribute(name, world:GetAttribute(name))
	end
	local changed, split = 0, 0
	local seen: { [BasePart]: boolean } = {}
	local function remember(node: Instance, frame: CFrame, size: Vector3?)
		changed += 1
		local row = Instance.new("ObjectValue")
		row.Name, row.Value = tostring(changed), node
		row:SetAttribute("Frame", frame)
		row:SetAttribute("Size", size)
		row.Parent = journal
		if changed % 400 == 0 then
			task.wait()
		end
	end
	local function mapped(frame: CFrame): CFrame
		return frame + V(0, 0, (frame.Z - front) * (FACTOR - 1))
	end
	local function stretch(part: BasePart)
		if seen[part] then
			return
		end
		seen[part] = true
		-- SurfaceSeparation follows its original's parent on every layout cycle.
		-- Keep the linked construction source in the same expanded location.
		local link = part:FindFirstChild("OriginalPart")
		local original = if link and link:IsA("ObjectValue") then link.Value else nil
		local state = game.ServerStorage:FindFirstChild("WorldLayoutState")
		if original and original:IsA("BasePart") and state and original:IsDescendantOf(state) then
			stretch(original)
		end
		local cf, size = part.CFrame, part.Size
		remember(part, cf, size)
		local axis = if math.abs(cf.RightVector.Z) > 0.9999
			then 1
			elseif math.abs(cf.UpVector.Z) > 0.9999 then 2
			elseif math.abs(cf.LookVector.Z) > 0.9999 then 3
			else 0
		local target = V(
			size.X * (if axis == 1 then FACTOR else 1),
			size.Y * (if axis == 2 then FACTOR else 1),
			size.Z * (if axis == 3 then FACTOR else 1)
		)
		local span = if axis == 1 then target.X elseif axis == 2 then target.Y else target.Z
		local pieces = if axis == 0 then 1 else math.ceil(span / 2048)
		local center = mapped(cf)
		local direction = if axis == 1 then cf.RightVector elseif axis == 2 then cf.UpVector else cf.ZVector
		local chunk = span / pieces
		for index = 1, pieces do
			local p = if index == 1 then part else part:Clone()
			if index > 1 then
				p.Name = part.Name .. "Segment" .. tostring(index)
				p:SetAttribute("CourseLengthSegment", true)
				-- New segments crossing zones belong to the common course geometry.
				p.Parent = if part:IsDescendantOf(course.Boundaries) then course.Boundaries else course.Geometry
				split += 1
			end
			p.Size = if pieces == 1
				then target
				else V(
					if axis == 1 then chunk else target.X,
					if axis == 2 then chunk else target.Y,
					if axis == 3 then chunk else target.Z
				)
			p.CFrame = center + direction * (if pieces == 1 then 0 else -span / 2 + (index - 0.5) * chunk)
		end
	end
	local function rigid(model: Model)
		if not model:FindFirstChildWhichIsA("BasePart", true) then
			return
		end
		local cf = model:GetBoundingBox()
		local pivot = model:GetPivot()
		remember(model, pivot)
		model:PivotTo(pivot + V(0, 0, (cf.Z - front) * (FACTOR - 1)))
	end
	local function geometry(root: Instance)
		for _, node in root:GetChildren() do
			if
				node.Name == "Banks"
				or node.Name == "PitchMarkings"
				or node.Name == "LeftAbutmentChecker"
				or node.Name == "RightAbutmentChecker"
				or node:GetAttribute("CourseLengthSegment")
			then
				continue
			elseif node:IsA("BasePart") then
				stretch(node)
			else
				geometry(node)
			end
		end
	end
	for _, zone in course.Zones:GetChildren() do
		stretch(zone.Field)
		geometry(zone.Geometry)
		for _, p in zone.Boundaries:GetDescendants() do
			if p:IsA("BasePart") then
				remember(p, p.CFrame, p.Size)
				p.CFrame = mapped(p.CFrame)
			end
		end
	end
	geometry(course.Geometry)
	for _, node in course.Boundaries:GetChildren() do
		if node:IsA("Model") and node.Name:match("^Boundary%d+$") then
			rigid(node)
		elseif node:IsA("BasePart") and node.Position.Z < front - 0.01 then
			stretch(node)
		end
	end
	for _, node in course.Environment:GetChildren() do
		if node:IsA("Model") then
			rigid(node)
		end
	end
	local finish = course:GetAttribute("ShotFinishPosition")
	if typeof(finish) == "Vector3" then
		course:SetAttribute("ShotFinishPosition", finish + V(0, 0, (finish.Z - front) * (FACTOR - 1)))
	end
	local last = Refs.field(world, 8)
	world:SetAttribute("RouteFrontZ", front)
	world:SetAttribute("RouteEndZ", last.Position.Z - last.Size.Z / 2)
	world:SetAttribute("RouteLengthStuds", first.Size.Z * 8)
	world:SetAttribute("BiomeLengthStuds", first.Size.Z)
	world:SetAttribute(
		"RouteDistanceMetres",
		first.Size.Z * 8 * require(game.ReplicatedStorage.Shared.GameConfig).DistancePerStud
	)
	world:SetAttribute("CourseLengthScale", FACTOR)
	world:SetAttribute("CourseLengthVersion", VERSION)
	return { changed = changed, splitParts = split, length = first.Size.Z * 8 }
end

-- Restore source geometry, then rebuild markings/skins/city/clouds normally.
function Length.revert(world: any)
	local course = Refs.course(world)
	local journal = assert(game.ServerStorage.WorldBackups:FindFirstChild("World1BeforeCourseLength"))
	for _, node in course:GetDescendants() do
		if node:GetAttribute("CourseLengthSegment") then
			node:Destroy()
		end
	end
	local rows = journal:GetChildren()
	table.sort(rows, function(a, b)
		return tonumber(a.Name) > tonumber(b.Name)
	end)
	for index, row in rows do
		local ref = row :: ObjectValue
		local node = ref.Value
		if node and node.Parent then
			local frame = ref:GetAttribute("Frame")
			assert(typeof(frame) == "CFrame", "Missing original frame")
			if node:IsA("BasePart") then
				local size = ref:GetAttribute("Size")
				assert(typeof(size) == "Vector3", "Missing original size")
				node.Size, node.CFrame = size, frame
			elseif node:IsA("Model") then
				node:PivotTo(frame)
			end
		end
		if index % 400 == 0 then
			task.wait()
		end
	end
	for _, name in { "RouteFrontZ", "RouteEndZ", "RouteLengthStuds", "BiomeLengthStuds", "RouteDistanceMetres" } do
		world:SetAttribute(name, journal:GetAttribute(name))
	end
	course:SetAttribute("ShotFinishPosition", journal:GetAttribute("OriginalFinish"))
	world:SetAttribute("CourseLengthVersion", nil)
	world:SetAttribute("CourseLengthScale", nil)
	journal:Destroy()
end

return Length
