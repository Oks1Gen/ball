--!strict
-- Legacy modal panels: Settings, Rebirth, Inventory and Gifts.
-- Desktop windows share the HUD board. Phone content keeps readable pixel
-- sizes and scrolls vertically inside the same window chrome.
local Kit = require(script.Parent.HudKit)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local MotionConfig = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local GuiInsets = require(script.Parent.Parent.Modules.GuiInsets)
local Presentation = require(script.Parent.Parent.Modules.UiPresentation)
local ReturnRewardPanels = require(script.Parent.ReturnRewardPanels)
local UpdateLog = require(script.Parent.Parent.Modules.UpdateLog)
local TextService = game:GetService("TextService")
local Style = require(script.Parent.Parent.UiStyle)

local Panels = {}
local C = Color3.fromRGB
local yellow = C(255, 225, 66)
-- The legacy panels live in the HUD canvas next to the HUD itself. Their
-- layer is fixed by ZIndex, not by the order the instances were created in:
-- the panel is above the HUD and the settings button (1). Notifications use
-- their own ScreenGui above every gameplay window.
local LAYER_PANEL = 20

export type Context = {
	canvas: Frame,
	send: (string, any?, any?) -> (),
	snapshot: () -> any?,
	closePanel: (boolean?) -> (),
	showPanel: (string) -> (),
	finishWelcome: (() -> ())?,
}

export type Handle = {
	open: (string, any?) -> (),
	shell: (string, string, number, number) -> Frame,
	refresh: () -> (),
	close: ((() -> ())?) -> (),
	destroy: () -> (),
	layout: () -> (),
}

function Panels.mount(context: Context): Handle
	local canvas = context.canvas
	local refresh: (() -> ())? = nil
	local windows: { [string]: any } = {}
	local activeName: string? = nil
	local function phoneArea(): (boolean, Vector2)
		local area = GuiInsets.area(workspace.CurrentCamera.ViewportSize, canvas.Parent :: GuiObject)
		return UserInputService.TouchEnabled and area.size.Y < 520, area.size
	end
	local function place(group: CanvasGroup)
		local center = GuiInsets.screenCenter(workspace.CurrentCamera.ViewportSize) - canvas.AbsolutePosition
		local factor = canvas.AbsoluteSize.X / math.max(1, canvas.Size.X.Offset)
		group.Position = UDim2.fromOffset(center.X / math.max(0.01, factor), center.Y / math.max(0.01, factor))
	end

	-- Every panel takes over the screen the same way: drop the current one,
	-- remember the new name and dim the world behind it.
	local function begin(name: string)
		context.closePanel(true)
		activeName = name
		context.showPanel(name)
	end

	-- A padded group keeps the whole window centred, including its chrome.
	local function shell(name: string, kind: string, width: number, height: number, fitWhole: boolean?): Frame
		local phone, area = phoneArea()
		phone = phone and not fitWhole
		local originalHeight = height
		if phone then
			width = math.min(width, area.X - 64)
			height = math.min(height, math.max(227, area.Y - 96))
		end
		local margin = MotionConfig.Window.ChromeMargin
		local group = Instance.new("CanvasGroup")
		group.Name = "Window_" .. (activeName or name)
		group.Size = UDim2.fromOffset(width + margin * 2, height + margin * 2)
		group.AnchorPoint = Vector2.new(0.5, 0.5)
		group.Position = UDim2.fromScale(0.5, 0.5)
		group.BackgroundTransparency = 1
		group.ZIndex = LAYER_PANEL
		group.Parent = canvas
		if phone then
			local fit = Instance.new("UIScale")
			fit.Name = "ReadablePhoneScale"
			fit.Scale = 1 / math.max(0.01, canvas.AbsoluteSize.X / canvas.Size.X.Offset)
			fit.Parent = group
		end
		place(group)
		local modal = Kit.frame(group, "Modal", margin, margin, width, height, C(55, 63, 79))
		modal.BackgroundTransparency = 0.3
		modal.ZIndex = LAYER_PANEL
		Kit.stroke(modal, 2)
		local heading = Kit.text(
			modal,
			"Heading",
			name,
			phone and 64 or 85,
			phone and -38 or -50,
			width - (phone and 128 or 170),
			phone and 44 or 66,
			phone and 34 or 63
		)
		heading.ZIndex = 10
		heading.TextScaled = true
		local headingLimit = Instance.new("UITextSizeConstraint")
		headingLimit.MinTextSize = 24
		headingLimit.MaxTextSize = phone and 34 or 63
		headingLimit.Parent = heading
		local cornerIcon = Kit.icon(modal, kind, 0, 0, phone and 64 or 100, phone and 64 or 100)
		cornerIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		cornerIcon.ZIndex = 10
		local canvasScale = math.max(0.01, canvas.AbsoluteSize.X / canvas.Size.X.Offset)
		local closeSize = if fitWhole then math.max(60, math.ceil(44 / canvasScale)) else phone and 44 or 60
		local close = Kit.button(
			modal,
			"Close",
			"",
			width - 32,
			phone and -28 or -31,
			closeSize,
			closeSize,
			C(252, 24, 68),
			52,
			context.closePanel
		)
		close.AnchorPoint = Vector2.new(0.5, 0.5)
		close.Position = UDim2.fromScale(1, 0)
		close.ZIndex = 11
		Kit.visualOf(close).BackgroundTransparency = 1
		Kit.hide(close, "Studs")
		Kit.hide(close, "UIStroke")
		Kit.hide(modal, "CloseShadow")
		Kit.icon(close, "Close", 0, 0, closeSize, closeSize)
		if activeName == "Offline" then
			close.Visible = false
		end
		local factor = phone and 1
			or math.min(
				1,
				math.max(1, canvas.Size.X.Offset - 24) / (width + margin * 2),
				math.max(1, canvas.Size.Y.Offset - 24) / (height + margin * 2)
			)
		local animation = Motion.window(group, factor)
		local key = activeName or name
		local record = { group = group, animation = animation, refresh = nil, phone = phone }
		windows[key] = record
		animation.setOpen(true)
		-- The world behind a legacy modal must not take clicks: the
		-- collector screens own a blocker of their own, so the panels match
		-- them. The SkippingHUD screen runs the Sibling ZIndex behaviour, so
		-- the blocker has to take its place in the canvas ordering, right
		-- below the modal: parked under the ScreenGui it would rank against
		-- the canvas subtree as a whole and swallow the modal's own clicks.
		-- The blocker dies with its modal, a stale one would swallow
		-- the game forever.
		local blocker = Instance.new("TextButton")
		blocker.Name = "ModalBlocker"
		blocker.Text = ""
		blocker.AutoButtonColor = false
		blocker.BackgroundTransparency = 1
		blocker.Size = UDim2.fromScale(1, 1)
		blocker.Modal = true
		blocker.ZIndex = LAYER_PANEL - 1
		blocker.Parent = canvas
		group.Destroying:Connect(function()
			blocker:Destroy()
		end)
		if phone then
			local scroll = Instance.new("ScrollingFrame")
			scroll.Name = "PhoneContent"
			scroll.BackgroundTransparency = 1
			scroll.BorderSizePixel = 0
			scroll.Position = UDim2.fromOffset(0, 24)
			scroll.Size = UDim2.fromOffset(width, height - 32)
			scroll.CanvasSize = UDim2.fromOffset(0, originalHeight)
			scroll.ScrollBarThickness = 5
			scroll.ScrollBarImageColor3 = yellow
			scroll.ScrollingDirection = Enum.ScrollingDirection.Y
			scroll.Parent = modal
			local content = Kit.frame(scroll, "Content", 0, 0, width, originalHeight)
			content.BackgroundTransparency = 1
			return content
		end
		return modal
	end

	local function scrolling(modal: Frame, y: number, height: number): ScrollingFrame
		local parentScroll = modal.Parent
		if parentScroll and parentScroll:IsA("ScrollingFrame") and parentScroll.Name == "PhoneContent" then
			local visibleHeight = parentScroll.Size.Y.Offset
			modal.Size = UDim2.fromOffset(modal.Size.X.Offset, visibleHeight)
			parentScroll.CanvasSize = UDim2.new()
			y = y == 70 and 12 or y
			height = math.max(60, visibleHeight - y - 4)
		end
		local s = Instance.new("ScrollingFrame")
		s.Name = "List"
		s.Position = UDim2.fromOffset(7, y)
		s.Size = UDim2.new(1, -14, 0, height)
		s.BackgroundTransparency = 1
		s.BorderSizePixel = 0
		s.ScrollBarThickness = 5
		s.ScrollBarImageColor3 = yellow
		s.CanvasSize = UDim2.new()
		s.AutomaticCanvasSize = Enum.AutomaticSize.Y
		s.Parent = modal
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 12)
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.Parent = s
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 4)
		padding.PaddingBottom = UDim.new(0, 4)
		padding.Parent = s
		return s
	end

	local function openUpdateLog()
		begin("UpdateLog")
		refresh = nil
		local modal = shell("Update Log", "UpdateLog", 620, 430)
		local width = modal.Size.X.Offset - 29
		local phone = phoneArea()
		local list = scrolling(modal, phone and 70 or 24, 394)
		for index, release in UpdateLog do
			local row = Kit.frame(list, release.id, 0, 0, width, 1, Style.PanelDeep)
			row.LayoutOrder = index
			row.BackgroundTransparency = 0.25
			Kit.corner(row, 9)
			Kit.stroke(row, 2)
			local title = Kit.text(row, "Title", release.title, 16, 12, width - 32, 34, phone and 24 or 29)
			title.TextXAlignment = Enum.TextXAlignment.Left
			local date = Kit.text(row, "Date", release.date, 16, 48, width - 32, 24, 16, Style.Gold)
			date.TextXAlignment = Enum.TextXAlignment.Left
			local y = 84
			local fontSize = phone and 18 or 22
			for changeIndex, change in release.changes do
				local text = "• " .. change
				local height = math.ceil(
					TextService:GetTextSize(text, fontSize, Enum.Font.GothamBlack, Vector2.new(width - 40, 10000)).Y
				) + 6
				local label = Kit.text(row, "Change" .. changeIndex, text, 16, y, width - 40, height, fontSize)
				label.TextWrapped = true
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextYAlignment = Enum.TextYAlignment.Top
				y += height + 12
			end
			row.Size = UDim2.fromOffset(width, y + 4)
		end
	end

	local function openSettings()
		begin("Settings")
		local modal = shell("Settings", "Settings", 585, 474)
		local width = modal.Size.X.Offset
		local phone = phoneArea()
		local toggles: { [string]: (any) -> () } = {}
		local list = scrolling(modal, 70, 390)
		for i, info in
			{
				{ "Sound Effects", "sound" },
				{ "Music", "music" },
				{ "Camera Shake", "shake" },
				{ "Effects", "effects" },
			}
		do
			local row = Kit.frame(list, info[2], 7, 0, width - 29, 63, C(48, 53, 67))
			row.LayoutOrder = i
			row.BackgroundTransparency = 0.25
			Kit.stroke(row, 2)
			Kit.text(
				row,
				"Name",
				phone and info[2] == "sound" and "Sound" or info[1],
				12,
				9,
				width - 305,
				42,
				phone and 22 or 32
			).TextXAlignment =
				Enum.TextXAlignment.Left
			if i <= 2 then
				local sliderX = width - 275
				local sliderWidth = phone and 200 or 220
				local track = Kit.frame(row, "Track", sliderX, 25, sliderWidth, 12, C(12, 27, 30))
				Kit.stroke(track, 2)
				local snapshotAtBuild = context.snapshot()
				local value = snapshotAtBuild and snapshotAtBuild.data.settings[info[2]] or 100
				-- The fill starts at the saved volume, not at 100 %: the
				-- panel is shown long before refresh() can run again.
				local fill = Kit.frame(track, "Fill", 0, 0, sliderWidth * value / 100, 12, C(70, 236, 0))
				local b = Kit.button(
					row,
					"Volume",
					tostring(value),
					sliderX + sliderWidth * value / 100,
					10,
					phone and 44 or 31,
					44,
					C(100, 238, 8),
					17
				)
				b.Active = false -- The full Slider owns input, including the knob area.
				local corner = Kit.cornerOf(b)
				if corner then
					corner.CornerRadius = UDim.new(0, 1)
				end
				local studs = Kit.studsOf(b)
				local studsCorner = studs and Kit.cornerOf(studs)
				if studsCorner then
					studsCorner.CornerRadius = UDim.new(0, 1)
				end
				local knobShadow = row:FindFirstChild("VolumeShadow")
				local shadowCorner = knobShadow and Kit.cornerOf(knobShadow)
				if shadowCorner then
					shadowCorner.CornerRadius = UDim.new(0, 1)
				end
				local hit = Instance.new("TextButton")
				hit.Name = "Slider"
				hit.Position = UDim2.fromOffset(sliderX - 10, 7)
				hit.Size = UDim2.fromOffset(248, 50)
				hit.BackgroundTransparency = 1
				hit.Text = ""
				hit.Parent = row
				local dragging = false
				local function change(point: Vector2)
					value = math.clamp(
						math.floor((point.X - track.AbsolutePosition.X) / track.AbsoluteSize.X * 100),
						0,
						100
					)
					fill.Size = UDim2.fromScale(value / 100, 1)
					b.Position = UDim2.fromOffset(sliderX + sliderWidth * value / 100, 10)
					local caption = Kit.captionOf(b)
					if caption then
						caption.Text = tostring(value)
					end
					if knobShadow then
						knobShadow.Position = b.Position + UDim2.fromOffset(0, 4)
					end
				end
				hit.InputBegan:Connect(function(input)
					if
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.Touch
					then
						dragging = true
						change(input.Position)
					end
				end)
				local move = UserInputService.InputChanged:Connect(function(input)
					if
						dragging
						and (
							input.UserInputType == Enum.UserInputType.MouseMovement
							or input.UserInputType == Enum.UserInputType.Touch
						)
					then
						change(input.Position)
					end
				end)
				local finish = UserInputService.InputEnded:Connect(function(input)
					if
						dragging
						and (
							input.UserInputType == Enum.UserInputType.MouseButton1
							or input.UserInputType == Enum.UserInputType.Touch
						)
					then
						dragging = false
						context.send("Setting", info[2], value)
					end
				end)
				modal.Destroying:Connect(function()
					move:Disconnect()
					finish:Disconnect()
				end)
				toggles[info[2]] = function(v: number)
					if not dragging then
						value = v
						fill.Size = UDim2.fromScale(v / 100, 1)
						b.Position = UDim2.fromOffset(sliderX + sliderWidth * v / 100, 10)
						if knobShadow then
							knobShadow.Position = b.Position + UDim2.fromOffset(0, 4)
						end
						local caption = Kit.captionOf(b)
						if caption then
							caption.Text = tostring(v)
						end
					end
				end
			else
				local b = Kit.button(row, "Toggle", "ON", width - 153, 8, 112, 47, C(66, 231, 29), 28, function()
					local snapshot = context.snapshot()
					if snapshot then
						context.send("Setting", info[2], not snapshot.data.settings[info[2]])
					end
				end)
				toggles[info[2]] = function(v: boolean)
					local caption = Kit.captionOf(b)
					if caption then
						caption.Text = v and "ON" or "OFF"
					end
					Kit.paint(b, v and C(61, 229, 33) or C(249, 61, 68))
				end
			end
		end
		refresh = function()
			local snapshot = context.snapshot()
			if snapshot then
				for key, apply in toggles do
					apply(snapshot.data.settings[key])
				end
			end
		end
		refresh()
	end

	local function openRebirth()
		begin("Rebirth")
		local modal = shell("Rebirth", "Rebirth", 585, 395)
		local phone = phoneArea()
		local width = modal.Size.X.Offset
		local sideWidth = phone and math.floor((width - 100) / 2) or 240
		local afterX = phone and width - sideWidth - 20 or 333
		Kit.text(modal, "Before", "Before", 20, 43, sideWidth, 54, phone and 28 or 37)
		Kit.text(modal, "After", "After", afterX, 43, sideWidth, 54, phone and 28 or 37)
		local before = Kit.button(modal, "BeforeMultiplier", "", 20, 113, sideWidth, 73, C(255, 217, 36), 28)
		local after = Kit.button(modal, "AfterMultiplier", "", afterX, 113, sideWidth, 73, C(255, 217, 36), 28)
		Kit.icon(before, "Skill", 14, 2, phone and 44 or 65, 67)
		Kit.icon(after, "Skill", 14, 2, phone and 44 or 65, 67)
		local beforeCaption = Kit.captionOf(before)
		if beforeCaption then
			beforeCaption.Position = UDim2.fromOffset(phone and 68 or 88, 3)
			beforeCaption.Size = UDim2.fromOffset(phone and sideWidth - 76 or 143, 67)
		end
		local afterCaption = Kit.captionOf(after)
		if afterCaption then
			afterCaption.Position = UDim2.fromOffset(phone and 68 or 88, 3)
			afterCaption.Size = UDim2.fromOffset(phone and sideWidth - 76 or 143, 67)
		end
		Kit.icon(modal, "Arrow", phone and (width - 44) / 2 or 271, 121, phone and 44 or 60, 59)
		Kit.text(
			modal,
			"Warning",
			"Resets your LEVEL and SKILL!",
			15,
			207,
			width - 30,
			42,
			phone and 23 or 30,
			C(255, 61, 74)
		)
		local bar = Kit.frame(modal, "LevelRequirement", 58, 248, width - 116, 57, C(226, 230, 235))
		Kit.corner(bar, 9)
		Kit.stroke(bar, 3)
		Kit.pattern(bar, C(190, 196, 204))
		local fill = Kit.frame(bar, "Progress", 0, 0, 0, 57, Color3.new(1, 1, 1))
		fill.Size = UDim2.fromScale(0, 1)
		Kit.corner(fill, 8)
		local gradient = Instance.new("UIGradient")
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new(C(0, 214, 255), C(0, 112, 255))
		gradient.Parent = fill
		Kit.pattern(fill, C(64, 179, 223))
		local barCaption = Kit.text(bar, "Caption", "Level 1 / Level " .. Config.MaxLevel, 4, 2, width - 124, 53, 30)
		barCaption.ZIndex = 3
		local actionButton = Kit.button(
			modal,
			"RebirthAction",
			"Rebirth",
			phone and (width - 360) / 2 or 121,
			328,
			155,
			53,
			C(82, 232, 18),
			29,
			function()
				local snapshot = context.snapshot()
				if snapshot and snapshot.rebirthReady then
					context.send("Rebirth")
				end
			end
		)
		Kit.button(
			modal,
			"SkipRebirth",
			"Skip Rebirth",
			phone and (width - 360) / 2 + 204 or 325,
			328,
			156,
			53,
			C(189, 128, 238),
			24,
			function()
				context.send("Product", "SkipRebirth")
			end
		)
		refresh = function()
			local snapshot = context.snapshot()
			if snapshot then
				local currentBefore = Kit.captionOf(before)
				if currentBefore then
					currentBefore.Text = "×" .. (snapshot.data.rebirths + 1) .. "\nSKILL"
				end
				local currentAfter = Kit.captionOf(after)
				if currentAfter then
					currentAfter.Text = "×" .. (snapshot.data.rebirths + 2) .. "\nSKILL"
				end
				local requiredLevel = snapshot.rebirthRequiredLevel or Config.MaxLevel
				barCaption.Text = "Level " .. snapshot.level .. " / Level " .. requiredLevel
				TweenService:Create(fill, TweenInfo.new(0.3), {
					Size = UDim2.fromScale(math.clamp(snapshot.rebirthProgress or 0, 0, 1), 1),
				}):Play()
				local ready = snapshot.rebirthReady == true
				local actionCaption = Kit.captionOf(actionButton)
				if actionCaption then
					actionCaption.Text = ready and "Rebirth" or "Need Level " .. Config.MaxLevel
				end
				Kit.paint(actionButton, ready and C(82, 232, 18) or C(34, 110, 18))
			end
		end
		refresh()
	end

	local function openInventory(selectedId: string?)
		begin("Inventory")
		local modal = shell("Balls", "Ball", 680, 470)
		local width = modal.Size.X.Offset
		local phone = phoneArea()
		Kit.text(
			modal,
			"Description",
			phone and "Buy with Wins • Boost power" or "Buy with Wins • Boost training and hits",
			25,
			32,
			width - 50,
			38,
			phone and 19 or 23,
			yellow
		)
		local scroll = scrolling(modal, 80, 380)
		local rows: { [string]: { b: TextButton, item: any } } = {}
		for i, item in Config.Stones do
			local row = Kit.brick(scroll, item.id, 0, 0, width - 30, 92, item.color)
			row.LayoutOrder = i
			BallVisuals.preview(row, item.id)
			Kit.text(row, "Name", item.name, 115, 7, phone and width - 286 or 300, 38, phone and 18 or 29).TextXAlignment =
				Enum.TextXAlignment.Left
			Kit.text(
				row,
				"Power",
				"×" .. item.power .. (phone and " Power" or " Training & Hit Power"),
				115,
				47,
				phone and width - 286 or 340,
				30,
				phone and 16 or 19,
				yellow
			).TextXAlignment =
				Enum.TextXAlignment.Left
			local b = Kit.button(
				row,
				"Equip",
				"",
				width - (phone and 151 or 219),
				27,
				phone and 110 or 171,
				phone and 44 or 42,
				C(85, 233, 19),
				phone and 19 or 23,
				function()
					context.send("Stone", item.id)
				end
			)
			rows[item.id] = { b = b, item = item }
		end
		refresh = function()
			local snapshot = context.snapshot()
			if snapshot then
				for id, row in rows do
					local caption = Kit.captionOf(row.b)
					if caption then
						caption.Text = snapshot.data.stone == id and "Equipped"
							or snapshot.data.stones[id] and "Equip"
							or Config.format(row.item.cost) .. " Wins"
					end
				end
			end
		end
		refresh()
		if selectedId then
			for i, item in Config.Stones do
				if item.id == selectedId then
					local row = scroll:FindFirstChild(item.id)
					if row and row:IsA("GuiObject") then
						local stroke = row:FindFirstChildOfClass("UIStroke")
						if stroke then
							stroke.Color = yellow
							stroke.Thickness = 4
						end
					end
					task.defer(function()
						if scroll.Parent then
							scroll.CanvasPosition = Vector2.new(0, math.max(0, (i - 1) * 102))
						end
					end)
					break
				end
			end
		end
	end

	local function openGifts()
		begin("Gifts")
		local modal = shell("Playtime Rewards", "Gifts", 700, 452)
		local phone = phoneArea()
		local cardWidth = math.floor((modal.Size.X.Offset - 64) / 3)
		local rows: { [number]: TextButton } = {}
		local checks: { [number]: Frame } = {}
		local dimmers: { [number]: Frame } = {}
		for i, gift in Config.Gifts do
			local x = 18 + (i - 1) % 3 * (cardWidth + 14)
			local y = (phone and 12 or 56) + math.floor((i - 1) / 3) * 192
			local color = i <= 3 and C(39, 167, 225) or i <= 5 and C(184, 104, 239) or C(255, 203, 33)
			local row = Kit.brick(modal, "Gift" .. i, x, y, cardWidth, 178, color, 18)
			Kit.burst(row)
			Kit.text(
				row,
				"Wins",
				"+" .. Config.format(gift.wins) .. " WINS",
				8,
				7,
				cardWidth - 16,
				27,
				phone and 18 or 22
			)
			Kit.text(
				row,
				"Skill",
				"+" .. Config.format(gift.skill) .. " SKILL",
				8,
				34,
				cardWidth - 16,
				24,
				phone and 16 or 19
			)
			Kit.icon(
				row,
				i % 2 == 0 and "Skill" or "Wins",
				(cardWidth - (phone and 90 or 102)) / 2,
				62,
				phone and 90 or 102,
				phone and 54 or 65
			)
			rows[i] = Kit.button(
				row,
				"Claim",
				"",
				14,
				phone and 124 or 134,
				cardWidth - 28,
				phone and 44 or 34,
				C(250, 53, 53),
				22,
				function()
					local snapshot = context.snapshot()
					if snapshot and not snapshot.gifts[i] and snapshot.elapsed >= Config.Gifts[i].time then
						context.send("Gift", i)
					end
				end
			)
			local dimmer = Kit.frame(row, "ClaimedShade", 0, 0, cardWidth, 178, C(10, 13, 22))
			dimmer.BackgroundTransparency = 0.48
			dimmer.ZIndex = 7
			Kit.corner(dimmer, 18)
			dimmers[i] = dimmer
			local check = Kit.icon(row, "Check", 50, 56, 112, 105)
			check.ZIndex = 8
			checks[i] = check
		end
		refresh = function()
			local snapshot = context.snapshot()
			if not snapshot then
				return
			end
			for i, b in rows do
				local claimed = snapshot.gifts[i] == true
				local remaining = math.max(0, Config.Gifts[i].time - snapshot.elapsed)
				local ready = not claimed and remaining <= 0
				local caption = Kit.captionOf(b)
				if caption then
					caption.Text = claimed and "Claimed" or ready and "Claim!" or Presentation.countdown(remaining)
				end
				checks[i].Visible = claimed
				dimmers[i].Visible = claimed
				Kit.paint(b, ready and C(84, 235, 24) or C(250, 53, 53))
				b.Active = not claimed
				b.Interactable = not claimed
			end
		end
		refresh()
	end

	local function openOffline()
		begin("Offline")
		local modal = shell("Welcome Back!", "Offline", 720, 520, true)
		refresh = ReturnRewardPanels.offline(modal, context)
		refresh()
	end

	local function openDaily()
		begin("Daily")
		local modal = shell("Daily Rewards", "Daily", 820, 550, true)
		Kit.corner(modal, 20)
		refresh = ReturnRewardPanels.daily(modal, context)
		refresh()
	end

	return {
		open = function(name: string, argument: any?)
			local existing = windows[name]
			if existing and existing.group.Parent then
				context.closePanel(true)
				activeName = name
				refresh = existing.refresh
				context.showPanel(name)
				existing.animation.setOpen(true)
				if refresh then
					refresh()
				end
				return
			end
			if name == "Settings" then
				openSettings()
			elseif name == "UpdateLog" then
				openUpdateLog()
			elseif name == "Rebirth" then
				openRebirth()
			elseif name == "Inventory" then
				openInventory(argument)
			elseif name == "Gifts" then
				openGifts()
			elseif name == "Daily" then
				openDaily()
			elseif name == "Offline" then
				openOffline()
			end
			local record = windows[name]
			if record then
				record.refresh = refresh
			end
		end,
		shell = function(name: string, kind: string, width: number, height: number): Frame
			begin(name)
			return shell(name, kind, width, height)
		end,
		refresh = function()
			if refresh then
				refresh()
			end
		end,
		close = function(onClosed: (() -> ())?)
			if activeName then
				local name = activeName
				local record = windows[name]
				activeName = nil
				if record then
					record.refresh = refresh
					record.animation.setOpen(false, function()
						if windows[name] == record then
							windows[name] = nil
						end
						record.group:Destroy()
						if onClosed then
							onClosed()
						end
					end)
				end
			elseif onClosed then
				task.defer(onClosed)
			end
			refresh = nil
		end,
		layout = function()
			for _, record in windows do
				place(record.group)
			end
		end,
		destroy = function()
			for _, record in windows do
				record.group:Destroy()
			end
			table.clear(windows)
		end,
	}
end

return Panels
