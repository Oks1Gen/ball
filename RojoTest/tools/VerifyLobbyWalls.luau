-- Read-only checks for the shallow, lighter World1 checker skins.
local world = workspace.Map.World1
local palette = require(game.ServerScriptService.Server.LobbyPalette:Clone())
local tiles, backed = 0, 0
for i, part in world:GetDescendants() do
	if part:IsA("BasePart") and part.Name == "CheckerTile" then
		local stud
		for _, child in part:GetChildren() do
			if child:IsA("Texture") and (child.Name == "CheckerStuds" or child.Name == "TerraceCheckerStuds") then
				stud = child
				break
			end
		end
		if stud then
			local normal = Vector3.FromNormalId(stud.Face)
			local axis = if math.abs(normal.X) > 0.5 then "X" elseif math.abs(normal.Y) > 0.5 then "Y" else "Z"
			local depth = part.Size[axis]
			assert(depth <= palette.WallCheckerDepth + 0.00001, "Checker sticks out")
			assert(part.Color == palette.EarthDark, "Wrong checker colour")
			assert(
				not part.CanCollide and not part.CanTouch and not part.CanQuery and not part.CastShadow,
				"Checker affects physics/shadows"
			)
			local oldSize = part:GetAttribute("BeforeThinCheckerSize")
			local oldCF = part:GetAttribute("BeforeThinCheckerCFrame")
			if oldSize and oldCF then
				local oldBack = oldCF.Position - oldCF:VectorToWorldSpace(normal) * (oldSize[axis] / 2)
				local newBack = part.Position - part.CFrame:VectorToWorldSpace(normal) * (depth / 2)
				assert((oldBack - newBack).Magnitude < 0.0001, "Checker back moved off wall")
				backed += 1
			end
			tiles += 1
		end
	end
	if i % 2000 == 0 then
		task.wait()
	end
end
assert(tiles > 0, "No wall checker found")
return { tiles = tiles, backsPreserved = backed, maximumDepth = palette.WallCheckerDepth }
