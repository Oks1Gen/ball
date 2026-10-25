--!strict
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Dividers = {}
local HEIGHT = 33
local CANVAS = Vector2.new(2048, 144)

local function part(parent: Instance, name: string, size: Vector3, frame: CFrame, color: Color3, transparency: number)
	local node = Instance.new("Part")
	node.Name = name
	node.Size, node.CFrame = size, frame
	node.Color, node.Transparency = color, transparency
	node.Material = Enum.Material.SmoothPlastic
	node.Anchored = true
	node.CanCollide, node.CanTouch, node.CanQuery = false, false, false
	node.CastShadow = false
	node.Parent = parent
	return node
end

local function title(anchor: BasePart, face: Enum.NormalId, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = face.Name .. "Title"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	gui.CanvasSize = CANVAS
	gui.LightInfluence = 0
	gui.MaxDistance = 360
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Name = "ZoneName"
	label.Size = UDim2.fromOffset(CANVAS.X, CANVAS.Y)
	label.BackgroundTransparency = 1
	label.Text = string.upper(text)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 96
	label.TextScaled = false
	label.TextWrapped = false
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(25, 30, 42)
	stroke.Thickness = 3
	stroke.Parent = label
end

function Dividers.apply(map: any)
	for _, anchor in map.SkippingWorld:GetChildren() do
		if anchor.Name == "LabelAnchor" then
			for _, gui in anchor:GetChildren() do
				if gui:IsA("BillboardGui") then
					local label = gui:FindFirstChildWhichIsA("TextLabel")
					if label then
						local firstLine = label.Text:match("^[^\n]+")
						for _, biome in Config.Biomes do
							if firstLine == biome.name then
								gui:Destroy()
								break
							end
						end
					end
				end
			end
			if #anchor:GetChildren() == 0 then
				anchor:Destroy()
			end
		end
	end
	local root = map:FindFirstChild("ZoneDividers")
	if root then
		for _, group in root:GetChildren() do
			local wall = group:FindFirstChild("Wall")
			if wall and wall:IsA("BasePart") then
				local delta = HEIGHT - wall.Size.Y
				if math.abs(delta) > 0.001 then
					local shift = wall.CFrame.UpVector * delta
					wall.Size = Vector3.new(wall.Size.X, HEIGHT, wall.Size.Z)
					wall.CFrame += shift / 2
					for _, name in { "TopEdge", "TitleAnchor" } do
						local node = group:FindFirstChild(name)
						if node and node:IsA("BasePart") then
							node.CFrame += shift
						end
					end
				end
			end
		end
		return root
	end
	root = Instance.new("Folder")
	root.Name = "ZoneDividers"
	local world = map.SkippingWorld
	for index = 1, #Config.Biomes - 1 do
		local current = world["Water_" .. index]
		local following = world["Water_" .. (index + 1)]
		local back = current.CFrame * CFrame.new(0, current.Size.Y / 2, -current.Size.Z / 2)
		local front = following.CFrame * CFrame.new(0, following.Size.Y / 2, following.Size.Z / 2)
		local boundary = back:Lerp(front, 0.5)
		local left, right = -current.Size.X / 2, current.Size.X / 2
		for _, bank in world:GetChildren() do
			if bank:IsA("BasePart") and bank.Name:match("^BiomeBank" .. index .. "_") then
				for _, x in { -1, 1 } do
					for _, z in { -1, 1 } do
						local point =
							bank.CFrame:PointToWorldSpace(Vector3.new(x * bank.Size.X / 2, 0, z * bank.Size.Z / 2))
						local offset = boundary:PointToObjectSpace(point)
						left, right = math.min(left, offset.X), math.max(right, offset.X)
					end
				end
			end
		end
		boundary *= CFrame.new((left + right) / 2, 0, 0)
		local width = right - left
		local group = Instance.new("Folder")
		group.Name = "Boundary" .. index
		group:SetAttribute("FromZone", Config.Biomes[index].name)
		group:SetAttribute("ToZone", Config.Biomes[index + 1].name)
		group.Parent = root
		local color = Config.Biomes[index + 1].bank:Lerp(Color3.new(1, 1, 1), 0.3)
		part(group, "Wall", Vector3.new(width, HEIGHT, 0.25), boundary * CFrame.new(0, HEIGHT / 2, 0), color, 0.72)
		part(group, "TopEdge", Vector3.new(width, 0.22, 0.3), boundary * CFrame.new(0, HEIGHT, 0), color, 0.2)
		local anchor =
			part(group, "TitleAnchor", Vector3.new(width, 11, 0.1), boundary * CFrame.new(0, HEIGHT + 6.5, 0), color, 1)
		title(anchor, Enum.NormalId.Back, Config.Biomes[index + 1].name)
		title(anchor, Enum.NormalId.Front, Config.Biomes[index].name)
	end
	root.Parent = map
	return root
end

return Dividers
