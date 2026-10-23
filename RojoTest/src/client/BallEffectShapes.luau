--!strict
-- Small native shapes avoid mesh uploads and keep the cartoon silhouette in 3D.
local TweenService = game:GetService("TweenService")
local Shapes = {}

function Shapes.part(parent: Instance, name: string, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.CastShadow = false
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Parent = parent
	return part
end

function Shapes.ring(parent: Instance, center: Vector3, normal: Vector3, color: Color3, radius: number)
	local host = Shapes.part(parent, "ImpactRing", color)
	host.Transparency = 1
	host.Size = Vector3.one * 0.1
	host.CFrame = CFrame.lookAt(center, center + normal)
	local segments = 8
	local curve = 4 / 3 * math.tan(math.pi / segments / 2)
	local attachments: { Attachment } = {}
	local beams: { Beam } = {}
	local tween = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	for i = 0, segments do
		local angle = i / segments * math.pi * 2
		local offset = Vector3.new(math.cos(angle), math.sin(angle), 0)
		local tangent = Vector3.new(-math.sin(angle), math.cos(angle), 0)
		local attachment = Instance.new("Attachment")
		attachment.CFrame = CFrame.fromMatrix(offset * 0.55, tangent, Vector3.zAxis)
		attachment.Parent = host
		attachments[i + 1] = attachment
		TweenService:Create(attachment, tween, { Position = offset * radius }):Play()
	end
	for i = 1, segments do
		local arc = Instance.new("Beam")
		arc.Name = "ImpactRingSegment"
		arc.Attachment0, arc.Attachment1 = attachments[i], attachments[i + 1]
		arc.CurveSize0, arc.CurveSize1 = curve * 0.55, curve * 0.55
		arc.Width0, arc.Width1 = 0.12, 0.12
		arc.Segments = 8
		arc.FaceCamera = true
		arc.Color = ColorSequence.new(color)
		arc.LightEmission = 0.8
		arc.Transparency = NumberSequence.new(0.15)
		arc.Parent = host
		beams[i] = arc
		TweenService:Create(arc, tween, {
			CurveSize0 = curve * radius,
			CurveSize1 = curve * radius,
			Width0 = 0.025,
			Width1 = 0.025,
		}):Play()
	end
	local fade = Instance.new("NumberValue")
	fade.Value = 0.15
	fade.Parent = host
	local changed = fade.Changed:Connect(function(value: number)
		local opacity = NumberSequence.new(value)
		for _, arc in beams do
			arc.Transparency = opacity
		end
	end)
	host.Destroying:Once(function()
		changed:Disconnect()
	end)
	TweenService:Create(fade, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.12), {
		Value = 1,
	}):Play()
end

function Shapes.puffs(parent: Instance, center: Vector3, normal: Vector3, color: Color3, strength: number)
	local basis = CFrame.lookAt(center, center + normal)
	for i = 1, 5 do
		local angle = i / 5 * math.pi * 2
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		local sideways = normal:Cross(outward)
		for lobe = 1, 2 do
			local puff = Shapes.part(parent, "ToonDustPuff", color:Lerp(Color3.new(1, 1, 1), (i % 3) * 0.06))
			puff.Shape = Enum.PartType.Ball
			puff.Size = Vector3.one * 0.35
			puff.Transparency = 0.48
			local offset = sideways * (lobe - 1.5) * 0.65 * strength
			puff.Position = center + outward * 0.45 + offset
			local scale = (1.4 + (i % 3) * 0.22) * strength * (lobe == 1 and 1 or 0.7)
			TweenService:Create(puff, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = center
					+ outward * (2.4 + i % 2) * strength
					+ normal * (0.55 + i % 3 * 0.2) * strength
					+ offset,
				Size = Vector3.new(scale * 1.5, scale * 0.85, scale * 1.15),
			}):Play()
			TweenService
				:Create(puff, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.12), {
					Transparency = 1,
				})
				:Play()
		end
	end
	for i = 1, 4 do
		local angle = i / 4 * math.pi * 2 + 0.3
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		local chip = Shapes.part(parent, "DustChip", color:Lerp(Color3.new(0, 0, 0), 0.25))
		chip.Size = Vector3.one * (0.12 + i * 0.035) * strength
		chip.CFrame = CFrame.new(center)
		TweenService:Create(chip, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(center + outward * 1.7 * strength + normal * 1.5 * strength)
				* CFrame.Angles(i, i * 2, i * 3),
		}):Play()
		task.delay(0.18, function()
			if not chip.Parent then
				return
			end
			TweenService
				:Create(chip, TweenInfo.new(0.27, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = CFrame.new(center + outward * 3.4 * strength + normal * 0.05)
						* CFrame.Angles(i * 2, i * 3, i),
					Transparency = 1,
				})
				:Play()
		end)
	end
end

return Shapes
