--!strict
-- Preserve authored wall footprints; flatten only decorative checker skins.
local Palette = require(script.Parent.LobbyPalette)
local Walls = {}
local LEGACY_EARTH = Color3.fromRGB(159, 111, 72)
local PREVIOUS_EARTH = Color3.fromRGB(193, 155, 117)
local CARAMEL_EARTH = Color3.fromRGB(211, 143, 71)

local function same(a: Color3, b: Color3): boolean
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.01
end

function Walls.apply(world: Instance): any
	if world.Name ~= "World1" then
		return { tiles = 0, walls = 0 }
	end
	local lobby = world:FindFirstChild("Lobby")
	if not lobby then
		return { tiles = 0, walls = 0 }
	end
	local coverage = require(script.Parent.LobbyWallCoverage).apply(world)
	local tiles, walls = 0, 0
	local baseNames: { [string]: boolean } = {}
	-- Include the course-facing side of the entrance arch as well.
	for _, node in world:GetDescendants() do
		if node:IsA("Model") and node.Name:match("Checker$") then
			baseNames[(node.Name:gsub("Checker$", ""))] = true
		end
	end
	for i, part in world:GetDescendants() do
		if part:IsA("BasePart") then
			local stud: Texture? = nil
			if part.Name == "CheckerTile" then
				for _, child in part:GetChildren() do
					if
						child:IsA("Texture") and (child.Name == "CheckerStuds" or child.Name == "TerraceCheckerStuds")
					then
						stud = child
						break
					end
				end
			end
			if stud then
				assert(
					not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Wall checker must remain cosmetic"
				)
				local normal = Vector3.FromNormalId(stud.Face)
				local axis = if math.abs(normal.X) > 0.5 then "X" elseif math.abs(normal.Y) > 0.5 then "Y" else "Z"
				local oldDepth = (part.Size :: any)[axis]
				local newDepth = math.min(oldDepth, Palette.WallCheckerDepth)
				if math.abs(oldDepth - newDepth) > 0.00001 then
					if part:GetAttribute("BeforeThinCheckerSize") == nil then
						part:SetAttribute("BeforeThinCheckerSize", part.Size)
						part:SetAttribute("BeforeThinCheckerCFrame", part.CFrame)
					end
					-- Keep the back on the wall plane; move only the exposed skin inward.
					part.CFrame += part.CFrame:VectorToWorldSpace(normal) * ((newDepth - oldDepth) / 2)
					part.Size = if axis == "X"
						then Vector3.new(newDepth, part.Size.Y, part.Size.Z)
						elseif axis == "Y" then Vector3.new(part.Size.X, newDepth, part.Size.Z)
						else Vector3.new(part.Size.X, part.Size.Y, newDepth)
				end
				part.Color, part.CastShadow = Palette.EarthDark, false
				part:SetAttribute("WallCheckerDepth", newDepth)
				tiles += 1
			elseif
				(part:IsDescendantOf(lobby) or baseNames[part.Name])
				and (
					same(part.Color, LEGACY_EARTH)
					or same(part.Color, PREVIOUS_EARTH)
					or same(part.Color, CARAMEL_EARTH)
					or same(part.Color, Palette.Earth)
				)
			then
				part.Color = Palette.Earth
				walls += 1
			end
		end
		if i % 1000 == 0 then
			task.wait()
		end
	end
	world:SetAttribute("LobbyWallStyleVersion", 3)
	return { tiles = tiles, walls = walls, coverage = coverage }
end

return Walls
