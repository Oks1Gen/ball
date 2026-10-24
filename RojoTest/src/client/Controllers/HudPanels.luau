--!strict
-- Legacy modal panels: Settings, Rebirth, Inventory and Gifts.
-- They share the canvas with the HUD. On a narrow screen the whole modal is
-- scaled down instead of being rebuilt, so the design stays intact.
local Kit = require(script.Parent.HudKit)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local BallVisuals = require(game.ReplicatedStorage.Shared.BallVisuals)
local UserInputService = game:GetService("UserInputService")
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local MotionConfig = require(game.ReplicatedStorage.Shared.UiMotionConfig)
local GuiInsets = require(script.Parent.Parent.Modules.GuiInsets)

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
}

export type Handle = {
	open: (string, any?) -> (),
	shell: (string, string, number, number) -> Frame,
	refresh: () -> (),
	close: () -> (),
	destroy: () -> (),
	layout: () -> (),
}

function Panels.mount(context: Context): Handle
	local canvas = context.canvas
	local refresh: (() -> ())? = nil
	local windows: { [string]: any } = {}
	local activeName: string? = nil
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
	local function shell(name: string, kind: string, width: number, height: number): Frame
		local margin = MotionConfig.Window.ChromeMargin
		local group = Instance.new("CanvasGroup")
		group.Name = "Window_" .. (activeName or name)
		group.Size = UDim2.fromOffset(width + margin * 2, height + margin * 2)
		group.AnchorPoint = Vector2.new(0.5, 0.5)
		group.Position = UDim2.fromScale(0.5, 0.5)
		group.BackgroundTransparency = 1
		group.ZIndex = LAYER_PANEL
		group.Parent = canvas
		place(group)
		local modal = Kit.frame(group, "Modal", margin, margin, width, height, C(55, 63, 79))
		modal.BackgroundTransparency = 0.3
		modal.ZIndex = LAYER_PANEL
		Kit.stroke(modal, 2)
		local heading = Kit.text(modal, "Heading", name, 85, -50, width - 170, 66, 63)
		heading.ZIndex = 10
		heading.TextScaled = true
		local headingLimit = Instance.new("UITextSizeConstraint")
		headingLimit.MinTextSize = 24
		headingLimit.MaxTextSize = 63
		headingLimit.Parent = heading
		Kit.icon(modal, kind, -15, -54, 100, 100).ZIndex = 10
		local close = Kit.button(modal, "Close", "", width - 32, -31, 60, 60, C(252, 24, 68), 52, context.closePanel)
		close.ZIndex = 11
		Kit.visualOf(close).BackgroundTransparency = 1
		Kit.hide(close, "Studs")
		Kit.hide(close, "UIStroke")
		Kit.hide(modal, "CloseShadow")
		Kit.icon(close, "Close", 0, 0, 60, 60)
		local factor = math.min(
			1,
			math.max(1, canvas.Size.X.Offset - 24) / (width + margin * 2),
			math.max(1, canvas.Size.Y.Offset - 24) / (height + margin * 2)
		)
		local animation = Motion.window(group, factor)
		local key = activeName or name
		local record = { group = group, animation = animation, refresh = nil }
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
		return modal
	end

	local function scrolling(modal: Frame, y: number, height: number): ScrollingFrame
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

	local function openSettings()
		begin("Settings")
		local modal = shell("Settings", "Settings", 585, 474)
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
			local row = Kit.frame(list, info[2], 7, 0, 556, 63, C(48, 53, 67))
			row.LayoutOrder = i
			row.BackgroundTransparency = 0.25
			Kit.stroke(row, 2)
			Kit.text(row, "Name", info[1], 12, 9, 280, 42, 32).TextXAlignment = Enum.TextXAlignment.Left
			if i <= 2 then
				local track = Kit.frame(row, "Track", 310, 25, 220, 12, C(12, 27, 30))
				Kit.stroke(track, 2)
				local snapshotAtBuild = context.snapshot()
				local value = snapshotAtBuild and snapshotAtBuild.data.settings[info[2]] or 100
				-- The fill starts at the saved volume, not at 100 %: the
				-- panel is shown long before refresh() can run again.
				local fill = Kit.frame(track, "Fill", 0, 0, 220 * value / 100, 12, C(70, 236, 0))
				local b =
					Kit.button(row, "Volume", tostring(value), 310 + 220 * value / 100, 10, 31, 44, C(100, 238, 8), 17)
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
				hit.Position = UDim2.fromOffset(300, 7)
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
					b.Position = UDim2.fromOffset(310 + 220 * value / 100, 10)
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
						b.Position = UDim2.fromOffset(310 + 220 * v / 100, 10)
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
				local b = Kit.button(row, "Toggle", "ON", 432, 8, 112, 47, C(66, 231, 29), 28, function()
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
		Kit.text(modal, "Before", "Before", 35, 43, 240, 54, 37)
		Kit.text(modal, "After", "After", 349, 43, 205, 54, 37)
		local before = Kit.button(modal, "BeforeMultiplier", "", 20, 113, 240, 73, C(255, 217, 36), 28)
		local after = Kit.button(modal, "AfterMultiplier", "", 333, 113, 240, 73, C(255, 217, 36), 28)
		Kit.icon(before, "Skill", 14, 2, 65, 67)
		Kit.icon(after, "Skill", 14, 2, 65, 67)
		local beforeCaption = Kit.captionOf(before)
		if beforeCaption then
			beforeCaption.Position = UDim2.fromOffset(88, 3)
			beforeCaption.Size = UDim2.fromOffset(143, 67)
		end
		local afterCaption = Kit.captionOf(after)
		if afterCaption then
			afterCaption.Position = UDim2.fromOffset(88, 3)
			afterCaption.Size = UDim2.fromOffset(143, 67)
		end
		Kit.icon(modal, "Arrow", 271, 121, 60, 59)
		Kit.text(modal, "Warning", "Resets your LEVEL and SKILL!", 15, 207, 555, 42, 30, C(255, 61, 74))
		local bar = Kit.button(
			modal,
			"LevelRequirement",
			"Level 1 / Level " .. Config.MaxLevel,
			58,
			248,
			466,
			57,
			C(22, 160, 248),
			30
		)
		local actionButton = Kit.button(
			modal,
			"RebirthAction",
			"Rebirth",
			121,
			328,
			155,
			53,
			C(82, 232, 18),
			29,
			function()
				context.send("Rebirth")
			end
		)
		Kit.button(modal, "SkipRebirth", "Skip Rebirth", 325, 328, 156, 53, C(189, 128, 238), 24, function()
			context.send("Product", "SkipRebirth")
		end)
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
				local barCaption = Kit.captionOf(bar)
				if barCaption then
					barCaption.Text = "Level "
						.. snapshot.level
						.. " / Level "
						.. (snapshot.rebirthRequiredLevel or Config.MaxLevel)
				end
				local ready = snapshot.rebirthReady == true
				local actionCaption = Kit.captionOf(actionButton)
				if actionCaption then
					actionCaption.Text = ready and "Rebirth" or "Need Level " .. Config.MaxLevel
				end
				-- A locked rebirth gets the muted block and stops being a
				-- button: the click would only travel to the server and die
				-- there in silence.
				Kit.paint(actionButton, ready and C(82, 232, 18) or C(115, 127, 143))
				actionButton.Active = ready
			end
		end
		refresh()
	end

	local function openInventory(selectedId: string?)
		begin("Inventory")
		local modal = shell("Balls", "Ball", 680, 470)
		Kit.text(modal, "Description", "Buy with Wins • Boost training and hits", 25, 32, 630, 38, 23, yellow)
		local scroll = scrolling(modal, 80, 380)
		local rows: { [string]: { b: TextButton, item: any } } = {}
		for i, item in Config.Stones do
			local row = Kit.brick(scroll, item.id, 0, 0, 650, 92, item.color)
			row.LayoutOrder = i
			BallVisuals.preview(row, item.id)
			Kit.text(row, "Name", item.name, 115, 7, 300, 38, 29).TextXAlignment = Enum.TextXAlignment.Left
			Kit.text(row, "Power", "×" .. item.power .. " Training & Hit Power", 115, 47, 340, 30, 19, yellow).TextXAlignment =
				Enum.TextXAlignment.Left
			local b = Kit.button(row, "Equip", "", 461, 27, 171, 42, C(85, 233, 19), 23, function()
				context.send("Stone", item.id)
			end)
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
		local rows: { [number]: TextButton } = {}
		local checks: { [number]: Frame } = {}
		local dimmers: { [number]: Frame } = {}
		for i, gift in Config.Gifts do
			local x = 18 + (i - 1) % 3 * 226
			local y = 56 + math.floor((i - 1) / 3) * 192
			local color = i <= 3 and C(39, 167, 225) or i <= 5 and C(184, 104, 239) or C(255, 203, 33)
			local row = Kit.brick(modal, "Gift" .. i, x, y, 212, 178, color, 18)
			Kit.burst(row)
			Kit.text(row, "Wins", "+" .. Config.format(gift.wins) .. " WINS", 8, 7, 196, 27, 22)
			Kit.text(row, "Skill", "+" .. Config.format(gift.skill) .. " SKILL", 8, 34, 196, 24, 19)
			Kit.icon(row, i % 2 == 0 and "Skill" or "Wins", 55, 62, 102, 65)
			rows[i] = Kit.button(row, "Claim", "", 14, 134, 184, 34, C(250, 53, 53), 22, function()
				context.send("Gift", i)
			end)
			local dimmer = Kit.frame(row, "ClaimedShade", 0, 0, 212, 178, C(10, 13, 22))
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
					caption.Text = claimed and "Claimed"
						or ready and "Claim!"
						or string.format(
							"%02d:%02d:%02d",
							math.floor(remaining / 3600),
							math.floor(remaining / 60) % 60,
							remaining % 60
						)
				end
				checks[i].Visible = claimed
				dimmers[i].Visible = claimed
				Kit.paint(b, ready and C(84, 235, 24) or C(250, 53, 53))
				b.Active = ready
			end
		end
		refresh()
	end

	local function openDaily()
		begin("Daily")
		local modal = shell("Daily Reward", "Daily", 600, 418)
		Kit.text(modal, "Subtitle", "COME BACK EVERY DAY!", 25, 43, 550, 38, 30)
		local card = Kit.brick(modal, "DailyReward", 130, 95, 340, 230, C(255, 211, 31), 12)
		Kit.burst(card)
		Kit.icon(card, "Wins", 82, 8, 176, 130)
		Kit.text(card, "Wins", "+500 WINS", 15, 143, 310, 39, 34, yellow)
		Kit.text(card, "Skill", "+100 SKILL", 15, 187, 310, 29, 25)
		local claim = Kit.button(modal, "DailyClaim", "Claim!", 170, 345, 260, 51, C(84, 235, 24), 32, function()
			context.send("Daily")
		end)
		refresh = function()
			local snapshot = context.snapshot()
			if not snapshot then
				return
			end
			local ready = snapshot.data.daily < math.floor(os.time() / 86400)
			local caption = Kit.captionOf(claim)
			if caption then
				caption.Text = ready and "Claim!" or "Claimed"
			end
			Kit.paint(claim, ready and C(84, 235, 24) or C(115, 118, 126))
			claim.Active = ready
		end
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
			elseif name == "Rebirth" then
				openRebirth()
			elseif name == "Inventory" then
				openInventory(argument)
			elseif name == "Gifts" then
				openGifts()
			elseif name == "Daily" then
				openDaily()
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
		close = function()
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
					end)
				end
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
