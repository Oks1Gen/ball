-- Scene regression: both caption tiers, their complete animated silhouettes, and preserved landmarks.
local world = workspace.Map.World1
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local source = game.ReplicatedStorage.Shared.BallVisuals:Clone()
source.Parent = game.ReplicatedStorage.Shared
local Visuals = require(source)
source:Destroy()
local shop = Refs.balls(world)
local signs = {}
for _, display in shop.Displays:GetChildren() do
	local gui = display.LabelAnchor.BallLabel
	assert(gui.Enabled and gui.Power.Visible and gui.Price.Visible and gui.Status.Visible, "Missing ball caption")
	assert(gui.StudsOffsetWorldSpace == Vector3.zero, "Unequal per-tier caption offset")
	assert(display.Ball:GetAttribute("DisplayLabelGap") == 3, "Unequal caption clearance")
	local base = Visuals.displayOrigin(display.Ball)
	table.insert(signs, { anchor = display.LabelAnchor, gui = gui, ball = display.Ball:Clone(), base = base })
end

local function bounds(ball, camera)
	local cf, size = ball:GetBoundingBox()
	local lo, hi = Vector2.one * math.huge, -Vector2.one * math.huge
	for _, x in { -0.5, 0.5 } do
		for _, y in { -0.5, 0.5 } do
			for _, z in { -0.5, 0.5 } do
				local q = camera.CFrame:PointToObjectSpace(cf:PointToWorldSpace(size * Vector3.new(x, y, z)))
				local p = Vector2.new(q.X, q.Y) / -q.Z
				lo, hi = lo:Min(p), hi:Max(p)
			end
		end
	end
	return { low = lo, high = hi }
end
local function overlaps(a, b)
	return math.min(a.high.X, b.high.X) > math.max(a.low.X, b.low.X) + 0.00001
		and math.min(a.high.Y, b.high.Y) > math.max(a.low.Y, b.low.Y) + 0.00001
end
local views =
	{ Vector3.new(55, 26, 196), Vector3.new(42, 29, 181), Vector3.new(42, 29, 220), Vector3.new(30, 27, 204.45) }
local camera = Instance.new("Camera")
for _, eye in views do
	camera.CFrame = CFrame.lookAt(eye, Vector3.new(8, 29, 204.45))
	for frame = 0, 72 do -- Complete 22.5-second yaw cycle and all nine bob cycles.
		local depth, near = 0, math.huge
		for _, sign in signs do
			sign.ball:PivotTo(Visuals.standPose(sign.base, frame * 0.3125, 0))
			local distance = -camera.CFrame:PointToObjectSpace(sign.base.Position).Z - 1
			depth, near = math.max(depth, distance), math.min(near, distance)
		end
		local rectangles, balls = {}, {}
		for _, sign in signs do
			local size = Vector2.new(sign.gui.Size.X.Scale, sign.gui.Size.Y.Scale)
			local position = Visuals.captionPosition(sign.ball, camera, depth, 3 * depth / near, size.Y)
			assert(position, "Missing caption projection")
			local q = camera.CFrame:PointToObjectSpace(position)
			local center = Vector2.new(q.X, q.Y) / -q.Z
			local half = size / (2 * depth)
			local rectangle = { low = center - half, high = center + half }
			local ball = bounds(sign.ball, camera)
			assert(math.abs((rectangle.low.Y - ball.high.Y) * near - 3) < 0.0001, "Unequal visible ball clearance")
			assert(math.abs(center.X - (ball.low.X + ball.high.X) / 2) < 0.0001, "Caption belongs to a different ball")
			table.insert(rectangles, rectangle)
			table.insert(balls, ball)
		end
		for i, a in rectangles do
			for j = i + 1, #rectangles do
				assert(not overlaps(a, rectangles[j]), "Ball captions overlap from an approach")
			end
			for _, ball in balls do
				assert(not overlaps(a, ball), "A ball overlaps caption text")
			end
		end
		if frame % 12 == 0 then
			task.wait()
		end
	end
end
for _, sign in signs do
	sign.ball:Destroy()
end
camera:Destroy()

local lanes = 0
for _, lane in Refs.training(world):GetChildren() do
	local anchor = lane:FindFirstChild("GoalSignAnchor")
	local visual = lane:FindFirstChild("BiomeReferenceVisuals")
	if anchor and visual then
		local gui = anchor.TrainingLaneSign
		local bottom = anchor.Position.Y - gui.Size.Y.Scale / 2
		for _, p in visual:GetDescendants() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local cf, size = p.CFrame, p.Size
				local top = p.Position.Y
					+ (
							math.abs(cf.RightVector.Y) * size.X
							+ math.abs(cf.UpVector.Y) * size.Y
							+ math.abs(cf.LookVector.Y) * size.Z
						)
						/ 2
				assert(bottom > top + 0.5, "Training caption overlaps its crest")
			end
		end
		assert(gui.Status.Size.Y.Scale >= 0.269 and gui.Multiplier.Size.Y.Scale >= 0.319, "Small training text")
		lanes += 1
	end
end

-- The fourth stand is the live Robux ranking (docs/leaderboards.md).
local donation = Refs.rankings(world).donated
assert(donation.Panel.RankingGui.Row1.Visible, "Donation board rows missing")
assert(donation.HeaderSurface.HeaderGui.Band.Title.Text == "ДОНАТ", "Donation title missing")
assert(donation.HeaderSurface.HeaderGui.Band.CategoryIcon.Image ~= "", "Donation icon missing")

if game:GetService("RunService"):IsRunning() and game:GetService("RunService"):IsClient() then
	local liveCamera = workspace.CurrentCamera
	local initial = liveCamera.CFrame
	local sizes = {}
	for _sample = 1, 18 do
		game:GetService("RunService").RenderStepped:Wait()
		local depth, near = 0, math.huge
		for _, display in shop.Displays:GetChildren() do
			local base = Visuals.displayOrigin(display.Ball)
			local distance = -liveCamera.CFrame:PointToObjectSpace(base.Position).Z - 1
			depth, near = math.max(depth, distance), math.min(near, distance)
		end
		for _, display in shop.Displays:GetChildren() do
			local gui = display.LabelAnchor.BallLabel
			local position = liveCamera.CFrame:PointToObjectSpace(display.LabelAnchor.Position)
			local ball = bounds(display.Ball, liveCamera)
			local gap = (position.Y / -position.Z - gui.Size.Y.Scale / (2 * -position.Z) - ball.high.Y) * near
			assert(math.abs(gap - 3) < 0.015, "Actual animated caption clearance drifted")
			local size = Vector2.new(gui.Power.TextBounds.Y, gui.Price.TextBounds.Y)
			if sizes.reference then
				assert((size - sizes.reference).Magnitude < 2, "Unequal caption text sizes")
			else
				sizes.reference = size
			end
		end
		task.wait(0.15)
	end
	assert(liveCamera.CFrame == initial, "Keep the verification camera fixed")
end

local landmarks = 0
for _, zone in Refs.course(world).Zones:GetChildren() do
	for _, model in zone.Environment.Cityscape:GetChildren() do
		if model:GetAttribute("CityLandmark") then
			landmarks += 1
			for _, p in model:GetDescendants() do
				if p:IsA("BasePart") then
					assert(
						p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
						"Landmark changes physics"
					)
					local localPoint = zone.Field.CFrame:PointToObjectSpace(p.Position)
					assert(math.abs(localPoint.X) - p.Size.X / 2 > zone.Field.Size.X / 2, "Landmark enters the pitch")
					assert(math.abs(localPoint.Z) + p.Size.Z / 2 < zone.Field.Size.Z / 2, "Landmark crosses its zone")
				end
			end
		end
	end
end
assert(#signs == 10 and lanes == 7 and landmarks == 8, "Incomplete readability pass")
return { ballCaptions = #signs, approachViews = #views, clearTrainingCaptions = lanes, landmarks = landmarks }
