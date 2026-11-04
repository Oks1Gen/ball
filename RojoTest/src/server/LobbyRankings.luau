--!strict
local Construction = require(script.Parent.ConstructionTypes)
local Rankings = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local WorldRefs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local Palette = require(script.Parent.LobbyPalette)
local Layout = require(script.Parent.WorldLayout)
local C, V = Color3.fromRGB, Vector3.new
-- `reserved` names the placeholder the lobby layout cloned for a board the original
-- builder never had; the style takes it over under the category key.
local categories = {
	{ key = "skill", title = "TOP SKILL", color = C(66, 219, 255) },
	{ key = "wins", title = "TOP WINS", color = C(255, 209, 65) },
	{ key = "best", title = "BEST THROW", color = C(184, 116, 255), suffix = " m" },
	{ key = "donated", title = "ДОНАТ", color = C(255, 101, 152), reserved = "ReservedFourthBoard" },
}
local stores, cached, names = {}, {}, {}
-- Every profile save would write the ordered data stores, but Roblox refuses
-- a second write to the same key within six seconds. The last written value is
-- remembered per user and category, so an unchanged board costs no write.
local written: { [number]: { [string]: number }? } = {}
local writtenOrder: { number } = {}
local WRITTEN_LIMIT = 200
local started = false

-- The cache has to stay small: the oldest user is dropped when it grows over
-- the limit, and a leaving player is removed right away.
local function forget(userId: number)
	if not written[userId] then
		return
	end
	written[userId] = nil
	for index, id in writtenOrder do
		if id == userId then
			table.remove(writtenOrder, index)
			break
		end
	end
end

local function remember(userId: number, category: string, value: number)
	local entry: { [string]: number } = written[userId] or {}
	if not written[userId] then
		table.insert(writtenOrder, userId)
		while #writtenOrder > WRITTEN_LIMIT do
			local oldest = table.remove(writtenOrder, 1)
			if oldest then
				written[oldest] = nil
			end
		end
	end
	written[userId] = entry
	entry[category] = value
end

Players.PlayerRemoving:Connect(function(player)
	forget(player.UserId)
end)

function Rankings.apply(map: Construction.World)
	if map:FindFirstChild("LobbyRankings") then
		return
	end
	local frame = map.Lobby.KickZoneFloor.CFrame * CFrame.new(115, -0.3, -13)
	local oldPosition = frame:PointToWorldSpace(V(-104, 20, 205))
	local group = Instance.new("Model")
	group.Name = "LobbyRankings"
	local function part(parent, name, size, cf, color)
		local p = Instance.new("Part")
		p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
		p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
		p.Material = Enum.Material.Plastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = parent
		return p
	end
	local function text(parent, name, value, y, height, color, font: Enum.Font?)
		local label = Instance.new("TextLabel")
		label.Name, label.Text = name, value
		label.Position, label.Size = UDim2.fromScale(0.05, y), UDim2.fromScale(0.9, height)
		label.BackgroundTransparency = 1
		label.Font, label.TextColor3 = font or Enum.Font.GothamBold, color
		label.TextScaled = true
		label.Parent = parent
		return label
	end
	for index, category in categories do
		if category.reserved then
			continue
		end
		local board = Instance.new("Model")
		board.Name = category.key
		board.Parent = group
		local center = V(oldPosition.X + (index - 2) * 30, frame.Position.Y + 18, oldPosition.Z)
		local cf = CFrame.new(center) * frame.Rotation
		part(board, "Foot", V(27, 0.8, 7), cf * CFrame.new(0, -17.5, 0), C(35, 56, 105))
		for _, x in { -9, 9 } do
			part(board, "Support", V(1.8, 5, 2), cf * CFrame.new(x, -15, 0), category.color)
		end
		part(board, "Frame", V(26, 31, 2.2), cf, category.color)
		local panel = part(board, "Panel", V(24.8, 29.8, 2.4), cf * CFrame.new(0, 0, -0.1), C(21, 31, 64))
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RankingGui"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(620, 745)
		gui.LightInfluence = 0
		gui.Active = false
		gui.Parent = panel
		text(gui, "Title", category.title, 0.025, 0.085, category.color, Enum.Font.GothamBlack)
		text(gui, "Scope", "GLOBAL TOP 10", 0.115, 0.035, C(178, 198, 225))
		for rank = 1, 10 do
			local row = Instance.new("Frame")
			row.Name = "Row" .. rank
			row.Position = UDim2.fromScale(0.04, 0.17 + (rank - 1) * 0.072)
			row.Size = UDim2.fromScale(0.92, 0.066)
			row.BackgroundColor3 = rank % 2 == 0 and C(31, 46, 84) or C(39, 57, 99)
			row.BorderSizePixel = 0
			row.Parent = gui
			local label =
				text(row, "Entry", rank .. ".   —", 0.08, 0.84, rank <= 3 and C(255, 224, 135) or C(235, 244, 255))
			label.TextXAlignment = Enum.TextXAlignment.Left
		end
		text(gui, "Status", "Waiting for players", 0.91, 0.055, C(170, 191, 224))
		local crown = part(board, "CrownBase", V(8, 1.2, 1.8), cf * CFrame.new(0, 16.3, 0), C(255, 208, 58))
		for _, x in { -3, 0, 3 } do
			part(
				board,
				"CrownPoint",
				V(1.6, x == 0 and 3 or 2.1, 1.8),
				crown.CFrame * CFrame.new(x, 1.6, 0),
				C(255, 208, 58)
			)
		end
		board.WorldPivot = cf
	end
	group.WorldPivot = CFrame.new(oldPosition)
	group.Parent = map
	return group
end

-- Stand look: docs/leaderboards.md. Sizes are studs of the 0.6 scene and follow
-- Shared.WorldScale like the rest of the lobby.
local STYLE = 9
local MEASURED = 0.6
local SIZE = {
	-- Every stand stays centred on its egg; neighbours and the waterfall keep a 0.2 gap,
	-- and the egg plaza measured from the stands keeps its approved cells.
	width = 17.6,
	rim = 0.2, -- dark outline of the body and the header
	-- Rounded outer corners (bottom of the body, top of the header), concentric with
	-- the rounded title band and table drawn on them.
	corner = 1,
	border = 1, -- coloured frame around the table
	-- Short legs, as the user asked (2026-11-04): the table starts low behind the eggs.
	bodyBottom = 3.6,
	bodyHeight = 21.6,
	headerHeight = 5.2,
	headerOverlap = 0.8,
	-- Two short legs near the sides, joined below by one base under the whole stand
	-- (user's sample, 2026-11-04).
	legX = 6,
	plinthWidth = 14, -- lobby studs
	-- The plinth front keeps the old stand foot's line: the egg plaza ends at the
	-- front-most stand part (LobbyPaths), so its cells stay the same.
	plinthFront = 2.1,
	-- SurfaceGui pixels per stud of the table and the title.
	canvas = 50,
}
local INK = C(16, 19, 31)
local WHITE = C(255, 255, 255)
local THEMES = {
	skill = {
		accent = C(38, 178, 246),
		rim = C(12, 92, 170),
		band = C(16, 104, 186),
		icon = "rbxassetid://121378767438034",
	},
	wins = {
		accent = C(255, 186, 30),
		rim = C(178, 98, 6),
		band = C(196, 112, 10),
		icon = "rbxassetid://114161247280750",
	},
	best = {
		accent = C(152, 84, 240),
		rim = C(84, 36, 158),
		band = C(98, 46, 182),
		icon = "rbxassetid://81860763257111",
	},
	donated = {
		accent = C(244, 72, 152),
		rim = C(150, 22, 90),
		band = C(176, 30, 108),
		icon = "rbxassetid://90468580391337",
	},
}
-- Gold, silver and bronze plates for the first three places.
local MEDALS = { C(255, 197, 31), C(196, 206, 220), C(236, 132, 46) }

local function solid(
	parent: Instance,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	shape: Enum.PartType?
): BasePart
	local p = Instance.new("Part")
	p.Shape = shape or Enum.PartType.Block
	p.Name, p.Size, p.CFrame, p.Color = name, size, cf, color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

-- A plate with rounded corners of `radius` at the chosen ends. The corner cylinders
-- are 0.01 thinner on each face, so they never share a face plane with the blocks.
local function plate(
	parent: Instance,
	name: string,
	cf: CFrame,
	size: Vector3,
	radius: number,
	top: boolean,
	bottom: boolean,
	color: Color3,
	collide: boolean
)
	local model = Instance.new("Model")
	model.Name = name
	local w, h, d = size.X, size.Y, size.Z
	local parts = { solid(model, "Centre", V(w - 2 * radius, h, d), cf, color) }
	local roundTop, roundBottom = if top then radius else 0, if bottom then radius else 0
	for _, sx in { -1, 1 } do
		local side = cf * CFrame.new(sx * (w - radius) / 2, (roundBottom - roundTop) / 2, 0)
		table.insert(parts, solid(model, "Side", V(radius, h - roundTop - roundBottom, d), side, color))
		for _, sy in { -1, 1 } do
			if (sy > 0 and top) or (sy < 0 and bottom) then
				-- A cylinder's axis is its X: turn it to run through the plate's depth.
				local corner = CFrame.new(sx * (w / 2 - radius), sy * (h / 2 - radius), 0)
					* CFrame.Angles(0, math.pi / 2, 0)
				table.insert(
					parts,
					solid(
						model,
						"Corner",
						V(d - 0.02, 2 * radius, 2 * radius),
						cf * corner,
						color,
						Enum.PartType.Cylinder
					)
				)
			end
		end
	end
	for _, p in parts do
		p.CanCollide, p.CanQuery = collide, collide
	end
	model.WorldPivot = cf
	model.Parent = parent
end

-- Lobby studs; stand sizes are whole studs, so every face shows complete rows.
local function studs(p: BasePart, pitch: number)
	for _, face in Enum.NormalId:GetEnumItems() do
		if face ~= Enum.NormalId.Bottom then
			local t = Instance.new("Texture")
			t.Name, t.Texture, t.Face = "StandStuds", Palette.Studs, face
			t.StudsPerTileU = pitch * Palette.StudsPerTexture
			t.StudsPerTileV = pitch * Palette.StudsPerTexture
			t.Transparency, t.Parent = Palette.StudsTransparency, p
		end
	end
end

-- An invisible face that only carries a SurfaceGui in front of the visible plates.
local function surface(parent: Instance, name: string, size: Vector3, cf: CFrame, purpose: string): BasePart
	local p = solid(parent, name, size, cf, INK)
	p.Transparency, p.CastShadow = 1, false
	p:SetAttribute("PartRole", "LabelAnchor")
	p:SetAttribute("Purpose", purpose)
	return p
end

local function round(parent: Instance, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = radius, parent
end

local function stroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local line = Instance.new("UIStroke")
	line.Color, line.Thickness, line.Parent = color, thickness, parent
	return line
end

local function label(
	parent: Instance,
	name: string,
	value: string,
	position: UDim2,
	size: UDim2,
	textSize: number,
	font: Enum.Font,
	alignment: Enum.TextXAlignment?
): TextLabel
	local item = Instance.new("TextLabel")
	item.Name, item.Text = name, value
	item.Position, item.Size = position, size
	item.BackgroundTransparency = 1
	item.Font, item.TextSize, item.TextColor3 = font, textSize, WHITE
	item.TextXAlignment = alignment or Enum.TextXAlignment.Left
	item.TextTruncate = Enum.TextTruncate.AtEnd
	item.Parent = parent
	return item
end

local function surfaceGui(part: BasePart, name: string, canvas: Vector2): SurfaceGui
	local gui = Instance.new("SurfaceGui")
	gui.Name, gui.Face, gui.CanvasSize = name, Enum.NormalId.Front, canvas
	gui.LightInfluence, gui.Brightness, gui.Active = 0, 1, false
	-- Children always draw above their parent, rows above the screen behind them.
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = part
	return gui
end

-- Ten dark rows: medal or number, avatar, name and result (filled by render).
-- `canvas` follows the panel's proportions; rows share its height evenly.
local function tableGui(panel: BasePart, canvas: Vector2)
	local gui = surfaceGui(panel, "RankingGui", canvas)
	local screen = Instance.new("Frame")
	screen.Name = "Screen"
	screen.Position, screen.Size = UDim2.fromOffset(5, 5), UDim2.fromOffset(canvas.X - 10, canvas.Y - 10)
	screen.BackgroundColor3, screen.BorderSizePixel = C(21, 26, 43), 0
	screen.Parent = gui
	round(screen, UDim.new(0, 24))
	stroke(screen, INK, 5)
	local pad, gap = 26, 10
	local width = canvas.X - 40
	local height = math.floor((canvas.Y - 2 * pad - 9 * gap) / 10)
	local function middle(size: number): number
		return math.floor((height - size) / 2)
	end
	for rank = 1, 10 do
		local row = Instance.new("Frame")
		row.Name = "Row" .. rank
		row.Position = UDim2.fromOffset(20, pad + (rank - 1) * (height + gap))
		row.Size = UDim2.fromOffset(width, height)
		row.BackgroundColor3 = if rank % 2 == 1 then C(38, 47, 73) else C(31, 39, 61)
		row.BorderSizePixel, row.ZIndex = 0, 2
		row.Parent = gui
		round(row, UDim.new(0, 14))
		local medal = MEDALS[rank]
		local number = label(
			row,
			"Rank",
			tostring(rank),
			UDim2.fromOffset(10, middle(62)),
			UDim2.fromOffset(62, 62),
			40,
			Enum.Font.GothamBlack,
			Enum.TextXAlignment.Center
		)
		if medal then
			number.BackgroundTransparency, number.BackgroundColor3, number.TextColor3 = 0, medal, INK
			round(number, UDim.new(0, 12))
			stroke(number, INK, 3).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		end
		local avatar = Instance.new("ImageLabel")
		avatar.Name, avatar.Image, avatar.ScaleType = "Avatar", "", Enum.ScaleType.Crop
		avatar.Position, avatar.Size = UDim2.fromOffset(86, middle(66)), UDim2.fromOffset(66, 66)
		avatar.BackgroundColor3, avatar.BorderSizePixel = C(54, 64, 96), 0
		avatar.Parent = row
		round(avatar, UDim.new(1, 0))
		stroke(avatar, INK, 3)
		local value = 220
		label(
			row,
			"Entry",
			"—",
			UDim2.fromOffset(168, 0),
			UDim2.fromOffset(width - 168 - value - 22, height),
			40,
			Enum.Font.GothamBold
		)
		-- Up to 999,999,999 must fit: a long number gets smaller instead of cut off.
		local result = label(
			row,
			"Value",
			"",
			UDim2.fromOffset(width - value - 14, middle(44)),
			UDim2.fromOffset(value, 44),
			40,
			Enum.Font.GothamBlack,
			Enum.TextXAlignment.Right
		)
		result.TextScaled, result.TextTruncate = true, Enum.TextTruncate.None
		local limit = Instance.new("UITextSizeConstraint")
		limit.MaxTextSize, limit.Parent = 40, result
	end
end

local function headerGui(part: BasePart, canvas: Vector2, title: string, theme: any)
	local gui = surfaceGui(part, "HeaderGui", canvas)
	local band = Instance.new("Frame")
	band.Name = "Band"
	band.Position, band.Size = UDim2.fromOffset(24, 24), UDim2.fromOffset(canvas.X - 48, canvas.Y - 48)
	band.BackgroundColor3, band.BorderSizePixel = theme.band, 0
	band.Parent = gui
	round(band, UDim.new(0, 28))
	stroke(band, theme.rim, 4)
	-- The category icon stands just left of the title (user's request); the pair is
	-- centred on the band.
	-- The largest text size that leaves room for the icon is measured, not scaled.
	local inner = band.Size.Y.Offset
	local iconSize, gap, outline = inner - 50, 18, 7
	local room = band.Size.X.Offset - 40 - iconSize - gap - 2 * outline
	local size, bounds = 100, Vector2.zero -- 100 is the largest TextSize
	repeat
		bounds = TextService:GetTextSize(title, size, Enum.Font.GothamBlack, Vector2.new(10000, 1000))
		size -= 2
	until bounds.X <= room or size < 40
	local textWidth = bounds.X + 2 * outline
	local left = math.floor((band.Size.X.Offset - iconSize - gap - textWidth) / 2)
	local icon = Instance.new("ImageLabel")
	icon.Name, icon.Image, icon.ScaleType = "CategoryIcon", theme.icon, Enum.ScaleType.Fit
	icon.Position = UDim2.fromOffset(left, math.floor((inner - iconSize) / 2))
	icon.Size = UDim2.fromOffset(iconSize, iconSize)
	icon.BackgroundTransparency = 1
	icon.Parent = band
	local heading = label(
		band,
		"Title",
		title,
		UDim2.fromOffset(left + iconSize + gap, 0),
		UDim2.fromOffset(textWidth, inner),
		size + 2,
		Enum.Font.GothamBlack,
		Enum.TextXAlignment.Center
	)
	heading.TextTruncate = Enum.TextTruncate.None
	stroke(heading, INK, outline).LineJoinMode = Enum.LineJoinMode.Round
end

-- Ground centre of a stand facing the lobby: the old Frame gives the centre and the
-- facing, the lowest old part gives the ground. A stand built by an earlier style
-- keeps that ground pivot as its WorldPivot.
local function anchor(board: Model): CFrame
	local frame = board:FindFirstChild("Frame")
	if not frame and board:GetAttribute("RankingStyle") ~= nil then
		return board.WorldPivot
	end
	assert(frame and frame:IsA("BasePart"), "Leaderboard frame missing: " .. board.Name)
	local ground = math.huge
	for _, p in board:GetDescendants() do
		if p:IsA("BasePart") then
			local cf, s = p.CFrame, p.Size / 2
			local extent = math.abs(cf.RightVector.Y) * s.X
				+ math.abs(cf.UpVector.Y) * s.Y
				+ math.abs(cf.LookVector.Y) * s.Z
			ground = math.min(ground, p.Position.Y - extent)
		end
	end
	local at = V(frame.Position.X, ground, frame.Position.Z)
	local look = frame.CFrame.LookVector
	return CFrame.lookAt(at, at + V(look.X, 0, look.Z))
end

-- Body, table and header with icon and title; returns the ground pivot.
local function build(board: Model, title: string, theme: any, u: number): CFrame
	local base = anchor(board)
	board:ClearAllChildren()
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x * u, y * u, z * u)
	end
	local w, r, corner = SIZE.width, SIZE.rim, SIZE.corner
	local face = w - 2 * r
	-- A concentric outline corner keeps one outline width around the curve.
	local rimCorner = corner + r
	local bodyY = SIZE.bodyBottom + SIZE.bodyHeight / 2
	local headerBottom = SIZE.bodyBottom + SIZE.bodyHeight - SIZE.headerOverlap
	local headerY = headerBottom + SIZE.headerHeight / 2

	-- Body: a dark outline plate behind the coloured one; the table is drawn on Panel.
	plate(
		board,
		"BodyRim",
		at(0, bodyY, 0.2),
		V(w, SIZE.bodyHeight + 2 * r, 1.6) * u,
		rimCorner * u,
		false,
		true,
		theme.rim,
		true
	)
	plate(
		board,
		"Body",
		at(0, bodyY, 0),
		V(face, SIZE.bodyHeight, 1.6) * u,
		corner * u,
		false,
		true,
		theme.accent,
		false
	)
	local inner = face - 2 * SIZE.border
	local panelBottom, panelTop = SIZE.bodyBottom + SIZE.border, headerBottom - 0.5
	local panel = surface(
		board,
		"Panel",
		V(inner, panelTop - panelBottom, 0.04) * u,
		at(0, (panelBottom + panelTop) / 2, -0.825),
		"Carries the leaderboard table (RankingGui)"
	)
	tableGui(panel, Vector2.new(inner, panelTop - panelBottom) * SIZE.canvas)

	-- Header cap, slightly in front of the body, with the title on a darker band.
	plate(
		board,
		"HeaderRim",
		at(0, headerY, 0.1),
		V(w, SIZE.headerHeight + 2 * r, 1.9) * u,
		rimCorner * u,
		true,
		false,
		theme.rim,
		true
	)
	plate(
		board,
		"Header",
		at(0, headerY, -0.1),
		V(face, SIZE.headerHeight, 1.9) * u,
		corner * u,
		true,
		false,
		theme.accent,
		false
	)
	local heading = surface(
		board,
		"HeaderSurface",
		V(face, SIZE.headerHeight, 0.04) * u,
		at(0, headerY, -1.075),
		"Carries the leaderboard title (HeaderGui)"
	)
	headerGui(heading, Vector2.new(face, SIZE.headerHeight) * SIZE.canvas, title, theme)
	return base
end

local function stand(board: Model, base: CFrame, u: number, pitch: number)
	local model = Instance.new("Model")
	model.Name = "Stand"
	-- Whole studs: the legs reach 0.4 into the body from the plinth top.
	local rows = math.ceil(((SIZE.bodyBottom + 0.4) * u - pitch) / pitch)
	local z = 0.1 * u
	local parts = {
		solid(
			model,
			"Plinth",
			V(SIZE.plinthWidth, 1, 3) * pitch,
			base * CFrame.new(0, pitch / 2, -SIZE.plinthFront * u + 1.5 * pitch),
			Palette.PathEdge
		),
	}
	for _, side in { -1, 1 } do
		local x = side * SIZE.legX * u
		table.insert(
			parts,
			solid(
				model,
				"Leg",
				V(2 * pitch, rows * pitch, pitch),
				base * CFrame.new(x, pitch + rows * pitch / 2, z),
				Palette.Stone
			)
		)
	end
	for _, p in parts do
		p.CanCollide, p.CanQuery = true, true
		studs(p, pitch)
	end
	model.WorldPivot = base
	model.Parent = board
end

-- Rebuild every stand once per style version; the board names and Panel.RankingGui
-- rows are the data paths render() fills.
function Rankings.style(map)
	local group = WorldRefs.rankings(map)
	if not group then
		return
	end
	local k = Scale.factor(map)
	local u = k / MEASURED
	local pitch = Palette.GroundStudPitch * k
	for _, category in categories do
		local board = group:FindFirstChild(category.key)
		if not board and category.reserved then
			board = group:FindFirstChild(category.reserved)
			if board then
				board.Name = category.key
				board:SetAttribute("LayoutPlaceholder", nil)
			end
		end
		if not board or not board:IsA("Model") then
			continue
		end
		-- WorldLayout.prepare returns the old stand's hidden originals (their visible
		-- copies are gone with the restyle); park them outside Workspace again.
		for _, child in board:GetChildren() do
			if child:IsA("BasePart") and child.Transparency == 1 and child:GetAttribute("SurfaceSeparationId") then
				Layout.retire(map, child)
			end
		end
		if board:GetAttribute("RankingStyle") == STYLE then
			continue
		end
		local theme = THEMES[category.key]
		local base = build(board, category.title, theme, u)
		stand(board, base, u, pitch)
		board.WorldPivot = base
		-- The stand draws its own non-overlapping parts; old surface records do not apply.
		board:SetAttribute("SurfaceSeparationSkip", true)
		board:SetAttribute("RankingStyle", STYLE)
	end
end

local function getStore(key)
	if not stores[key] then
		stores[key] = DataStoreService:GetOrderedDataStore("StoneSkipping_Top_" .. Config.DataVersion .. "_" .. key)
	end
	return stores[key]
end

function Rankings.record(userId, data)
	if RunService:IsStudio() or userId <= 0 then
		return
	end
	for _, category in categories do
		local value = Data.bound(data[category.key] or 0)
		local entry = written[userId]
		if entry and entry[category.key] == value then
			continue
		end
		local ok, err = pcall(function()
			getStore(category.key):SetAsync(tostring(userId), value)
		end)
		if not ok then
			warn("Leaderboard save failed for " .. category.key .. ": " .. tostring(err))
		else
			-- Only a write that reached the store counts as written, so a
			-- refused write is retried on the next save.
			remember(userId, category.key, value)
		end
	end
end

-- Whole numbers with thousands separators; huge values use the game's short form.
local function amount(value: number): string
	if value >= 1e9 then
		return Config.format(value)
	end
	local grouped = tostring(math.floor(value)):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (grouped:gsub("^,", ""))
end

local function headshot(userId: number): string
	return if userId > 0 then string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId) else ""
end

function Rankings.render(map, states)
	local group = assert(WorldRefs.rankings(map))
	for _, category in categories do
		local board: any = group:FindFirstChild(category.key)
		local panel: any = board and board:FindFirstChild("Panel")
		local gui: any = panel and panel:FindFirstChild("RankingGui")
		if not gui then
			continue
		end
		local entries = {}
		for _, entry in cached[category.key] or {} do
			entries[entry.userId] = table.clone(entry)
		end
		for player, state in states do
			local data = state.data
			if player.Parent then
				entries[player.UserId] =
					{ userId = player.UserId, name = player.DisplayName, value = math.floor(data[category.key] or 0) }
			end
		end
		-- A zero result is not a place on the board (most players never donate).
		local sorted = {}
		for _, entry in entries do
			if entry.value > 0 then
				table.insert(sorted, entry)
			end
		end
		table.sort(sorted, function(a, b)
			if a.value == b.value then
				return a.userId < b.userId
			end
			return a.value > b.value
		end)
		for rank = 1, 10 do
			local entry = sorted[rank]
			local row = gui:FindFirstChild("Row" .. rank)
			if not row then
				continue
			end
			row.Entry.Text = entry and (entry.name or names[entry.userId] or ("User " .. entry.userId)) or "—"
			row.Value.Text = entry and (amount(entry.value) .. (category.suffix or "")) or ""
			local avatar = row:FindFirstChild("Avatar")
			if avatar then
				avatar.Image = if entry then headshot(entry.userId) else ""
			end
		end
	end
end

function Rankings.start(map, states)
	if started then
		return
	end
	started = true
	Rankings.render(map, states)
	task.spawn(function()
		while map.Parent do
			if not RunService:IsStudio() then
				for _, category in categories do
					local ok, page = pcall(function()
						return getStore(category.key):GetSortedAsync(false, 10, 1)
					end)
					if ok then
						local entries = {}
						for _, record in page:GetCurrentPage() do
							local id = tonumber(record.key)
							if id then
								if not names[id] then
									local found, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
									if found then
										names[id] = name
									end
								end
								table.insert(entries, { userId = id, value = record.value })
							end
						end
						cached[category.key] = entries
					else
						warn("Leaderboard read failed for " .. category.key .. ": " .. tostring(page))
					end
				end
			end
			Rankings.render(map, states)
			task.wait(120)
		end
	end)
	task.spawn(function()
		while map.Parent do
			task.wait(10)
			Rankings.render(map, states)
		end
	end)
end

return Rankings
