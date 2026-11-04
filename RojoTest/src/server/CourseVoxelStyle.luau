--!strict
-- MagicaVoxel-style restyle of course locations chosen by name (docs/course-voxel.md).
-- Runs after FootballCityScenery/Landmarks: it clads the zone's cosmetic banks and pitch
-- with whole-stud blocks and replaces the zone's city props. Physics stays authored.
local Style = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Themes = require(game.ReplicatedStorage.Shared.FootballCity)
local Kit = require(script.Parent.CourseVoxelKit)
local Ground = require(script.Parent.CourseVoxelGround)
local Props = require(script.Parent.CourseVoxelProps)
local Layout = require(script.Parent.WorldLayout)
local VERSION = 1

-- Location name -> prop builder. Add a name here to restyle that location.
Style.Locations = {
	["Football Field"] = Props.footballField,
}

function Style.apply(world: any): any
	assert(world.Name == "World1" and world:GetAttribute("WorldLayoutReady"), "Final World1 layout required")
	local course = Refs.course(world)
	local styled, rebuilt = {}, 0
	for index, theme in Themes do
		local zone = course.Zones[string.format("Zone%02d", index)]
		local field = Refs.field(world, index)
		local city = zone.Environment.Cityscape
		local ground = zone.Geometry:FindFirstChild("GroundCladding")
		local builder = Style.Locations[theme.name]
		if not builder then
			-- Rollback: drop the cladding; FootballCityScenery restores the old props on the next start.
			if zone:GetAttribute("VoxelStyleVersion") then
				if ground then
					ground:Destroy()
				end
				city:SetAttribute("GeometrySignature", nil)
				city:SetAttribute("VoxelStyleSignature", nil)
				zone:SetAttribute("VoxelStyleVersion", nil)
			end
			continue
		end
		local kit = Kit.new(world, zone, field)
		local signature = tostring(field.CFrame) .. tostring(field.Size) .. ":" .. VERSION
		if not ground or ground:GetAttribute("GeometrySignature") ~= signature then
			if ground then
				ground:Destroy()
			end
			local root = Instance.new("Model")
			root.Name = "GroundCladding"
			root.WorldPivot = kit.frame
			root:SetAttribute("Location", theme.name)
			root.Parent = zone.Geometry
			Ground.build(kit, theme, index == 1, root)
			root:SetAttribute("GeometrySignature", signature)
			rebuilt += 1
		end
		-- The voxel pitch paints its own lines; FootballPitches rebuilds the old set each start.
		local markings = zone.Geometry:FindFirstChild("PitchMarkings")
		if markings then
			Layout.retire(world, markings)
		end
		if city:GetAttribute("VoxelStyleSignature") ~= signature then
			for _, node in city:GetChildren() do
				node:Destroy()
			end
			builder(kit, city, theme, index, field)
			city:SetAttribute("VoxelStyleSignature", signature)
		end
		zone:SetAttribute("VoxelStyleVersion", VERSION)
		table.insert(styled, theme.name)
		task.wait()
	end
	return { styled = styled, rebuiltGround = rebuilt }
end

return Style
