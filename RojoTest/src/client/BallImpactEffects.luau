--!strict
-- Bounded, client-only impact accents. The owner removes the entire burst after 1.3s.
local TweenService = game:GetService("TweenService")
local Shapes = require(script.Parent.BallEffectShapes)
local Effects = {}
local C = Color3.fromRGB
local COLORS = {
	Red = C(255, 108, 28),
	White = C(230, 251, 255),
	Blue = C(72, 212, 255),
	Purple = C(192, 101, 255),
	Rainbow = C(255, 220, 85),
}

local function spark(parent: Instance, position: Vector3, normal: Vector3, strength: number)
	local attachment = Instance.new("Attachment")
	attachment.CFrame = CFrame.lookAt(position, position + normal) * CFrame.Angles(-math.pi / 2, 0, 0)
	if parent:IsA("BasePart") then
		attachment.CFrame = parent.CFrame:ToObjectSpace(attachment.CFrame)
	end
	attachment.Parent = parent
	local p = Instance.new("ParticleEmitter")
	p.Name = "ImpactEmbers"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Enabled = false
	p.Rate = 0
	p.Color = ColorSequence.new(C(255, 231, 113), COLORS.Red)
	p.LightEmission = 1
	p.Lifetime = NumberRange.new(0.25, 0.65)
	p.EmissionDirection = Enum.NormalId.Top
	p.SpreadAngle = Vector2.new(65, 65)
	p.Speed = NumberRange.new(6 * strength, 15 * strength)
	p.Acceleration = -normal * 16
	p.Drag = 3
	p.Orientation = Enum.ParticleOrientation.VelocityParallel
	p.Squash = NumberSequence.new(-0.5)
	p.Size = NumberSequence.new(0.3 * strength, 0)
	p.Transparency = NumberSequence.new(0.05, 1)
	p.Parent = attachment
	p:Emit(math.round(10 + strength * 10))
	local fire = p:Clone()
	fire.Name = "ImpactFlame"
	fire.Texture = "rbxasset://textures/particles/fire_main.dds"
	fire.Orientation = Enum.ParticleOrientation.FacingCamera
	fire.Squash = NumberSequence.new(0)
	fire.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6 * strength),
		NumberSequenceKeypoint.new(0.25, 2.2 * strength),
		NumberSequenceKeypoint.new(1, 0),
	})
	fire.Lifetime = NumberRange.new(0.2, 0.4)
	fire.Speed = NumberRange.new(2 * strength, 7 * strength)
	fire.Parent = attachment
	fire:Emit(math.round(5 + strength * 5))
end

function Effects.bounce(parent: Instance, position: Vector3, normal: Vector3, id: string, strength: number)
	local color = COLORS[id]
	if not color then
		return
	end
	local host = Shapes.part(parent, id .. "Impact", color)
	host.Size = Vector3.one * 0.1
	host.Transparency = 1
	host.Position = position
	host:SetAttribute("ImpactStyle", id)
	local center = position + normal * 0.18
	local basis = CFrame.lookAt(center, center + normal)
	Shapes.ring(host, center, normal, color, (id == "White" and 4.5 or 3.5) * strength)
	if id == "Red" then
		spark(host, center, normal, strength)
		Shapes.ring(host, center + normal * 0.2, normal, C(255, 213, 80), 2.2 * strength)
	elseif id == "White" then
		Shapes.ring(host, center + normal * 0.45, normal, C(168, 225, 255), 3 * strength)
	elseif id == "Purple" then
		Shapes.ring(host, center + normal * 0.6, normal, C(255, 180, 255), 2.4 * strength)
	end
	local count = strength < 0.5 and 4 or 8
	for i = 1, count do
		local angle = i / count * math.pi * 2
		local outward = basis.RightVector * math.cos(angle) + basis.UpVector * math.sin(angle)
		if id == "Rainbow" then
			local star = Shapes.part(host, "RainbowStar", Color3.fromHSV(i / count, 0.7, 1))
			star.Size = Vector3.one * 0.1
			star.Transparency = 1
			star.Position = center + outward * 0.4
			local gui = Instance.new("BillboardGui")
			local starSize = 1.8 * math.max(strength, 0.6)
			gui.Size = UDim2.fromScale(starSize, starSize)
			gui.LightInfluence = 0
			gui.Parent = star
			local art = Instance.new("TextLabel")
			art.BackgroundTransparency = 1
			art.Size = UDim2.fromScale(1, 1)
			art.Font = Enum.Font.GothamBlack
			art.Text = "★"
			art.TextScaled = true
			art.TextColor3 = star.Color
			art.TextStrokeColor3 = C(70, 42, 105)
			art.TextStrokeTransparency = 0.25
			art.Parent = gui
			TweenService:Create(
				star,
				TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Position = center + outward * 4.8 * strength + normal * (1.2 + i % 3) * strength }
			):Play()
			TweenService:Create(
				art,
				TweenInfo.new(0.65),
				{ Rotation = i % 2 == 0 and 140 or -140, TextTransparency = 1, TextStrokeTransparency = 1 }
			):Play()
		else
			local piece: BasePart
			if id == "Blue" then
				piece = Instance.new("WedgePart")
				piece.Name = "IceImpactShard"
				piece.Anchored = true
				piece.CanCollide, piece.CanTouch, piece.CanQuery = false, false, false
				piece.CastShadow = false
				piece.Parent = host
			else
				piece = Shapes.part(
					host,
					id == "Purple" and "ImpactRune" or id == "White" and "WindStreak" or "HotCinder",
					color
				)
			end
			piece.Color = i % 2 == 0 and color or color:Lerp(Color3.new(1, 1, 1), 0.5)
			piece.Material = id == "Blue" and Enum.Material.Glass or Enum.Material.Neon
			piece.Transparency = id == "Blue" and 0.15 or 0.1
			piece.Size = (
				id == "White" and Vector3.new(0.12, 0.12, 1.4)
				or id == "Blue" and Vector3.new(0.65, 2, 0.95)
				or id == "Purple" and Vector3.new(0.5, 0.5, 0.12)
				or Vector3.new(0.16, 0.3, 0.16)
			) * (id == "Blue" and math.max(strength, 0.6) or strength)
			piece.CFrame = CFrame.lookAt(center + outward * 0.6, center + outward * 2, normal)
				* CFrame.Angles(0, 0, math.pi / 4)
			TweenService:Create(piece, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = piece.CFrame
					+ outward * (id == "White" and 4.8 or 3.6) * strength
					+ normal * (id == "White" and 0.25 or 1.7) * strength,
				Transparency = 1,
				Size = piece.Size * 0.25,
			}):Play()
		end
	end
end

return Effects
