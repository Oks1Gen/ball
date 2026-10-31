--!strict
-- Streaks rushing past the owner's camera on fast shots, tinted with the trail.
-- A ring of emitters rides ahead of the camera; particles are locked to it, so
-- the lines move only relative to the view and keep the centre (the ball) clear.
local Debris = game:GetService("Debris")
local Kit = require(script.Parent.TrailKit)
local SpeedLines = {}

local STREAK = "rbxassetid://6660412891"
local RING = 10
local AHEAD = 34
local RATE = 20

export type Handle = {
	update: (camera: CFrame, pace: number) -> (),
	destroy: () -> (),
}

function SpeedLines.new(color: Color3): Handle
	local rig = Instance.new("Part")
	rig.Name = "SpeedLines"
	rig.Anchored = true
	rig.CanCollide, rig.CanTouch, rig.CanQuery = false, false, false
	rig.CastShadow = false
	rig.Transparency = 1
	rig.Size = Vector3.one * 0.1
	rig.Parent = workspace
	local emitters: { ParticleEmitter } = {}
	for i = 1, RING do
		local angle = (i - 1) / RING * math.pi * 2
		local radius = 9 + (i % 3) * 2.5
		local source = Instance.new("Attachment")
		source.Position = Vector3.new(math.cos(angle) * radius * 1.6, math.sin(angle) * radius, -AHEAD)
		source.Parent = rig
		-- Back is +Z: from far ahead straight towards the camera.
		table.insert(
			emitters,
			Kit.emitter(source, {
				Name = "SpeedLine",
				Texture = STREAK,
				Orientation = Enum.ParticleOrientation.VelocityParallel,
				Rotation = Kit.range(90),
				LockedToPart = true,
				Color = Kit.colors(Color3.new(1, 1, 1), color),
				-- Low glow: additive white disappears against the sky.
				LightEmission = 0.2,
				EmissionDirection = Enum.NormalId.Back,
				Speed = Kit.range(150, 210),
				SpreadAngle = Vector2.new(6, 6),
				Lifetime = Kit.range(0.16, 0.24),
				Size = Kit.seq(0, 0.5, 1, 0.9),
				Transparency = Kit.seq(0, 1, 0.25, 0.35, 1, 1),
				Enabled = true,
			})
		)
	end
	local alive = true
	return {
		update = function(camera: CFrame, pace: number)
			if not alive then
				return
			end
			rig.CFrame = camera
			for _, emitter in emitters do
				emitter.Rate = RATE * pace
			end
		end,
		destroy = function()
			if not alive then
				return
			end
			alive = false
			for _, emitter in emitters do
				emitter.Enabled = false
			end
			-- Let the lines already in flight finish.
			Debris:AddItem(rig, 0.3)
		end,
	}
end

return SpeedLines
