--!strict
-- Client-side direction arrows, independent of onboarding, HUD and economy.
-- Copy this ModuleScript to another project without any supporting modules.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local DirectionGuide = {}

export type Target = Vector3 | BasePart | Model | Attachment | (() -> any)
export type Options = {
	name: string?,
	parent: Instance?,
	source: Target?,
	target: Target?,
	automatic: boolean?,
	enabled: boolean?,
	reducedMotion: boolean?,
	texture: string?,
	width: number?,
	spacing: number?,
	speed: number?,
	minDistance: number?,
	startOffset: number?,
	outlineWidth: number?,
	color: Color3?,
	outlineColor: Color3?,
}

local function position(value: any): Vector3?
	if typeof(value) == "function" then
		value = value()
	end
	if typeof(value) == "Instance" then
		if not value:IsDescendantOf(workspace) then
			return nil
		end
		if value:IsA("BasePart") then
			return value.Position
		end
		if value:IsA("Attachment") then
			return value.WorldPosition
		end
		if value:IsA("Model") then
			return value:GetPivot().Position
		end
	elseif typeof(value) == "Vector3" then
		if value.X == value.X and value.Y == value.Y and value.Z == value.Z and value.Magnitude < math.huge then
			return value
		end
	end
	return nil
end

function DirectionGuide.new(options: Options?)
	local config: Options = options or {}
	assert(config.automatic == false or RunService:IsClient(), "Automatic DirectionGuide must run on the client")
	local width = config.width or 2
	local spacing = config.spacing or 3.3
	local minimum = config.minDistance or 4
	local inset = config.startOffset or 2.5
	local speed = config.speed or 1.5
	assert(width > 0 and spacing > 0 and minimum >= 0 and inset >= 0, "Invalid direction guide dimensions")
	local folder = Instance.new("Folder")
	folder.Name = config.name or "DirectionGuide"
	folder.Parent = config.parent or workspace
	local function anchor(name: string): BasePart
		local part = Instance.new("Part")
		part.Name = name
		part.Size = Vector3.one * 0.1
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Parent = folder
		return part
	end
	local startPart, endPart = anchor("PlayerAnchor"), anchor("GoalAnchor")
	local a, b = Instance.new("Attachment"), Instance.new("Attachment")
	a.Parent, b.Parent = startPart, endPart
	local beam = Instance.new("Beam")
	beam.Name = "DirectionArrows"
	beam.Attachment0, beam.Attachment1 = a, b
	-- Ready-made public texture from Roblox's Mansion of Wonder beam tutorial.
	beam.Texture = config.texture or "rbxassetid://5886559421"
	beam.TextureMode = Enum.TextureMode.Static
	beam.TextureLength = spacing
	beam.TextureSpeed = 0
	beam.Width0, beam.Width1 = width, width
	beam.Color = ColorSequence.new(config.color or Color3.new(1, 1, 1))
	beam.FaceCamera = true
	beam.LightInfluence, beam.LightEmission = 0, 0
	beam.Transparency = NumberSequence.new(0)
	beam.Enabled = false
	beam.Parent = startPart
	local outlines: { Beam } = {}
	for _, offset in { -0.035, 0, 0.035 } do
		local edge = beam:Clone()
		edge.Name = "ArrowOutline"
		edge.Color = ColorSequence.new(config.outlineColor or Color3.new(0, 0, 0))
		edge.Width0, edge.Width1 = width + (config.outlineWidth or 0.4), width + (config.outlineWidth or 0.4)
		edge:SetAttribute("TextureOffset", offset)
		edge.Parent = startPart
		table.insert(outlines, edge)
	end
	beam.ZOffset = 0.05
	local source: any = config.source
		or function()
			local player = Players.LocalPlayer
			local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			return if root and root:IsA("BasePart") then root.Position - Vector3.new(0, 1, 0) else nil
		end
	local target: any = config.target
	local enabled = config.enabled ~= false
	local reduced = config.reducedMotion == true
	local destroyed = false
	local connection: RBXScriptConnection? = nil
	local handle = {}
	local function hide()
		beam.Enabled = false
		for _, edge in outlines do
			edge.Enabled = false
		end
	end
	function handle:setSource(value: Target?)
		source = value
	end
	function handle:setTarget(value: Target?)
		target = value
	end
	function handle:setEnabled(value: boolean)
		enabled = value
		if not value then
			hide()
		end
	end
	function handle:setReducedMotion(value: boolean)
		reduced = value
	end
	function handle:update(now: number?, reducedMotion: boolean?)
		if destroyed then
			return
		end
		hide()
		if not enabled then
			return
		end
		local origin, destination = position(source), position(target)
		if not origin or not destination then
			return
		end
		local delta = destination - origin
		if delta.Magnitude < math.max(minimum, inset + 0.01) then
			return
		end
		startPart.Position = origin + delta.Unit * inset
		endPart.Position = destination
		local paused = if reducedMotion == nil then reduced else reducedMotion
		local offset = if paused then 0 else ((now or os.clock()) * speed) % 1
		beam:SetTextureOffset(offset)
		for _, edge in outlines do
			edge:SetTextureOffset(offset + (edge:GetAttribute("TextureOffset") :: number))
			edge.Enabled = true
		end
		beam.Enabled = true
	end
	function handle:destroy()
		if destroyed then
			return
		end
		destroyed = true
		if connection then
			connection:Disconnect()
		end
		folder:Destroy()
	end
	if config.automatic ~= false then
		connection = RunService.RenderStepped:Connect(function()
			handle:update()
		end)
	end
	return handle
end

return DirectionGuide
