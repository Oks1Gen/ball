local Look = require(script.Parent.OceanDepthsLook)
local Ground = require(script.Parent.OceanReefGround)
local Kit = require(script.Parent.OceanReefKit)
local HDStuds = require(script.Parent.HDStuds)

local Landmarks = {}
local v = Vector3.new
local c = Color3.fromHex
local sand = c("F9DA97")
local lightSand = c("FFE7AB")
local darkSand = c("D9AB65")
local limestone = c("477FB7")
local deepBlue = c("2A518B")
local navy = c("102F69")
local teal = c("16BEBE")
local gold = c("EDA932")
local lightGold = c("FFD775")

local function brick(parent: Instance, name: string, cf: CFrame, size: Vector3, tint: Color3, studs: number?)
	local part = Look.part(parent, name, cf, size, tint)
	if studs then
		HDStuds.apply(part, studs)
	end
	return part
end

local function textPlate(part: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Caption"
	gui.Face = Enum.NormalId.Front
	gui.LightInfluence = 0.28
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 70
	gui.Parent = part
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(0.9, 0.77)
	title.Position = UDim2.fromScale(0.05, 0.115)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = lightSand
	title.TextScaled = true
	title.Text = text
	title.Parent = gui
end

local function trophy(cf: CFrame, studs: number): Model
	local model = Instance.new("Model")
	model.Name = "TrophyMonument"
	model.WorldPivot = cf
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	local base = brick(model, "PlinthBase", at(0, 0.6, 0), v(12, 1.2, 12), sand, studs)
	base.CanCollide, base.CanQuery = true, true
	local pedestal = brick(model, "LimestonePlinth", at(0, 2.4, 0), v(9.6, 2.4, 9.6), limestone, studs)
	pedestal.CanCollide, pedestal.CanQuery = true, true
	local pedestalTop = brick(model, "UpperPlinth", at(0, 4.2, 0), v(7.2, 1.2, 7.2), deepBlue, studs)
	pedestalTop.CanCollide, pedestalTop.CanQuery = true, true
	brick(model, "TurquoiseCoping", at(0, 5.1, 0), v(7.2, 0.6, 7.2), teal)
	brick(model, "PlaqueBorder", at(0, 2.8, -4.84), v(6.45, 1.82, 0.28), gold)
	textPlate(brick(model, "ReefCupPlaque", at(0, 2.8, -5.015), v(5.88, 1.40, 0.15), navy), "REEF CUP")
	for _, x in { -3.02, 3.02 } do
		for _, y in { 2.1, 3.5 } do
			brick(model, "PlaqueStud", at(x, y, -5.07), v(0.26, 0.26, 0.20), lightGold)
		end
	end
	brick(model, "ScallopSeat", at(0, 5.88, 0), v(4.7, 1.05, 3.8), lightGold)
	Look.ellipsoid(model, "ShellBowl", at(0, 7.8, 0), v(8.3, 3.8, 6.4), gold)
	Look.ellipsoid(model, "ShellInterior", at(0, 8.74, -0.04), v(7.91, 2.55, 6.08), lightGold)
	for i = 0, 13 do
		local angle = i * 2 * math.pi / 14
		local radial = at(0, 7.99, 0) * CFrame.Angles(0, angle, 0)
		local radius = 3.62 - math.cos(angle * 2) * 0.37
		Look.ellipsoid(
			model,
			"ScallopLip",
			radial * CFrame.new(0, 0.95 + (1 + math.cos(angle)) * 0.25, -radius),
			v(1.78, 1.12, 1.22),
			if i % 2 == 0 then lightSand else lightGold
		)
	end
	for i = -4, 4 do
		local tip = v(i * 1.28, 18.4 - math.abs(i) ^ 1.55 * 0.60, 1.33 + math.abs(i) * 0.16)
		local start = v(i * 0.32, 8.1, 0.86)
		local direction = tip - start
		local frame = cf * CFrame.lookAt((tip + start) / 2, (tip + start) / 2 + direction, v(0, 0, 1))
		brick(
			model,
			"ScallopRib",
			frame,
			v(1.48, 0.96, direction.Magnitude + 0.22),
			if i % 2 == 0 then lightGold else gold
		)
		brick(model, "ScallopTip", cf * CFrame.new(tip), v(1.46, 0.8, 1.3), lightSand)
	end
	for _, side in { -1, 1 } do
		local points = {
			v(side * 3.0, 12.02, 0.28),
			v(side * 5.6, 12.02, 0.28),
			v(side * 5.6, 10.36, 0.28),
			v(side * 4.1, 8.78, 0.28),
			v(side * 3.05, 8.78, 0.28),
		}
		for i = 2, #points do
			local a, b = points[i - 1], points[i]
			local middle = (a + b) / 2
			local frame = cf * CFrame.lookAt(middle, b, v(0, 0, 1))
			brick(model, "GoldHandle", frame, v(0.9, 1.12, (b - a).Magnitude + 0.3), gold)
		end
		for _, p in { points[2], points[4] } do
			brick(model, "HandlePin", cf * CFrame.new(p - v(0, 0, 0.6)), v(0.73, 0.73, 0.28), lightGold)
		end
	end
	local pearl = Look.ellipsoid(model, "ChampionsPearl", at(0, 11.45, -0.73), v(5.28, 5.28, 5.28), c("FFF1F9"))
	pearl.Reflectance = 0.14
	return model
end

local function portal(cf: CFrame, studs: number): Model
	local model = Instance.new("Model")
	model.Name = "BathyscapheHatch"
	model.WorldPivot = cf
	model:SetAttribute("Purpose", "Ocean Depths reef gate preview")
	local function at(x: number, y: number, z: number): CFrame
		return cf * CFrame.new(x, y, z)
	end
	brick(model, "Foundation", at(0, 0.6, 0), v(16.8, 1.2, 8.4), sand, studs)
	brick(model, "EntranceStep", at(0, 0.3, -4.8), v(9.6, 0.6, 1.2), lightSand)
	brick(model, "EntranceStep", at(0, 0.9, -2.4), v(9.6, 1.8, 1.2), lightSand)
	brick(model, "EntranceStep", at(0, 1.2, -1.2), v(9.6, 2.4, 1.2), lightSand)
	brick(model, "Threshold", at(0, 2.1, 1.2), v(9.6, 0.6, 3.6), lightSand)
	for _, side in { -1, 1 } do
		brick(model, "LimestoneFoot", at(side * 6.0, 2.4, 0.6), v(4.8, 2.4, 6), limestone, studs)
		brick(model, "FootCoping", at(side * 6, 3.9, 0.6), v(4.8, 0.6, 6), teal)
		for row, profile in
			{
				{ 4.2, 7.8 },
				{ 4.2, 7.8 },
				{ 4.2, 7.8 },
				{ 4.2, 7.8 },
				{ 4.2, 7.8 },
				{ 3.6, 8.4 },
				{ 3, 7.8 },
				{ 1.8, 6.6 },
			}
		do
			local inner, outer = profile[1], profile[2]
			local y = 3.6 + row * 1.2
			brick(
				model,
				"SandstoneCourse",
				at(side * (inner + outer) / 2, y, 0.6),
				v(outer - inner, 1.2, 4.8),
				if row % 3 == 0 then darkSand else lightSand,
				studs
			)
			if row >= 5 then
				brick(model, "TurquoiseArchEdge", at(side * (outer - 0.6), y + 0.36, -2.13), v(1.2, 0.48, 0.72), teal)
			end
		end
	end
	brick(model, "KeystoneCourse", at(0, 14.4, 0.6), v(10.8, 1.2, 4.8), lightSand, studs)
	brick(model, "CrownCoping", at(0, 15.3, 0.6), v(8.4, 0.6, 4.8), teal)
	brick(model, "CrownGemFrame", at(0, 14.4, -1.96), v(1.55, 1.55, 0.35), darkSand)
	brick(model, "CrownSeaGlass", at(0, 14.4, -2.18) * CFrame.Angles(0, 0, math.pi / 4), v(0.78, 0.78, 0.28), teal)
	local water = Look.part(model, "WaterVeil", at(0, 7.92, 0.5), v(8.52, 11.1, 0.12), c("1DBEDC"))
	water.Transparency = 0.22
	water.CastShadow = false
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local texture = Instance.new("Texture")
		texture.Name = "WaterLight"
		texture.Face = face
		texture.Texture = "rbxassetid://12781828706"
		texture.StudsPerTileU, texture.StudsPerTileV = 9, 9
		texture.Transparency = 0.32
		texture.Parent = water
	end
	Kit.place(model, "PinkStaghorn", at(-6.2, 1.2, -3.27), 0.42)
	Kit.place(model, "MintAnemone", at(6.22, 1.2, -3.27), 0.38)
	local ramp = Instance.new("WedgePart")
	ramp.Name = "ThresholdRamp"
	ramp.Size = v(8.4, 2.4, 4.8)
	ramp.CFrame = at(0, 1.2, -3)
	ramp.Transparency = 1
	ramp.Anchored = true
	ramp.CanCollide, ramp.CanQuery, ramp.CanTouch = true, true, false
	ramp:SetAttribute("PartRole", "TraversalRamp")
	ramp:SetAttribute("Purpose", "Smooth walkable collision over the reef gate steps")
	ramp.Parent = model
	for _, part in model:GetChildren() do
		if
			part:IsA("BasePart")
			and (part.Name == "Threshold" or part.Name == "LimestoneFoot" or part.Name == "SandstoneCourse")
		then
			part.CanCollide, part.CanQuery = true, true
		end
	end
	return model
end

local function rankings(folder: Instance, studs: number)
	for _, board in folder:GetChildren() do
		if not board:IsA("Model") then
			continue
		end
		local panel = board:FindFirstChild("Panel")
		local header = board:FindFirstChild("HeaderSurface")
		local stand = board:FindFirstChild("Stand")
		if not (panel and panel:IsA("BasePart") and header and header:IsA("BasePart") and stand) then
			continue
		end
		local base = board:GetPivot()
		local frame = Instance.new("Model")
		frame.Name = "ReefDisplayHousing"
		local function at(x: number, y: number, z: number): CFrame
			return base * CFrame.new(x, y, z)
		end
		-- Keep the original display planes and GUI instances. Build the shell behind them.
		local housing = brick(frame, "SandstoneBacking", at(0, 16.2, 0.08), v(16.8, 26.4, 1.2), sand, studs)
		housing.CanCollide, housing.CanQuery = true, true
		brick(frame, "RecessedScreen", at(0, 16.48, -0.52), v(15.25, 25.85, 0.26), navy)
		for _, side in { -1, 1 } do
			brick(frame, "TurquoiseUpright", at(side * 8.02, 16.2, -0.7), v(0.84, 24, 0.6), teal)
			for _, y in { 5.4, 26.4 } do
				brick(frame, "CornerTile", at(side * 7.8, y, -0.91), v(1.2, 1.2, 0.38), limestone)
			end
		end
		brick(frame, "TurquoiseSill", at(0, 4.2, -0.79), v(16.8, 0.6, 0.55), teal)
		brick(frame, "TurquoiseCap", at(0, 29.7, -0.34), v(16.8, 0.6, 1.2), teal)
		for _, child in stand:GetDescendants() do
			if child:IsA("BasePart") then
				child.Color = if child.Name == "Plinth" then limestone else lightSand
			end
		end
		for _, name in { "Body", "BodyRim", "Header", "HeaderRim", frame.Name } do
			local old = board:FindFirstChild(name)
			if old then
				old:Destroy()
			end
		end
		frame.Parent = board
	end
end

function Landmarks.apply(lobby: any)
	local decor = lobby.Environment.ClubDecor
	local oldTrophy: Model = decor.TrophyMonument
	local oldGate: Model = decor:FindFirstChild("BathyscapheHatch") or decor.WorldPortal
	local source = assert(lobby.Geometry.Lawn:FindFirstChild("LawnCell", true))
	local studs = Look.studsTile(source)
	local surfaces = Ground.collect(lobby.Geometry, { LawnCell = true, GroundTile = true })
	local function base(model: Model, footprint: Vector2): CFrame
		local pivot = model:GetPivot()
		local ground = v(pivot.X, 20.26, pivot.Z)
		return Ground.fit(surfaces, CFrame.new(ground) * pivot.Rotation, footprint, 0.12)
	end
	local newTrophy = trophy(base(oldTrophy, Vector2.new(12, 12)), studs)
	local newGate = portal(base(oldGate, Vector2.new(16.8, 10.8)), studs)
	newTrophy.Parent = decor
	newGate.Parent = decor
	oldTrophy:Destroy()
	oldGate:Destroy()
	rankings(lobby.Leaderboards, studs)
end

function Landmarks.writeTemplates(lobby: any)
	local storage = game:GetService("ServerStorage")
	local assets = assert(storage:FindFirstChild("Assets"))
	local ocean = assert(assets:FindFirstChild("OceanDepths"))
	local category = Instance.new("Folder")
	category.Name = "Landmarks"
	for _, original in
		{
			lobby.Environment.ClubDecor.TrophyMonument,
			lobby.Environment.ClubDecor.BathyscapheHatch,
			lobby.Leaderboards.skill,
		}
	do
		local model = original:Clone()
		if model.Name == "skill" then
			model.Name = "ReefLeaderboard"
		end
		model:PivotTo(CFrame.identity)
		model.Parent = category
	end
	local previous = ocean:FindFirstChild(category.Name)
	category.Parent = ocean
	if previous then
		previous:Destroy()
	end
end

return Landmarks
