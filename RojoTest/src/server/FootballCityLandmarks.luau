--!strict
-- Small themed landmarks beside each exit; the pitch and its physics stay authored.
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Themes = require(game.ReplicatedStorage.Shared.FootballCity)
local Props = require(script.Parent.FootballCityProps)
local Landmarks = {}
local V, C = Vector3.new, Color3.fromRGB
local INK, WHITE = C(67, 93, 121), C(245, 246, 235)
local VERSION = 1
local NAMES = {
	"LocalClubTower",
	"ParkPavilion",
	"StreetClubSign",
	"DockSignalTower",
	"FactoryStacks",
	"SkylineBeacon",
	"AcademyClubTower",
	"ChampionshipTower",
}
local HEIGHTS = { 27, 32, 39, 52, 60, 70, 44, 56 }

function Landmarks.apply(world: Instance): number
	local course = Refs.course(world)
	local k = Scale.factor(world)
	local built = 0
	for index, theme in Themes do
		local zone = course.Zones[string.format("Zone%02d", index)]
		local city = zone.Environment.Cityscape
		local field = Refs.field(world, index)
		local signature = tostring(field.CFrame) .. tostring(field.Size) .. ":" .. VERSION
		local old = city:FindFirstChild(NAMES[index])
		if old and old:GetAttribute("LandmarkSignature") == signature then
			continue
		end
		local ctx = Props.context(field, k)
		local model = Instance.new("Model")
		model.Name = NAMES[index]
		model:SetAttribute("CityLandmark", true)
		model:SetAttribute("LandmarkSignature", signature)
		local side = if index % 2 == 0 then 1 else -1
		local x, z, base, height = side * 70, -field.Size.Z / (2 * k) + 24, 3.74, HEIGHTS[index]
		local function block(name: string, dx: number, y: number, dz: number, size: Vector3, color: Color3): Part
			return ctx.part(model, name, V(x + dx, base + y, z + dz), size, color)
		end
		block("Plinth", 0, 0.5, 0, V(12, 1, 10), INK)
		if index == 2 then
			-- An open timber silhouette, distinct from the tall city signs.
			for _, dx in { -5, 5 } do
				block("TimberColumn", dx, height / 2, 0, V(1.4, height, 2), C(164, 116, 69))
			end
			for dz = -5, 5, 2.5 do
				block("PavilionSlat", 0, height + 1, dz, V(16, 1.2, 1.2), C(192, 151, 97))
			end
		elseif index == 4 then
			for _, dx in { -4, 4 } do
				block("TowerLeg", dx, height / 2, 0, V(1.5, height, 2), theme.accent)
			end
			for y = 2, height - 9, 8 do
				ctx.beam(model, "CrossBrace", V(x - 4, base + y, z), V(x + 4, base + y + 8, z), 0.7, theme.accent)
			end
			block("SignalHousing", 0, height + 1, 0, V(12, 5, 7), INK)
			block("SignalLight", 0, height + 1, 3.6, V(9, 2.5, 0.2), C(255, 225, 95))
		elseif index == 5 then
			for j, dx in { -3.5, 3.5 } do
				local h = height - (j - 1) * 12
				block("BrickStack", dx, h / 2, 0, V(4.5, h, 5), C(224, 105, 42))
				for y = 8, h - 2, 10 do
					block("StackBand", dx, y, 0, V(4.8, 1.3, 5.3), theme.accent)
				end
				block("StackRim", dx, h + 0.5, 0, V(5.5, 1, 6), INK)
			end
		elseif index == 6 then
			block("SkylineSpine", 0, height / 2, 0, V(5, height, 5), INK)
			for j = 1, 4 do
				block("SkylineTerrace", side * (j % 2), 13 * j, 0, V(14 - j, 2, 9), theme.accent)
			end
			block("Antenna", 0, height + 7, 0, V(0.5, 14, 0.5), INK)
		else
			block("ClubPylon", 0, height / 2, 0, V(7, height, 6), INK)
			for _, dx in { -3.8, 3.8 } do
				block("ClubTrim", dx, height / 2, 0, V(0.6, height - 2, 6.5), theme.accent)
			end
			if index == 8 then
				Props.trophy(ctx, model, x, z, base + height + 1)
			elseif index == 7 then
				block("ClubCrown", 0, height + 1, 0, V(14, 2, 8), WHITE)
			else
				block("ClubCap", 0, height + 1, 0, V(11, 2, 8), theme.accent)
			end
		end
		local sign = block("Advertisement", 0, height - 7, 4.5, V(20, 8, 0.8), theme.accent)
		local title = string.format("%02d  %s", index, string.upper(theme.name))
		ctx.text(sign, title, Enum.NormalId.Back, INK)
		ctx.text(sign, title, Enum.NormalId.Front, INK)
		model.WorldPivot = ctx.frame * CFrame.new(x * k, base * k, z * k)
		if old then
			old:Destroy()
		end
		model.Parent = city
		built += 1
		task.wait()
	end
	return built
end

return Landmarks
