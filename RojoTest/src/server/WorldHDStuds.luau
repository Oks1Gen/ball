--!strict
-- Normalize saved map blocks and cover the authored bases behind decorative cladding.
local HDStuds = require(script.Parent.HDStuds)
local LobbyWallCoverage = require(script.Parent.LobbyWallCoverage)
local Palette = require(script.Parent.LobbyPalette)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)

local WorldHDStuds = {}
local wallOwners = { SideTerraces1 = true, SideTerraces2 = true, RearTerraces = true, EntranceTunnel = true }
local galleonBlocks = {
	Keel = true,
	HullPlank = true,
	RaisedProw = true,
	SweptBowRail = true,
	ProwScroll = true,
	SternDeck = true,
	DeckRib = true,
	CabinFrame = true,
	BrokenCabinRoof = true,
	CabinSill = true,
	CabinLintel = true,
	BrokenMast = true,
	Spar = true,
	TornCreamSail = true,
}

local function backingTile(
	part: BasePart,
	lobby: Instance,
	geometry: Instance?,
	environment: Instance?,
	ocean: boolean,
	groundTile: number,
	wallTile: number
): number?
	local parent = part.Parent
	if not parent then
		return nil
	end
	if parent == geometry and part.Name == "GroundTile" then
		return groundTile
	end
	if part.Name == "KickZoneFloor" and parent.Name == "KickZone" and parent.Parent == lobby then
		return groundTile
	end
	if LobbyWallCoverage.isBacking(part) then
		local owner: Instance? = parent
		while owner and owner ~= lobby do
			if wallOwners[owner.Name] and owner.Parent == environment then
				return wallTile
			end
			owner = owner.Parent
		end
	end
	if ocean then
		if parent.Name == "SandfilledGalleon" and parent:IsA("Model") and galleonBlocks[part.Name] then
			return if parent:GetScale() < 1.75 then 3.6 else 4.8
		end
		if parent.Name == "SunlitBanks" and (part.Name == "SandShelf" or part.Name == "Seabed") then
			return 4.8
		end
	end
	return nil
end

function WorldHDStuds.apply(world: Instance, subtree: Instance?): { converted: number, removed: number, filled: number }
	local map = workspace:FindFirstChild("Map")
	assert(map and world.Parent == map and world.Name:match("^World%d+$"), "Expected a world in Workspace.Map")
	local lobby = assert(world:FindFirstChild("Lobby"), "Expected a complete world")
	local geometry, environment = lobby:FindFirstChild("Geometry"), lobby:FindFirstChild("Environment")
	local root = subtree or world
	assert(root == world or root:IsDescendantOf(world), "Expected a subtree of the selected world")

	local ocean = world:GetAttribute("OceanDepthsPreview") == true
	local scale =
		Scale.factor(if ocean and world:GetAttribute("WorldScale") == nil then map:FindFirstChild("World1") else world)
	local groundTile = scale * Palette.GroundStudPitch * Palette.StudsPerTexture
	local wallTile = scale * Palette.WallStudPitch * Palette.StudsPerTexture
	local converted, removed, filled = 0, 0, 0
	for index, instance in root:GetDescendants() do
		if index % 750 == 0 then
			task.wait()
		end
		if
			not (instance:IsA("WedgePart") or (instance:IsA("Part") and instance.Shape == Enum.PartType.Block))
			or instance.Transparency ~= 0
		then
			continue
		end
		local part: BasePart = instance
		local textures: { Texture } = {}
		local hasOtherAppearance = false
		for _, child in part:GetChildren() do
			if child:IsA("Texture") and child.Texture == HDStuds.LegacyImage then
				table.insert(textures, child)
			elseif (child:IsA("Decal") and child.Name ~= "WaterLight") or child:IsA("SurfaceAppearance") then
				hasOtherAppearance = true
			end
		end
		local first = textures[1]
		local backing = backingTile(part, lobby, geometry, environment, ocean, groundTile, wallTile)
		local tile = backing or (first and first.StudsPerTileU)
		if not tile or hasOtherAppearance then
			continue
		end
		local variant = HDStuds.variant(part.Material, tile)
		if not variant or (not backing and part.MaterialVariant ~= "" and part.MaterialVariant ~= variant.Name) then
			continue
		end
		local compatible = true
		for _, texture in textures do
			-- Egg stand wedges used a shortened V repeat to compensate for the old face projection.
			local standSlope = part:IsA("WedgePart")
				and texture.Name == "StandStuds"
				and texture.Face == Enum.NormalId.Top
			if
				not backing
				and (
					math.abs(texture.StudsPerTileU - tile) > 0.001
					or (not standSlope and math.abs(texture.StudsPerTileV - tile) > 0.001)
				)
			then
				compatible = false
				break
			end
		end
		if compatible then
			if part.MaterialVariant ~= variant.Name then
				part.MaterialVariant = variant.Name
				converted += 1
				if not first then
					filled += 1
				end
			end
			for _, texture in textures do
				texture:Destroy()
				removed += 1
			end
			if part:IsA("Part") and part.Name == "KickZoneFloor" and part.TopSurface == Enum.SurfaceType.Studs then
				part.TopSurface = Enum.SurfaceType.Smooth
			end
		end
	end
	return { converted = converted, removed = removed, filled = filled }
end

return WorldHDStuds
