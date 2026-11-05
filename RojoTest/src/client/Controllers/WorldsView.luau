--!strict
local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.GameConfig)
local Worlds = require(Shared.Worlds)
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Style = require(script.Parent.Parent.UiStyle)
local Kit = require(script.Parent.HudKit)

local e = React.createElement
local C = Color3.fromRGB
local View = {}
local art = { "rbxassetid://134218720041114", "rbxassetid://72479154074171" }
local width, height = 696, 190

local function label(value: string, size: number, right: boolean)
	return e("TextLabel", {
		Position = UDim2.fromOffset(if right then 350 else 18, 9),
		Size = UDim2.fromOffset(if right then 328 else 322, 48),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		Text = value,
		TextSize = size,
		TextColor3 = Style.Text,
		TextXAlignment = if right then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, {
		Outline = e("UIStroke", {
			Color = Style.Ink,
			Thickness = if right then 2.5 else 3.5,
			LineJoinMode = Enum.LineJoinMode.Round,
		}),
	})
end

local function Card(props: any)
	local ref = React.useRef(nil :: Frame?)
	local current = props.current
	local locked = props.locked == true
	local enabled = not current and (not locked or props.affordable)
	local text = if current
		then "YOU ARE HERE"
		elseif locked then "Unlock • " .. Config.format(Worlds[2].cost) .. " Wins"
		else "Teleport"
	local tint = if current then C(48, 161, 250) elseif enabled then C(126, 238, 14) else C(103, 113, 127)
	local buttonWidth = if locked then 245 elseif current then 232 else 177
	React.useEffect(function(): (() -> ())?
		local holder = ref.current
		if not holder then
			return nil
		end
		local button = Kit.button(holder, "Travel", text, 0, 0, buttonWidth, 49, tint, 25, function()
			if enabled then
				props.send("TravelWorld", props.index)
			end
		end)
		button.Selectable = enabled
		return function()
			holder:ClearAllChildren()
		end
	end, { current, locked, enabled })
	return e("ImageLabel", {
		LayoutOrder = props.index,
		Size = UDim2.fromOffset(width, height),
		BorderSizePixel = 0,
		BackgroundColor3 = if props.index == 1 then C(54, 94, 43) else C(29, 89, 109),
		Image = art[props.index],
		ScaleType = Enum.ScaleType.Crop,
	}, {
		Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Outline = e("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = if current then C(85, 199, 255) else Style.Ink,
			Thickness = 3.5,
		}),
		Shade = e("Frame", {
			Size = UDim2.fromScale(1, 1),
			BorderSizePixel = 0,
			BackgroundColor3 = Style.Ink,
			ZIndex = 2,
		}, {
			Corner = e("UICorner", { CornerRadius = UDim.new(0, 8) }),
			Gradient = e("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.14),
					NumberSequenceKeypoint.new(0.34, 0.92),
					NumberSequenceKeypoint.new(0.74, 1),
					NumberSequenceKeypoint.new(1, 0.77),
				}),
			}),
		}),
		Index = label("World " .. props.index, 42, false),
		WorldName = label(Worlds[props.index].name, 32, true),
		Action = e("Frame", {
			ref = ref,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -17, 1, -16),
			Size = UDim2.fromOffset(buttonWidth, 49),
			BackgroundTransparency = 1,
			ZIndex = 4,
		}),
	})
end

function View.mount(modal: Frame, context: any): () -> ()
	local container = Instance.new("Frame")
	container.Name = "WorldCards"
	container.BackgroundTransparency = 1
	container.Position = UDim2.fromOffset(24, 36)
	container.Size = UDim2.fromOffset(width, height * 2 + 17)
	container.Parent = modal
	local root = ReactRoblox.createRoot(container)
	modal.Destroying:Connect(function()
		root:unmount()
	end)
	local priorWorld: number?
	local priorUnlock: boolean?
	local priorFunds: boolean?
	return function()
		local snapshot = context.snapshot()
		if not snapshot then
			return
		end
		local data = snapshot.data
		local unlocked = data.oceanUnlocked == true
		local affordable = data.wins >= Worlds[2].cost
		if priorWorld == data.world and priorUnlock == unlocked and priorFunds == affordable then
			return
		end
		priorWorld, priorUnlock, priorFunds = data.world, unlocked, affordable
		root:render(e(React.Fragment, nil, {
			Layout = e("UIListLayout", { Padding = UDim.new(0, 17), SortOrder = Enum.SortOrder.LayoutOrder }),
			FootballCity = e(Card, { index = 1, current = data.world == 1, send = context.send }),
			OceanDepths = e(Card, {
				index = 2,
				current = data.world == 2,
				locked = not unlocked,
				affordable = affordable,
				send = context.send,
			}),
		}))
	end
end

return View
