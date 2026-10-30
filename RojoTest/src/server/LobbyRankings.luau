--!strict
local Rankings = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Data = require(game.ReplicatedStorage.Shared.Core.ProfileData)
local C, V = Color3.fromRGB, Vector3.new
local categories = {
	{ key = "skill", title = "TOP SKILL", color = C(66, 219, 255) },
	{ key = "wins", title = "TOP WINS", color = C(255, 209, 65) },
	{ key = "best", title = "BEST THROW", color = C(184, 116, 255), suffix = " m" },
}
local stores, cached, names = {}, {}, {}
-- Every profile save would write three ordered data stores, but Roblox refuses
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

function Rankings.apply(map)
	if map:FindFirstChild("LobbyRankings") then
		return
	end
	local portal = assert(map.SkippingWorld:FindFirstChild("World2Portal"))
	local field = assert(portal:FindFirstChild("PortalField"))
	local frame = map.Lobby.ThrowingApron.CFrame * CFrame.new(115, -0.3, -13)
	local oldPosition = field.Position
	local target = frame:PointToWorldSpace(V(-155, 20, 60))
	portal:PivotTo(portal:GetPivot() + (target - field.Position))
	local facing = CFrame.new(field.Position) * CFrame.Angles(0, math.rad(-135), 0)
	portal:PivotTo(facing * field.CFrame:Inverse() * portal:GetPivot())
	local prompt = assert(field:FindFirstChildWhichIsA("ProximityPrompt", true))
	local attachment = prompt.Parent
	assert(attachment:IsA("Attachment"), "Portal needs its ground-level prompt")
	local promptPoint = frame:PointToWorldSpace(V(-155, 4, 60))
	attachment.Position = field.CFrame:PointToObjectSpace(promptPoint)
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

-- Restyle only the ranking stands; keep their authored placement and data paths.
function Rankings.style(map)
	local group = map:FindFirstChild("LobbyRankings")
	if not group then
		return
	end
	local accents = { skill = C(37, 177, 255), wins = C(255, 187, 26), best = C(164, 90, 248) }
	local ink = C(24, 29, 44)
	local function label(parent, name, value, x, y, width, height, size, color, alignment: Enum.TextXAlignment?)
		local item = Instance.new("TextLabel")
		item.Name, item.Text = name, value
		item.Position, item.Size = UDim2.fromOffset(x, y), UDim2.fromOffset(width, height)
		item.BackgroundTransparency = 1
		item.Font, item.TextSize, item.TextColor3 = Enum.Font.GothamBold, size, color
		item.TextXAlignment = alignment or Enum.TextXAlignment.Left
		item.TextTruncate = Enum.TextTruncate.AtEnd
		item.Parent = parent
		return item
	end
	for _, board in group:GetChildren() do
		local panel = board:FindFirstChild("Panel")
		if not panel or not panel:IsA("BasePart") or board:GetAttribute("RankingStyle") == 4 then
			continue
		end
		local accent = accents[board.Name] or C(255, 101, 152)
		local oldGui = panel:FindFirstChild("RankingGui")
		local title = oldGui and oldGui:FindFirstChild("Title")
		local titleText = title and title:IsA("TextLabel") and title.Text or "LEADERBOARD"
		for _, item in board:GetChildren() do
			if item.Name == "CrownBase" or item.Name == "CrownPoint" or item.Name == "CartoonTrim" then
				item:Destroy()
			elseif item:IsA("BasePart") then
				item.Material = Enum.Material.SmoothPlastic
				item.Reflectance = 0
				item.Color = item == panel and C(230, 241, 250) or ink
			end
		end
		local trim = Instance.new("Folder")
		trim.Name, trim.Parent = "CartoonTrim", board
		local frame = board:FindFirstChild("Frame")
		assert(frame and frame:IsA("BasePart"), "Ranking frame missing")
		local cf = frame.CFrame
		local function brick(name, size, offset, color, angle: number?)
			local p = Instance.new("Part")
			p.Name, p.Size = name, size
			p.CFrame = cf * CFrame.new(offset) * CFrame.Angles(0, 0, math.rad(angle or 0))
			p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
			p.Material, p.Color = Enum.Material.Plastic, color
			p.TopSurface, p.BottomSurface = Enum.SurfaceType.Studs, Enum.SurfaceType.Smooth
			p.Parent = trim
			if color ~= ink then
				for _, face in { Enum.NormalId.Front, Enum.NormalId.Left, Enum.NormalId.Right } do
					local studs = Instance.new("Texture")
					studs.Name, studs.Texture = "Studs", "rbxassetid://88156646156237"
					studs.Face, studs.Color3 = face, color
					studs.StudsPerTileU, studs.StudsPerTileV = 8, 8
					studs.Transparency = 0.15
					studs.Parent = p
				end
			end
			return p
		end
		for _, side in { -1, 1 } do
			brick("SideRail", V(1.7, 29, 3), V(side * 12.5, 0, -0.1), accent)
			for _, y in { -13, 11.8 } do
				brick("CornerOutline", V(2.9, 3.8, 3.4), V(side * 12.2, y, -0.2), ink, 0)
				brick("CornerCap", V(2.3, 3.2, 3.7), V(side * 12.2, y, -0.3), accent:Lerp(C(255, 255, 255), 0.3), 0)
			end
			brick("ShoeOutline", V(7, 1.4, 5.5), V(side * 8, -16.6, 0), ink)
			brick("Shoe", V(6.2, 1.1, 5), V(side * 8, -16.3, -0.1), accent)
		end
		brick("BottomRail", V(24, 1.5, 3), V(0, -14.5, -0.15), accent)
		local tilt = 0
		brick("HeaderOutline", V(28, 6.2, 3.8), V(0, 15.3, -0.4), ink, tilt)
		local header = brick("Header", V(27, 5.2, 4.1), V(0, 15.3, -0.6), accent, tilt)
		local headerGui = Instance.new("SurfaceGui")
		headerGui.Name, headerGui.Face = "HeaderGui", Enum.NormalId.Front
		headerGui.CanvasSize, headerGui.LightInfluence = Vector2.new(675, 130), 0
		headerGui.Parent = header
		local headerText =
			label(headerGui, "Title", titleText, 14, 7, 647, 116, 72, C(255, 255, 255), Enum.TextXAlignment.Center)
		headerText.Font = Enum.Font.GothamBlack
		headerText.TextStrokeColor3, headerText.TextStrokeTransparency = ink, 0
		-- Reuse the game's original icons on a raised round brick.
		local badgeBack = brick("BadgeOutline", V(1.4, 6.5, 6.5), V(0, 21, -0.2), ink)
		badgeBack.Shape = Enum.PartType.Cylinder
		badgeBack.CFrame = cf * CFrame.new(0, 21, -0.2) * CFrame.Angles(0, math.pi / 2, 0)
		local badge = brick("Badge", V(1.7, 5.7, 5.7), V(0, 21, -0.4), accent)
		badge.Shape = Enum.PartType.Cylinder
		badge.CFrame = cf * CFrame.new(0, 21, -0.4) * CFrame.Angles(0, math.pi / 2, 0)
		local badgeGui = Instance.new("SurfaceGui")
		badgeGui.Name, badgeGui.Face = "BadgeGui", Enum.NormalId.Right
		badgeGui.CanvasSize, badgeGui.LightInfluence = Vector2.new(160, 160), 0
		badgeGui.Parent = badge
		local icon = Instance.new("ImageLabel")
		icon.Name, icon.BackgroundTransparency = "CategoryIcon", 1
		icon.Size, icon.Position = UDim2.fromOffset(136, 136), UDim2.fromOffset(12, 12)
		icon.Image = ({
			skill = "rbxassetid://121378767438034",
			wins = "rbxassetid://114161247280750",
			best = "rbxassetid://81860763257111",
		})[board.Name] or "rbxassetid://90468580391337"
		icon.Parent = badgeGui
		if oldGui then
			oldGui:Destroy()
		end
		local gui = Instance.new("SurfaceGui")
		gui.Name = "RankingGui"
		gui.Face = Enum.NormalId.Front
		gui.CanvasSize = Vector2.new(620, 745)
		gui.LightInfluence, gui.Brightness = 0, 1
		gui.Active = false
		gui.Parent = panel
		local stripe = Instance.new("Frame")
		stripe.Name = "CategoryLine"
		stripe.Size = UDim2.new(1, 0, 0, 6)
		stripe.BackgroundColor3, stripe.BorderSizePixel = accent, 0
		stripe.Parent = gui
		local heading = label(gui, "Title", titleText, 28, 24, 564, 52, 38, C(239, 237, 228))
		heading.Visible = false -- The title is on the raised brick above the panel.
		local scope = label(gui, "Scope", "GLOBAL TOP 10", 30, 80, 560, 30, 22, ink, Enum.TextXAlignment.Center)
		label(gui, "RankHeading", "#", 30, 129, 44, 26, 18, ink)
		label(gui, "PlayerHeading", "PLAYER", 91, 129, 300, 26, 18, ink)
		label(gui, "ValueHeading", "RESULT", 413, 129, 177, 26, 18, ink, Enum.TextXAlignment.Right)
		for rank = 1, 10 do
			local row = Instance.new("Frame")
			row.Name = "Row" .. rank
			row.Position, row.Size = UDim2.fromOffset(20, 165 + (rank - 1) * 49), UDim2.fromOffset(580, 47)
			row.BackgroundColor3 = rank % 2 == 0 and C(242, 248, 255) or accent:Lerp(C(255, 255, 255), 0.84)
			row.BorderSizePixel = 0
			row.Parent = gui
			local corner = Instance.new("UICorner")
			corner.CornerRadius, corner.Parent = UDim.new(0, 9), row
			local number = label(row, "Rank", tostring(rank), 5, 4, 46, 39, 25, ink, Enum.TextXAlignment.Center)
			number.BackgroundTransparency = 0
			number.BackgroundColor3 = ({ C(255, 211, 55), C(199, 218, 237), C(239, 166, 106) })[rank] or accent
			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius, badgeCorner.Parent = UDim.new(0, 9), number
			label(row, "Entry", "—", 71, 0, 300, 47, 25, ink)
			label(row, "Value", "", 393, 0, 177, 47, 25, ink, Enum.TextXAlignment.Right)
		end
		local placeholder = board:GetAttribute("LayoutPlaceholder") == true
		label(gui, "Status", placeholder and "Скоро" or "Waiting for players", 30, 687, 560, 30, 18, ink)
		if placeholder then
			scope.Text = "Рейтинг скоро появится"
		end
		board:SetAttribute("RankingStyle", 4)
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

function Rankings.render(map, states)
	local group = assert(map:FindFirstChild("LobbyRankings"))
	for _, category in categories do
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
		local sorted = {}
		for _, entry in entries do
			table.insert(sorted, entry)
		end
		table.sort(sorted, function(a, b)
			if a.value == b.value then
				return a.userId < b.userId
			end
			return a.value > b.value
		end)
		local gui = group[category.key].Panel.RankingGui
		gui.Scope.Text = RunService:IsStudio() and "STUDIO • LIVE TOP 10" or "GLOBAL TOP 10"
		for rank = 1, 10 do
			local entry = sorted[rank]
			local row = gui["Row" .. rank]
			row.Entry.Text = entry and (entry.name or names[entry.userId] or ("User " .. entry.userId)) or "—"
			row.Value.Text = entry and (Config.format(entry.value) .. (category.suffix or "")) or ""
		end
		gui.Status.Text = #sorted == 0 and "Be the first to reach the top!"
			or (
				RunService:IsStudio() and "Live session • updates every 10s"
				or (
					cached[category.key] and "Global rankings • refresh every 2 min"
					or "Live server • global rankings loading"
				)
			)
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
