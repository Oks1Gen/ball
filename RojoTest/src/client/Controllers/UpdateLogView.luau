--!strict
-- Content only: HudPanels owns the existing window chrome, blur and lifecycle.
local Kit = require(script.Parent.HudKit)
local Style = require(script.Parent.Parent.UiStyle)
local UpdateLog = require(script.Parent.Parent.Modules.UpdateLog)
local Motion = require(game.ReplicatedStorage.Shared.UiMotion)
local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")

local View = {}
local colors = { New = Style.Colors.Green, Improved = Style.Colors.Blue, Fixed = Style.Gold }

local function stack(parent: Instance, name: string, width: number, gap: number): Frame
	local frame = Kit.frame(parent, name, 0, 0, width, 0)
	frame.BackgroundTransparency = 1
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, gap)
	layout.Parent = frame
	return frame
end

local function leftText(
	parent: Instance,
	name: string,
	text: string,
	x: number,
	y: number,
	width: number,
	height: number,
	size: number,
	color: Color3?
): TextLabel
	local label = Kit.text(parent, name, text, x, y, width, height, size, color)
	label.TextXAlignment = Enum.TextXAlignment.Left
	return label
end

local function changeRow(parent: Frame, change: UpdateLog.Change, width: number, fontSize: number): Frame
	local row = stack(parent, change.id, width, 0)
	row:SetAttribute("ChangeId", change.id)
	row:SetAttribute("Expanded", false)
	local header = Kit.frame(row, "Summary", 0, 0, width, 58)
	header.BackgroundTransparency = 1
	header.LayoutOrder = 1
	local body = Kit.frame(row, "Details", 0, 0, width, 0)
	body.BackgroundTransparency = 1
	body.ClipsDescendants = true
	body.LayoutOrder = 2
	local textWidth = width - 40
	local details = change.details or ""
	local detailsHeight = if details == ""
		then 0
		else math.ceil(
			TextService:GetTextSize(details, fontSize - 2, Enum.Font.Gotham, Vector2.new(textWidth, 10000)).Y
		) + 6
	local description =
		leftText(body, "Description", details, 20, 0, textWidth, detailsHeight, fontSize - 2, Style.Muted)
	description.Font = Enum.Font.Gotham
	description.TextWrapped = true
	description.TextYAlignment = Enum.TextYAlignment.Top
	local y = detailsHeight + 10
	for index, credit in change.credits do
		local author = UpdateLog.Authors[credit.author]
		local line = Kit.frame(body, "Credit" .. index, 20, y, textWidth, 30)
		line.BackgroundTransparency = 1
		local inset = 0
		if author.userId then
			local avatar = Instance.new("ImageLabel")
			avatar.Name = "Avatar"
			avatar.Size = UDim2.fromOffset(28, 28)
			avatar.BackgroundTransparency = 1
			avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", author.userId)
			avatar.Parent = line
			Kit.corner(avatar, 14)
			inset = 36
		end
		local label = leftText(
			line,
			"Author",
			author.name .. "  ·  " .. credit.role,
			inset,
			0,
			textWidth - inset,
			28,
			15,
			Style.Gold
		)
		label.TextWrapped = true
		y += 34
	end
	local expandedHeight = y + 8
	local tween: Tween? = nil
	local expanded = false
	local more: TextLabel? = nil
	local function resize(instant: boolean?)
		if tween then
			tween:Cancel()
			tween = nil
		end
		local size = UDim2.fromOffset(width, if expanded then expandedHeight else 0)
		if instant or Motion.reduced(row) then
			body.Size = size
		else
			local transition = TweenService:Create(
				body,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = size }
			)
			tween = transition
			transition:Play()
		end
	end
	local button = Kit.button(header, "Toggle", "", 36, 8, width - 72, 40, Style.PanelDeep, fontSize, function()
		expanded = not expanded
		row:SetAttribute("Expanded", expanded)
		if more then
			more.Text = if expanded then "Less" else "Details"
		end
		resize()
	end)
	Kit.hide(button, "Studs")
	leftText(button, "SummaryText", "• " .. change.summary, 12, 0, width - 178, 40, fontSize)
	local disclosure = leftText(button, "Disclosure", "Details", width - 157, 0, 70, 40, 14, Style.Muted)
	disclosure.TextXAlignment = Enum.TextXAlignment.Right
	more = disclosure
	local screen = row:FindFirstAncestorOfClass("ScreenGui")
	local reducedConnection: RBXScriptConnection? = nil
	if screen then
		reducedConnection = screen:GetAttributeChangedSignal("ReducedMotion"):Connect(function()
			if Motion.reduced(row) then
				resize(true)
			end
		end)
	end
	row.Destroying:Connect(function()
		if tween then
			tween:Cancel()
		end
		if reducedConnection then
			reducedConnection:Disconnect()
		end
	end)
	return row
end

function View.mount(list: ScrollingFrame, width: number, phone: boolean)
	local fontSize = if phone then 18 else 20
	for dayIndex, day in UpdateLog.groupReleases(UpdateLog.Releases) do
		local card = stack(list, "Day_" .. day.date, width, 10)
		card.LayoutOrder = dayIndex
		card.BackgroundColor3 = Style.PanelDeep
		card.BackgroundTransparency = 0.25
		card:SetAttribute("Date", day.date)
		Kit.corner(card, 9)
		Kit.stroke(card, 2)
		local padding = Instance.new("UIPadding")
		padding.PaddingTop = UDim.new(0, 14)
		padding.PaddingBottom = UDim.new(0, 16)
		padding.PaddingLeft = UDim.new(0, 16)
		padding.PaddingRight = UDim.new(0, 16)
		padding.Parent = card
		local contentWidth = width - 32
		local date = leftText(card, "Date", UpdateLog.displayDate(day.date), 0, 0, contentWidth, 28, 22, Style.Gold)
		date.LayoutOrder = 1
		for releaseIndex, release in day.releases do
			local section = stack(card, release.id, contentWidth, 4)
			section.LayoutOrder = releaseIndex + 1
			section:SetAttribute("Version", release.version)
			local heading = Kit.frame(section, "Release", 0, 0, contentWidth, 38)
			heading.BackgroundTransparency = 1
			heading.LayoutOrder = 1
			local version = Kit.frame(heading, "VersionBadge", 0, 2, 114, 30, Style.Colors.Blue)
			Kit.corner(version, 6)
			Kit.stroke(version, 2)
			Kit.text(version, "Version", "v" .. release.version, 4, 0, 106, 30, 19)
			leftText(heading, "Title", release.title, 126, 0, contentWidth - 126, 34, 20)
			local authors = stack(section, "Contributors", contentWidth, 4)
			authors.LayoutOrder = 2
			local credited: { [string]: boolean } = {}
			local authorOrder = 0
			for _, change in release.changes do
				for _, credit in change.credits do
					if not credited[credit.author] then
						credited[credit.author] = true
						authorOrder += 1
						local author = UpdateLog.Authors[credit.author]
						local line = Kit.frame(authors, credit.author, 0, 0, contentWidth, 32)
						line.BackgroundTransparency = 1
						line.LayoutOrder = authorOrder
						local inset = 0
						if author.userId then
							local avatar = Instance.new("ImageLabel")
							avatar.Name = "Avatar"
							avatar.Size = UDim2.fromOffset(28, 28)
							avatar.BackgroundTransparency = 1
							avatar.Image =
								string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48", author.userId)
							avatar.Parent = line
							Kit.corner(avatar, 14)
							inset = 36
						end
						leftText(
							line,
							"Author",
							"By " .. author.name,
							inset,
							0,
							contentWidth - inset,
							28,
							15,
							Style.Muted
						)
					end
				end
			end
			local order = 3
			for _, category in UpdateLog.Categories do
				local shown = false
				for _, change in release.changes do
					if change.category == category then
						if not shown then
							local label =
								leftText(section, category, category, 0, 0, contentWidth, 24, 16, colors[category])
							label.LayoutOrder = order
							order += 1
							shown = true
						end
						local row = changeRow(section, change, contentWidth, fontSize)
						row.LayoutOrder = order
						order += 1
					end
				end
			end
		end
	end
end

return View
