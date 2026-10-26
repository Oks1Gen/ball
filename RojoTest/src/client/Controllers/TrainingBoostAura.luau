--!strict
-- Short local bubbles, expanding violet rings and scattered sparks. No physics/assets.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Aura = {}
local LIGHT = Color3.fromRGB(202, 102, 255)
local PURPLE = Color3.fromRGB(137, 35, 235)

function Aura.mount(context: any)
	local folder = Instance.new("Folder")
	folder.Name = "TrainingBoostAuras"
	folder.Parent = context.folder
	local active: { Part } = {}
	local alive = true
	local function clear()
		for _, host in active do
			host:Destroy()
		end
		table.clear(active)
	end
	return {
		emit = function(position: Vector3, kind: string)
			local camera = workspace.CurrentCamera
			if
				not alive
				or not context.enabled()
				or not camera
				or (camera.CFrame.Position - position).Magnitude > 220
			then
				return
			end
			for i = #active, 1, -1 do
				if not active[i].Parent then
					table.remove(active, i)
				end
			end
			while #active >= 6 do
				local oldest = table.remove(active, 1)
				if oldest then
					oldest:Destroy()
				end
			end
			local radius = if kind == "Pop" then 1.5 elseif kind == "Kick" then 2.1 else 3.2
			local duration = if kind == "Pop" then 0.38 elseif kind == "Kick" then 0.48 else 0.7
			local host = Instance.new("Part")
			host.Name = "TrainingBoost" .. kind
			host.Anchored = true
			host.CanCollide, host.CanTouch, host.CanQuery = false, false, false
			host.CastShadow = false
			host.Shape = Enum.PartType.Ball
			host.Material = Enum.Material.Neon
			host.Color = PURPLE
			host.Transparency = 0.72
			host.Size = Vector3.one * 0.6
			local toward = camera.CFrame.Position - position
			host.CFrame =
				CFrame.lookAt(position, position + (if toward.Magnitude > 0.01 then toward.Unit else Vector3.zAxis))
			local points: { { node: Attachment, offset: Vector3 } } = {}
			local beams: { Beam } = {}
			local function point(offset: Vector3): Attachment
				local node = Instance.new("Attachment")
				node.Position = offset * 0.25
				node.Parent = host
				table.insert(points, { node = node, offset = offset })
				return node
			end
			local function beam(a: Attachment, b: Attachment, width: number)
				local ribbon = Instance.new("Beam")
				ribbon.Attachment0, ribbon.Attachment1 = a, b
				ribbon.FaceCamera = true
				ribbon.Segments = 1
				ribbon.Width0, ribbon.Width1 = width, width * 0.65
				ribbon.Color = ColorSequence.new(LIGHT, PURPLE)
				ribbon.Transparency = NumberSequence.new(0.05)
				ribbon.LightEmission, ribbon.LightInfluence = 0.45, 0
				ribbon.Parent = host
				table.insert(beams, ribbon)
			end
			for layer = 1, 2 do
				local ring: { Attachment } = {}
				for i = 1, 24 do
					local angle = i / 24 * math.pi * 2
					ring[i] = point(
						Vector3.new(math.cos(angle), math.sin(angle), 0) * radius * (if layer == 1 then 1 else 0.72)
					)
				end
				for i = 1, 24 do
					beam(ring[i], ring[i % 24 + 1], if layer == 1 then 0.1 else 0.05)
				end
			end
			for i = 1, 10 do
				local angle = i / 10 * math.pi * 2 + 0.15
				local direction = Vector3.new(math.cos(angle), math.sin(angle), 0.18 * math.sin(i))
				beam(point(direction * radius * 1.05), point(direction * radius * 1.35), 0.12)
			end
			local progress = Instance.new("NumberValue")
			progress.Parent = host
			local changed = progress.Changed:Connect(function(t: number)
				if not alive or not context.enabled() then
					host:Destroy()
					return
				end
				local expansion = 0.25 + (1 - (1 - t) ^ 3)
				for _, entry in points do
					entry.node.Position = entry.offset * expansion
				end
				for _, ribbon in beams do
					ribbon.Transparency = NumberSequence.new(0.05 + 0.95 * t)
				end
				host.Size = Vector3.one * (0.6 + radius * t * 1.4)
				host.Transparency = 0.72 + 0.28 * t
			end)
			host.Destroying:Once(function()
				changed:Disconnect()
			end)
			host.Parent = folder
			table.insert(active, host)
			TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Value = 1 }):Play()
			Debris:AddItem(host, duration + 0.08)
		end,
		clear = clear,
		destroy = function()
			alive = false
			clear()
			folder:Destroy()
		end,
	}
end

return Aura
