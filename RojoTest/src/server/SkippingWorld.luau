--!strict
local Construction = require(script.Parent.ConstructionTypes)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local World = {}
local C, V = Color3.fromRGB, Vector3.new
function World.finish(map: Construction.World)
	if map:GetAttribute("SkippingFinishVersion") == 7 then
		return
	end
	local lighting = game:GetService("Lighting")
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	local snapshot = backups and backups:FindFirstChild("BeforeSkippingGame")
	local savedLighting = snapshot and snapshot:FindFirstChild("Lighting")
	if snapshot and not savedLighting then
		savedLighting = Instance.new("Folder")
		savedLighting.Name = "Lighting"
		savedLighting.Parent = snapshot
	end
	for _, b in lighting:GetChildren() do
		if b:IsA("BloomEffect") and b.Name ~= "SkippingBloom" then
			if savedLighting and not savedLighting:FindFirstChild(b.Name) then
				b:Clone().Parent = savedLighting
			end
			b.Enabled = false
		end
	end
	local bloom = lighting:FindFirstChild("SkippingBloom") or Instance.new("BloomEffect")
	bloom.Name = "SkippingBloom"
	bloom.Intensity = 0.12
	bloom.Size = 20
	bloom.Threshold = 1.6
	bloom.Parent = lighting
	local plate = map.SkippingWorld.KickZonePrint
	plate.Size = V(140, 16, 0.05)
	plate.CFrame = CFrame.new(-115, 0.82, 13) * CFrame.Angles(math.pi / 2, 0, 0)
	plate.Transparency = 1
	local gui = plate.KickZoneLabel
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 110)
	gui.AlwaysOnTop = false
	local title = gui.TextLabel
	title.Rotation = 180
	title.TextScaled = true
	title.TextColor3 = C(255, 253, 243)
	title.TextStrokeTransparency = 0
	title.TextStrokeColor3 = C(18, 20, 26)
	for _, s in title:GetChildren() do
		if s:IsA("UIStroke") then
			s:Destroy()
		end
	end
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = C(20, 22, 28)
	stroke.Parent = title
	local terrain = workspace.Terrain
	terrain.WaterReflectance = 0.04
	terrain.WaterTransparency = 0.08
	terrain.WaterWaveSize = 0.09
	terrain.WaterColor = C(16, 194, 226)
	for i = 1, 8 do
		local field = map.SkippingWorld:FindFirstChild("Field_" .. i)
		if field and field:IsA("BasePart") then
			field.Position = V(field.Position.X, 0.7, field.Position.Z)
			field.Transparency = 0.08
			field.Material = Enum.Material.SmoothPlastic
			field.Reflectance = 0
			field.Color = Config.Biomes[i].color
		end
	end
	local apron = map.Lobby.KickZoneFloor
	if not apron:FindFirstChild("KickZoneStuds") then
		local studs = Instance.new("Texture")
		studs.Name = "KickZoneStuds"
		studs.Texture = Config.StudTexture
		studs.Face = Enum.NormalId.Top
		studs.StudsPerTileU = 8
		studs.StudsPerTileV = 8
		studs.Transparency = 0.55
		studs.Color3 = apron.Color
		studs.Parent = apron
	end
	if not map:GetAttribute("RetiredLobbyPaving") and not map.SkippingWorld:FindFirstChild("MainPlazaPath") then
		local function pave(name: string, size: Vector3, pos: Vector3, color: Color3)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = size
			p.Position = pos
			p.Color = color
			p.Anchored = true
			p.CanCollide = false
			p.CanTouch = false
			p.CanQuery = false
			p.Material = Enum.Material.Plastic
			p.Parent = map.SkippingWorld
			local t = Instance.new("Texture")
			t.Texture = Config.StudTexture
			t.Face = Enum.NormalId.Top
			t.StudsPerTileU = 8
			t.StudsPerTileV = 8
			t.Transparency = 0.5
			t.Color3 = color
			t.Parent = p
			return p
		end
		pave("MainPlazaPath", V(17, 0.15, 178), V(-105, 0.17, 116), C(212, 225, 240))
		for _, z in { 123, 160 } do
			pave("EggWalkway", V(60, 0.15, 9), V(-131, 0.25, z), C(216, 230, 246))
		end
		for z = 40, 82, 21 do
			pave("ArrowStem", V(2.4, 0.08, 10), V(-105, 0.3, z), C(52, 61, 80))
			for _, side in { -1, 1 } do
				local arm = pave("ArrowArm", V(1.8, 0.08, 6), V(-105 + side * 1.8, 0.3, z - 3.5), C(52, 61, 80))
				arm.CFrame *= CFrame.Angles(0, side * math.pi / 4, 0)
			end
		end
		for i = 1, 16 do
			local x = if i % 2 == 0 then -85 else -181
			local z = 42 + math.floor(i / 2) * 18
			pave("FlowerStem", V(0.4, 1, 0.4), V(x, 0.7, z), C(61, 169, 48))
			local flower =
				pave("Flower", V(1.7, 0.4, 1.7), V(x, 1.3, z), if i % 3 == 0 then C(255, 73, 99) else C(81, 198, 255))
			flower.Shape = Enum.PartType.Ball
		end
	end
	for _, label in map.SkippingWorld:GetDescendants() do
		if label:IsA("TextLabel") and label.Text:find("↻") then
			label.Text = label.Text:gsub("↻", "RB")
		end
	end
	local admin = map.SkippingWorld:FindFirstChild("HackedAdminEgg")
	if admin and not admin:FindFirstChild("ProximityPrompt") then
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "View egg"
		pp.ObjectText = "Hacked Admin Egg • 175 Robux"
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = admin
	end
	for _, l in map.SkippingWorld:GetDescendants() do
		if l:IsA("TextLabel") and l.Text:find("COMING SOON") then
			l.Text = "Hacked Admin Egg\n175 ROBUX"
		end
	end
	map:SetAttribute("SkippingFinishVersion", 7)
end
function World.refine(map: Construction.World)
	if map:GetAttribute("SkippingRefinementVersion") == 1 then
		return
	end
	local function hide(p: BasePart)
		p.Transparency = 1
		for _, t in p:GetChildren() do
			if t:IsA("Decal") then
				t.Transparency = 1
			end
		end
	end
	for _, p in map:GetDescendants() do
		if p:IsA("BasePart") and not p:IsDescendantOf(map.SkippingWorld) then
			local source = tostring(p:GetAttribute("SurfaceSource") or p:GetFullName())
			if
				(source:find("PerimeterWalls") and (p.Position.Z < 0 or p.Name:find("Panel")))
				or source:find("CorridorBarriers")
			then
				hide(p)
			end
			if p.Position.Z < 0 and p.Position.Y > 14 and (p.Position.X < -202 or p.Position.X > -28) then
				hide(p)
			end
			if
				p.Position.Z < 0
				and p.Position.Z > -140
				and (p.Name:find("Trunk") or p.Name:find("Crown") or p.Name:find("Leaf"))
			then
				hide(p)
			end
		end
	end
	-- Aligned eight-stud checker squares, with a continuous HD stud overlay.
	for _i, info in
		{
			{ wall = map.PerimeterWalls.LobbyLeft, face = Enum.NormalId.Right },
			{ wall = map.PerimeterWalls.LobbyRight, face = Enum.NormalId.Left },
			{ wall = map.PerimeterWalls.LobbyBack, face = Enum.NormalId.Front },
		}
	do
		local wall, face = info.wall, info.face
		local width = face == Enum.NormalId.Front and wall.Size.X or wall.Size.Z
		local gui = Instance.new("SurfaceGui")
		gui.Name = "ReferenceCheckerWall"
		gui.Face = face
		gui.CanvasSize = Vector2.new(width * 16, wall.Size.Y * 16)
		gui.LightInfluence = 0.65
		gui.Active = false
		gui.Parent = wall
		for row = 0, 7 do
			for col = 0, math.ceil(width / 8) - 1 do
				local square = Instance.new("Frame")
				square.BorderSizePixel = 0
				square.Size = UDim2.fromOffset(math.min(128, width * 16 - col * 128), 128)
				square.Position = UDim2.fromOffset(col * 128, row * 128)
				local green = row < 2
				square.BackgroundColor3 = green and ((row + col) % 2 == 0 and C(98, 228, 40) or C(129, 243, 62))
					or ((row + col) % 2 == 0 and C(163, 112, 73) or C(186, 137, 91))
				square.Parent = gui
			end
		end
		local studs = Instance.new("ImageLabel")
		studs.BackgroundTransparency = 1
		studs.Size = UDim2.fromScale(1, 1)
		studs.Image = Config.StudTexture
		studs.ImageTransparency = 0.73
		studs.ScaleType = Enum.ScaleType.Tile
		studs.TileSize = UDim2.fromOffset(128, 128)
		studs.Parent = gui
	end
	for _, p in map.SkippingWorld:GetChildren() do
		if not p:IsA("BasePart") then
			continue
		end
		if p.Name == "GrassWallCrown" then
			hide(p)
		end
		if p.Name == "LabelAnchor" and p.Position.Z < 0 then
			local label = p:FindFirstChildWhichIsA("BillboardGui")
			if label then
				label.Size = UDim2.fromScale(42, 6)
				p.Position += V(0, -3, -115)
			end
		end
		if (p.Name == "PalmFrond" or p.Name == "BiomeDecorStem") and p.Position.Z > -130 and p.Position.Z < 0 then
			hide(p)
		end
	end
	local old = map.Lobby.KickZoneFloor:FindFirstChild("KickZoneLettering")
	if old and old:IsA("SurfaceGui") then
		old.Enabled = false
	end
	local apron = map.Lobby.KickZoneFloor
	-- Use the top face's actual X/Z axes to prevent stretched lettering.
	local plate = Instance.new("Part")
	plate.Name = "KickZonePrint"
	plate.Anchored = true
	plate.CanCollide = false
	plate.CanTouch = false
	plate.CanQuery = false
	plate.Transparency = 1
	plate.Size = V(140, 0.05, 16)
	plate.Position = apron.Position + V(0, 0.36, 0)
	plate.Parent = map.SkippingWorld
	local printGui = Instance.new("SurfaceGui")
	printGui.Name = "KickZoneLabel"
	printGui.Face = Enum.NormalId.Top
	printGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	printGui.CanvasSize = Vector2.new(1400, 160)
	printGui.LightInfluence = 0
	printGui.Parent = plate
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Text = "KICK ZONE"
	title.TextScaled = true
	title.Font = Enum.Font.GothamBlack
	title.TextColor3 = C(255, 252, 239)
	title.Rotation = 180
	title.Parent = printGui
	local s = Instance.new("UIStroke")
	s.Thickness = 5
	s.Color = C(20, 21, 28)
	s.Parent = title
	-- Plaza paths and flower clusters are installed by World.finish.
	map:SetAttribute("SkippingRefinementVersion", 1)
end
function World.apply(map: Construction.World): Instance?
	if map:GetAttribute("SkippingWorldVersion") == 1 then
		World.refine(map)
		World.finish(map)
		return map:FindFirstChild("SkippingWorld")
	end
	local root = Instance.new("Model")
	root.Name = "SkippingWorld"
	root.Parent = map
	local function part(
		name: string,
		size: Vector3,
		pos: Vector3,
		color: Color3,
		solid: boolean?,
		material: Enum.Material?,
		parent: Instance?
	)
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Position = pos
		p.Color = color
		p.Anchored = true
		p.Material = material or Enum.Material.Plastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.CanCollide = solid == true
		p.CanTouch = false
		p.CanQuery = solid == true
		p.Parent = parent or root
		return p
	end
	local function studs(p: BasePart, faces: { Enum.NormalId }?)
		local selectedFaces: { Enum.NormalId } = faces or { Enum.NormalId.Top }
		for _, face in selectedFaces do
			local t = Instance.new("Texture")
			t.Texture = Config.StudTexture
			t.Face = face
			t.StudsPerTileU = 8
			t.StudsPerTileV = 8
			t.Transparency = 0.35
			t.Color3 = p.Color
			t.Parent = p
		end
	end
	local function label(text: string, pos: Vector3, size: number, color: Color3, parent: Instance?)
		local anchor = part("LabelAnchor", V(0.1, 0.1, 0.1), pos, C(255, 255, 255), false, nil, parent)
		anchor.Transparency = 1
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromScale(size, 7)
		gui.MaxDistance = 450
		gui.LightInfluence = 0
		gui.Parent = anchor
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = color or C(255, 255, 255)
		l.Font = Enum.Font.GothamBlack
		l.TextScaled = true
		l.Parent = gui
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = C(20, 24, 40)
		s.Parent = l
		return l
	end
	local function hide(p: BasePart)
		p.Transparency = 1
		for _, d in p:GetChildren() do
			if d:IsA("Decal") then
				d.Transparency = 1
			elseif d:IsA("BillboardGui") then
				d.Enabled = false
			end
		end
	end
	-- Preserve the existing collision geometry, hand-placed decorations and pivots.
	for _, d in map.CorridorBarriers:GetDescendants() do
		if d:IsA("BasePart") then
			hide(d)
		end
	end
	for _, d in map.PerimeterWalls:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Position.Z < 0 or d.Name:find("Corridor") then
				hide(d)
			else
				d.Color = if d.Name:find("Panel") then C(175, 125, 79) else C(152, 105, 67)
				for _, t in d:GetChildren() do
					if t:IsA("Texture") then
						t.Color3 = d.Color
					end
				end
			end
		end
	end
	for _, wall in { map.PerimeterWalls.LobbyLeft, map.PerimeterWalls.LobbyRight, map.PerimeterWalls.LobbyBack } do
		local p = part(
			"GrassWallCrown",
			V(wall.Size.X + 0.3, 16, wall.Size.Z + 0.3),
			wall.Position + V(0, 25, 0),
			C(108, 224, 53),
			false
		)
		studs(
			p,
			{ Enum.NormalId.Top, Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }
		)
	end
	for _, d in map:GetDescendants() do
		if d:IsA("TextLabel") and d.Parent and d.Parent:IsA("BillboardGui") and not d:IsDescendantOf(root) then
			if d.Text:find("БАРЬЕР") or d.Text:find("ЗОНА") or d.Text:find("ПРЕДМЕТЫ") then
				d.Parent.Enabled = false
			end
		end
	end
	for i = 1, 7 do
		local lane = assert(map.TrainingZone:FindFirstChild("TrainingLane" .. i)) :: Construction.Lane
		local def = Config.Lanes[i]
		lane:SetAttribute("RequiredRebirths", def.rebirths)
		lane:SetAttribute("TrainingMultiplier", def.multiplier)
		lane.StartingPad:SetAttribute("LaneIndex", i)
		for _, d in lane:GetDescendants() do
			if d:IsA("BillboardGui") then
				d.Enabled = false
			end
		end
		local endX = lane.TrainingStrip.Position.X + lane.TrainingStrip.Size.X / 2 - 3
		part("LaneBoard" .. i, V(9, 7, 0.5), V(endX, 6, lane.StartingPad.Position.Z), C(26, 39, 45), false)
		local stone = part(
			"TrainingStone" .. i,
			V(2.4, 0.8, 1.8),
			lane.StartingPad.Position + V(1, 1.1, 0),
			C(137, 146, 166),
			false
		)
		stone.Shape = Enum.PartType.Ball
	end
	local apron = map.Lobby.KickZoneFloor
	local surface = Instance.new("SurfaceGui")
	surface.Name = "KickZoneLettering"
	surface.Face = Enum.NormalId.Top
	surface.CanvasSize = Vector2.new(1400, 220)
	surface.LightInfluence = 0
	surface.Parent = apron
	local txt = Instance.new("TextLabel")
	txt.Size = UDim2.fromScale(1, 1)
	txt.BackgroundTransparency = 1
	txt.Text = "KICK ZONE"
	txt.TextScaled = true
	txt.Font = Enum.Font.GothamBlack
	txt.TextColor3 = C(255, 253, 236)
	txt.Rotation = 180
	txt.Parent = surface
	local line = Instance.new("UIStroke")
	line.Thickness = 6
	line.Color = C(20, 21, 28)
	line.Parent = txt
	for _, x in { -175, -57 } do
		local pad = part("KickPad", V(11, 0.15, 9), V(x, 0.73, 12), C(48, 194, 255), false)
		studs(pad)
	end
	-- The reference uses open horizons and short, terraced banks.
	for _, d in map.FieldCorridor:GetDescendants() do
		if d:IsA("BasePart") and (d.Name:find("Gateway") or d.Name == "UIAnchor") then
			hide(d)
		end
	end
	for i, biome in Config.Biomes do
		local startZ = -(i - 1) * 180
		local centerZ = startZ - 90
		local field =
			part("Field_" .. i, V(111.6, 0.08, 180), V(-116, 0.035, centerZ), biome.color, false, Enum.Material.Glass)
		field.Transparency = 0.43
		field.Reflectance = 0.08
		field.CastShadow = false
		for _, side in { -1, 1 } do
			for tier = 1, 2 do
				local x = -116 + side * (if tier == 1 then 67 else 91)
				local y = if tier == 1 then 4 else 9
				local ground = part(
					"BiomeBank" .. i .. "_" .. tier,
					V(if tier == 1 then 22 else 26, 0.18, 180),
					V(x, y + 0.13, centerZ),
					biome.bank,
					false
				)
				studs(ground)
				if i >= 8 then
					part(
						"BankExtension",
						V(if tier == 1 then 22 else 26, y + 16, 180),
						V(x, (y - 16) / 2, centerZ),
						C(168, 121, 82),
						true
					)
				end
			end
			for j = 1, 3 do
				local pos = V(-116 + side * 90, 9, startZ - j * 49)
				local stem = part("BiomeDecorStem", V(2.5, 14, 2.5), pos + V(0, 7, 0), C(152, 105, 55), false)
				if biome.kind == "palm" then
					for k = 0, 5 do
						local angle = k * math.pi / 3
						local leaf = part(
							"PalmFrond",
							V(3, 1, 15),
							pos + V(math.sin(angle) * 5, 15, math.cos(angle) * 5),
							C(41, 188, 87),
							false
						)
						leaf.CFrame *= CFrame.Angles(0, angle, 0.2)
					end
				elseif biome.kind == "desert" then
					stem.Color = C(100, 187, 55)
					local arm = part("CactusArm", V(8, 2.5, 2.5), pos + V(side * 2, 8, 0), stem.Color, false)
					studs(stem)
					studs(arm)
				elseif biome.kind == "crystal" or biome.kind == "ice" or biome.kind == "lava" then
					stem.Color = biome.bank
					stem.Material = Enum.Material.Neon
					stem.CFrame *= CFrame.Angles(0, math.pi / 4, 0.18)
					part("CrystalSatellite", V(3, 8, 3), pos + V(4, 4, 0), biome.color, false, Enum.Material.Neon).CFrame *= CFrame.Angles(
						0,
						0.4,
						-0.25
					)
				elseif biome.kind == "moon" then
					stem.Color = C(200, 213, 255)
					stem.Size = V(1.2, 10, 1.2)
					local orb =
						part("MoonOrb", V(9, 9, 9), pos + V(0, 14, 0), C(255, 238, 144), false, Enum.Material.Neon)
					orb.Shape = Enum.PartType.Ball
				else
					local crown = part(
						"CandyCrown",
						V(10, 8, 10),
						pos + V(0, 15, 0),
						if j % 2 == 0 then C(255, 121, 217) else C(143, 123, 244),
						false
					)
					crown.Shape = Enum.PartType.Ball
				end
			end
		end
	end
	-- The river is flat parts with VFX now (tools/FlatRiverWater.luau); no Terrain water is filled here.
	part("RiverEndSafety", V(210, 80, 2), V(-116, 25, -1442), C(100, 180, 230), true).Transparency = 1
	for _, x in { -175, -57 } do
		part("BankSafetyExtension", V(2, 100, 160), V(x, 49, -1360), C(255, 255, 255), true).Transparency = 1
	end
	for _, egg in Config.BaseEggs do
		local model = Instance.new("Model")
		model.Name = "Egg_" .. egg.id
		model:SetAttribute("EggId", egg.id)
		model.Parent = root
		local base = part("EggPedestal", V(15, 1, 15), V(egg.x, 0.75, egg.z), egg.color, false, nil, model)
		studs(base)
		part("EggRing", V(11, 0.45, 11), V(egg.x, 1.5, egg.z), egg.color, false, Enum.Material.Neon, model)
		local shell = part("EggShell", V(6, 8, 6), V(egg.x, 6.2, egg.z), egg.color, false, nil, model)
		shell.Shape = Enum.PartType.Ball
		for j = 1, 3 do
			local dot = part(
				"EggSpot",
				V(1.4, 1.4, 1.4),
				shell.Position + V(math.sin(j * 2) * 2.5, (j - 2) * 1.5, -2.4),
				egg.color:Lerp(C(255, 255, 255), 0.6),
				false,
				nil,
				model
			)
			dot.Shape = Enum.PartType.Ball
		end
		label(egg.name .. "\n" .. Config.format(egg.cost) .. " Wins", V(egg.x, 13, egg.z), 22, egg.color, model)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Hatch"
		pp.ObjectText = egg.name
		pp.KeyboardKeyCode = Enum.KeyCode.E
		pp.HoldDuration = 0
		pp.MaxActivationDistance = 13
		pp.Parent = shell
	end
	-- A free pet display supplies the same moving mascot silhouette as the references.
	for i, stone in Config.Stones do
		local pedestal = map.EmptyItemStand:FindFirstChild("EmptyPedestal" .. i)
		if pedestal and pedestal:IsA("BasePart") then
			local rock = part(
				"DisplayStone_" .. stone.id,
				V(5, 2, 4),
				pedestal.Position + V(0, 2.2, 0),
				stone.color,
				false,
				nil,
				root
			)
			rock.Shape = Enum.PartType.Ball
			label(
				stone.name .. "\n+" .. stone.trainingBonus .. " Training",
				V(pedestal.Position.X, rock.Position.Y + 4, pedestal.Position.Z),
				12,
				stone.color
			)
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "View stones"
			pp.ObjectText = stone.name
			pp.MaxActivationDistance = 10
			pp.Parent = rock
			pp:SetAttribute("OpenInventory", true)
		end
	end
	label("BEST IN GAME\nAlways one step ahead!", V(-175, 20, 196), 38, C(255, 206, 53))
	local hacked = part("HackedEggStand", V(12, 1, 12), V(-90, 1, 39), C(30, 45, 25), false)
	studs(hacked)
	local hackedEgg = part("HackedAdminEgg", V(5, 7, 5), V(-90, 5.6, 39), C(16, 26, 21), false)
	hackedEgg.Shape = Enum.PartType.Ball
	for i = 1, 6 do
		local patch = part(
			"HackedPixel",
			V(1.2, 1.6, 0.3),
			V(-90 + math.sin(i) * 2, 4 + i * 0.4, 36.5),
			C(125, 255, 0),
			false,
			Enum.Material.Neon
		)
		patch.CFrame *= CFrame.Angles(0, 0, i * 0.7)
	end
	label("Hacked Admin Egg\n175 ROBUX", V(-90, 12, 39), 23, C(120, 255, 65))
	root.WorldPivot = CFrame.new(-116, 0, 112)
	map:SetAttribute("SkippingWorldVersion", 1)
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 13.5
	lighting.Brightness = 2.5
	lighting.Ambient = C(152, 170, 180)
	lighting.OutdoorAmbient = C(170, 181, 191)
	lighting.FogStart = 700
	lighting.FogEnd = 2400
	lighting.FogColor = C(150, 220, 237)
	World.refine(map)
	World.finish(map)
	return root
end
return World
