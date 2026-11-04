--!strict
-- Remove terrace dressing only; preserve wall solids, gameplay and waterfalls.
local Decor = {}
local TERRACES = { SideTerraces1 = true, SideTerraces2 = true, RearTerraces = true }
local SOLIDS = { TerraceEarth = true, RearEarthLedge = true, GrassShelf = true, RearGrassLedge = true }
local TOP = { TunnelRoofTree = true, LayeredShrub = true, Stem = true, Petals = true, Pollen = true }
local LOOSE = {
	TrailingVine = true,
	MossCap = true,
	RockMass = true,
	GardenShrub = true,
	FlowerStem = true,
	FlowerPetals = true,
	FlowerCenter = true,
	SummitPollen = true,
	SummitFlowerStem = true,
	SummitFlower = true,
}

function Decor.plan(world: any): { Instance }
	local environment = world.Lobby.Environment
	local targets: { Instance } = {}
	local walls = {}
	for _, owner in environment:GetChildren() do
		if TERRACES[owner.Name] then
			for _, child in owner:GetChildren() do
				if SOLIDS[child.Name] and child:IsA("BasePart") then
					table.insert(walls, child)
				elseif child.Name ~= "WallCladding" and child.Name ~= "UpperTier" then
					table.insert(targets, child)
				end
			end
		elseif
			owner.Name:match("^SideTerraces[12]Planting$")
			or owner.Name == "RearTerracesPlanting"
			or owner.Name:match("^StoneOutcrops[12]$")
		then
			table.insert(targets, owner)
		elseif owner.Name == "EntranceTunnel" then
			for _, child in owner:GetChildren() do
				if child:IsA("BasePart") and child.Name:find("Abutment") then
					table.insert(walls, child)
				end
				if TOP[child.Name] then
					table.insert(targets, child)
				end
			end
		end
	end
	local function onWall(position: Vector3): boolean
		for _, wall in walls do
			local d = position - wall.Position
			if
				math.abs(d.X) <= wall.Size.X / 2 + 3
				and math.abs(d.Z) <= wall.Size.Z / 2 + 3
				and position.Y > 32
				and position.Y <= wall.Position.Y + wall.Size.Y / 2 + 6
			then
				return true
			end
		end
		return false
	end
	local flowers = environment:FindFirstChild("Flowers")
	if flowers then
		for _, model in flowers:GetDescendants() do
			if model:IsA("Model") and model.Name == "SmallFlower" then
				local stem = model:FindFirstChild("Stem")
				if stem and stem:IsA("BasePart") and onWall(stem.Position) then
					table.insert(targets, model)
				end
			end
		end
	end
	-- Earlier palette/flower passes left some individual terrace props at zone level.
	for _, child in environment:GetChildren() do
		if child:IsA("BasePart") and LOOSE[child.Name] then
			if onWall(child.Position) then
				table.insert(targets, child)
			end
		end
	end
	-- Fail before any mutation if an unfamiliar functional object appears here.
	for _, target in targets do
		local descendants = target:GetDescendants()
		table.insert(descendants, target)
		for _, p in descendants do
			assert(
				not p:IsA("LuaSourceContainer") and not p:IsA("ProximityPrompt") and not p:IsA("ClickDetector"),
				"Functional wall decoration"
			)
			if p:IsA("BasePart") then
				assert(
					p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
					"Wall decoration affects physics: " .. p:GetFullName()
				)
			end
		end
	end
	return targets
end

function Decor.apply(world: any): number
	local targets = Decor.plan(world)
	for _, target in targets do
		target:Destroy()
	end
	return #targets
end
return Decor
