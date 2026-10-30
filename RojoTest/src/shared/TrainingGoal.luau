--!strict
-- Cosmetic contact with the real imported net, using the practice-ball timeline.
local Config = require(script.Parent.GameConfig)
local Motion = require(script.Parent.TrainingMotion)
local Goal = {}
local BALL_RADIUS = Config.BallDiameter / 2
-- Root-to-toe reach of the right foot in the kick stance, so the ball rests just ahead of the toe.
local TOE_REACH = 1.25

export type Contact = {
	phase: number,
	position: Vector3,
	normal: Vector3,
	radius: number,
	direction: Vector3,
	hit: Vector2,
	edge: Vector3,
}

export type Shot = { start: Vector3, finish: Vector3, seed: number }

function Goal.net(lane: Instance): BasePart?
	local visual = lane:FindFirstChild("ImportedField")
	if visual then
		for _, part in visual:GetChildren() do
			if part:IsA("BasePart") and part.Name:find("Goal_Net", 1, true) then
				return part
			end
		end
	end
	return nil
end

function Goal.shot(lane: Instance, rootPosition: Vector3, seed: number, cycle: number): Shot?
	local net = Goal.net(lane)
	if not net then
		return nil
	end
	local shotSeed = (math.floor(seed) + math.floor(cycle) * 104729) % 2147483647
	local random = Random.new(shotSeed)
	local ballRadius = BALL_RADIUS
	local margin = ballRadius + 0.18
	local width = math.max(0, net.Size.X / 2 - margin)
	local height = math.max(0, net.Size.Y / 2 - margin)
	local rootLocal = net.CFrame:PointToObjectSpace(rootPosition)
	local side = if rootLocal.Z >= 0 then 1 else -1
	local normal = net.CFrame:VectorToWorldSpace(Vector3.new(0, 0, side))
	local finish = net.CFrame:PointToWorldSpace(
		Vector3.new(
			random:NextNumber(-width, width),
			random:NextNumber(-height, height),
			side * (net.Size.Z / 2 + ballRadius)
		)
	)
	local surface = Config.trainingSurface(lane :: any)
	local toward = Vector3.new(finish.X - rootPosition.X, 0, finish.Z - rootPosition.Z)
	local forward = if toward.Magnitude > 0.01 then toward.Unit else -normal
	local right = forward:Cross(Vector3.yAxis)
	local step = math.min(TOE_REACH + ballRadius, toward.Magnitude * 0.2)
	local start = Vector3.new(rootPosition.X, surface + ballRadius, rootPosition.Z) + forward * step + right * 0.45
	-- Very close to/inside the net, keep the ball on the player's side of its plane.
	local startLocal = net.CFrame:PointToObjectSpace(start)
	local minimum = net.Size.Z / 2 + ballRadius + 0.25
	if startLocal.Z * side < minimum then
		start += normal * (minimum - startLocal.Z * side)
	end
	return { start = start, finish = finish, seed = shotSeed }
end

function Goal.contact(net: BasePart, start: Vector3, finish: Vector3, lane: number): Contact?
	local from = net.CFrame:PointToObjectSpace(start)
	local delta = net.CFrame:VectorToObjectSpace(finish - start)
	if math.abs(delta.Z) < 0.001 then
		return nil
	end
	local sign = if delta.Z > 0 then 1 else -1
	local ballRadius = BALL_RADIUS
	local front = -sign * (net.Size.Z / 2 + ballRadius)
	local alpha = (front - from.Z) / delta.Z
	if alpha < -0.0001 or alpha > 1.0001 then
		return nil
	end
	alpha = math.clamp(alpha, 0, 1)
	local phase = Config.KickContact + Motion.FlightTime * alpha
	local position = Motion.position(start, finish, phase, lane)
	local point = net.CFrame:PointToObjectSpace(position)
	if math.abs(point.X) > net.Size.X / 2 + ballRadius or math.abs(point.Y) > net.Size.Y / 2 + ballRadius then
		return nil
	end
	local normal = net.CFrame:VectorToWorldSpace(Vector3.new(0, 0, -sign))
	local hit = Vector2.new(
		math.clamp(point.X / math.max(0.01, net.Size.X / 2), -1, 1),
		math.clamp(point.Y / math.max(0.01, net.Size.Y / 2), -1, 1)
	)
	return {
		phase = phase,
		position = position - normal * ballRadius,
		normal = normal,
		radius = math.clamp(net.Size.Y * 0.48, 1.8, 3.4),
		direction = (finish - start).Unit,
		hit = hit,
		edge = net.CFrame:VectorToWorldSpace(Vector3.new(hit.X, hit.Y, 0)),
	}
end

return Goal
