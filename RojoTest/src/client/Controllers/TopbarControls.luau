--!strict
-- Screen pixels, independent of the scaled gameplay HUD. The engine owns
-- the free topbar rectangle, including changes to chat/voice and device cutouts.
local GuiService = game:GetService("GuiService")
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local GuiInsets = require(script.Parent.Parent.Modules.GuiInsets)
local Icons = require(script.Parent.Parent.Icons)
local Style = require(script.Parent.Parent.UiStyle)

local Controls = {}
local SIZE, GAP = 44, 12

function Controls.mount(player: Player, openPanel: (string) -> ())
	local gui = Instance.new("ScreenGui")
	gui.Name = "BallTopbar"
	GuiInsets.prepare(gui)
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")
	local root = Instance.new("Frame")
	root.Name = "SafeArea"
	root.BackgroundTransparency = 1
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui
	local anchor = Instance.new("Frame")
	anchor.Name = "TopbarArea"
	anchor.BackgroundTransparency = 1
	anchor.Parent = root
	local row = Instance.new("Frame")
	row.Name = "Controls"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 1)
	row.Parent = anchor
	local slide = Motion.slide(row, "Top")
	local connections: { RBXScriptConnection } = {}
	local cleanups: { () -> () } = {}
	local buttons: { TextButton } = {}
	local names = { "Settings", "UpdateLog", "Dev", "Daily" }
	local captions =
		{ Settings = "Settings", UpdateLog = "Update Log", Dev = "Developer tools", Daily = "Daily Rewards" }
	for index, name in names do
		local button = Instance.new("TextButton")
		button.Name = name
		button.Text = ""
		button.AutoButtonColor = false
		button.BackgroundTransparency = 1
		button.Size = UDim2.fromOffset(SIZE, SIZE)
		button.Position = UDim2.fromOffset((index - 1) * (SIZE + GAP), 0)
		button.SelectionOrder = index
		button:SetAttribute("AccessibleName", captions[name])
		button.Visible = name ~= "Dev"
		button.Parent = row
		table.insert(buttons, button)
		local visual = Instance.new("Frame")
		visual.Name = "ButtonVisual"
		visual.Size = UDim2.fromScale(1, 1)
		visual.BorderSizePixel = 0
		-- Roblox's experience controls use this neutral, almost opaque surface.
		visual.BackgroundColor3 = Color3.fromRGB(18, 18, 21)
		visual.BackgroundTransparency = 0.08
		visual.Parent = button
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = visual
		if name == "Dev" then
			local caption = Instance.new("TextLabel")
			caption.Name = "Caption"
			caption.BackgroundTransparency = 1
			caption.Size = UDim2.fromScale(1, 1)
			caption.Font = Enum.Font.GothamBlack
			caption.Text = "DEV"
			caption.TextSize = 13
			caption.TextColor3 = Style.Text
			caption.Parent = visual
		else
			local icon = Icons.draw(visual, name, nil)
			icon.Size = UDim2.fromScale(0.6, 0.6)
		end
		table.insert(cleanups, Motion.button(button, visual))
		table.insert(
			connections,
			button.Activated:Connect(function()
				if Motion.enabled(button) then
					openPanel(name)
				end
			end)
		)
	end

	local function layout()
		local count = 0
		for _, button in buttons do
			if button.Visible then
				button.Position = UDim2.fromOffset(count * (SIZE + GAP), 0)
				count += 1
			end
		end
		local width = count * SIZE + math.max(0, count - 1) * GAP
		local inset = GuiService:GetInsetArea(Enum.ScreenInsets.TopbarSafeInsets)
		local origin = root.AbsolutePosition
		-- Native 44px controls have a 2px bottom margin in the topbar region.
		-- Keep the same baseline as those controls, rather than the HUD canvas.
		anchor.Position = UDim2.fromOffset(inset.Min.X - origin.X + GAP, inset.Max.Y - origin.Y - SIZE - 2)
		anchor.Size = UDim2.fromOffset(width, SIZE)
		anchor.Visible = inset.Height >= SIZE and inset.Width >= width + GAP
		slide.refresh()
	end
	local function presentation()
		gui.Enabled = player:GetAttribute("MapIntroActive") == false and not GuiService.MenuIsOpen
		if not gui.Enabled then
			Motion.resetButtons(row)
		end
	end
	table.insert(connections, GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(layout))
	table.insert(connections, root:GetPropertyChangedSignal("AbsolutePosition"):Connect(layout))
	table.insert(connections, root:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout))
	table.insert(connections, GuiService:GetPropertyChangedSignal("MenuIsOpen"):Connect(presentation))
	table.insert(connections, player:GetAttributeChangedSignal("MapIntroActive"):Connect(presentation))
	layout()
	presentation()
	return {
		setAdmin = function(authorized: boolean)
			local dev = buttons[3]
			if dev.Visible ~= authorized then
				dev.Visible = authorized
				layout()
			end
		end,
		setHidden = function(value: boolean, reduced: boolean?)
			gui:SetAttribute("ReducedMotion", reduced == true)
			slide.setHidden(value, reduced)
		end,
		destroy = function()
			for _, connection in connections do
				connection:Disconnect()
			end
			for _, cleanup in cleanups do
				cleanup()
			end
			slide.destroy()
			gui:Destroy()
		end,
	}
end

return Controls
