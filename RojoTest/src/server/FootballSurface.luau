--!strict
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Surface = {}
local STUDS = "rbxassetid://88156646156237"
local TILE = 8 -- studs a tile in the 0.8 scene; follows the world scale

local function style(part: BasePart, origin: BasePart, tile: number)
	part.Material = Enum.Material.SmoothPlastic
	part.MaterialVariant = ""
	if part:IsA("MeshPart") then
		part.TextureID = ""
	end
	for _, child in part:GetChildren() do
		if child:IsA("Texture") or child:IsA("Decal") or child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	local texture = Instance.new("Texture")
	texture.Name = "FootballStuds"
	texture.Texture = STUDS
	texture.Face = Enum.NormalId.Top
	texture.StudsPerTileU, texture.StudsPerTileV = tile, tile
	texture.Transparency = 0.55
	-- Align the floor and its raised stripes in the same local grid.
	local corner = part.CFrame:PointToWorldSpace(Vector3.new(-part.Size.X / 2, 0, -part.Size.Z / 2))
	local offset = origin.CFrame:PointToObjectSpace(corner)
	texture.OffsetStudsU = (offset.X + origin.Size.X / 2) % tile
	texture.OffsetStudsV = (offset.Z + origin.Size.Z / 2) % tile
	texture.Parent = part
end

function Surface.apply(map: any)
	local tile = TILE * Scale.relative(map)
	local world = map.SkippingWorld
	local markings = world:FindFirstChild("FootballPitchMarkings")
	for index = 1, 8 do
		local floor = world["Field_" .. index]
		style(floor, floor, tile)
		local pitch = markings and markings:FindFirstChild("Pitch" .. index)
		if pitch then
			for _, stripe in pitch:GetChildren() do
				if stripe:IsA("BasePart") and stripe.Name == "MownGrassStripe" then
					style(stripe, floor, tile)
				end
			end
		end
	end
	for _, lane in map.TrainingZone:GetChildren() do
		local strip = lane:FindFirstChild("TrainingStrip")
		if strip and strip:IsA("BasePart") then
			local imported = lane:FindFirstChild("ImportedField")
			if imported then
				for _, mesh in imported:GetDescendants() do
					if mesh:IsA("BasePart") and (mesh.Name:find("_Grass_Bed") or mesh.Name:find("_Grass_Stripes")) then
						style(mesh, strip, tile)
					end
				end
			elseif strip.Transparency < 1 then
				style(strip, strip, tile)
			end
		end
	end
end

return Surface
