--!strict
-- Studio Edit/Server audit. No profile or player state changes.
-- capture() + compare() prove reparenting preserves the authored geometry.
local Verify = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local baseline: { [BasePart]: any } = {}
local pivots: { [Model]: CFrame } = {}

function Verify.capture()
	baseline = {}
	pivots = {}
	for _, root in { workspace:FindFirstChild("Map"), workspace:FindFirstChild("AllBalls_NoTextures") } do
		if root then
			for _, node in root:GetDescendants() do
				if node:IsA("Model") and not node:GetAttribute("LayoutKey") then
					pivots[node] = node:GetPivot()
				end
				if node:IsA("BasePart") then
					baseline[node] =
						{ node.CFrame, node.Size, node.Transparency, node.CanCollide, node.CanTouch, node.CanQuery }
				end
			end
		end
	end
end

function Verify.compare(): any
	local checked, parked = 0, 0
	for node, pivot in pivots do
		assert(node:GetPivot() == pivot, "Authored model pivot changed: " .. node:GetFullName())
	end
	for node, props in baseline do
		assert(node.Parent, "An authored part was deleted")
		assert(node.CFrame == props[1] and node.Size == props[2], "Geometry changed: " .. node:GetFullName())
		assert(node.Transparency == props[3], "Visibility changed: " .. node:GetFullName())
		assert(
			node.CanCollide == props[4] and node.CanTouch == props[5] and node.CanQuery == props[6],
			"Physics changed: " .. node:GetFullName()
		)
		if not node:IsDescendantOf(workspace) then
			assert(
				node.Transparency == 1 and not node.CanCollide and not node.CanTouch and not node.CanQuery,
				"An active part was parked: " .. node:GetFullName()
			)
			parked += 1
		end
		checked += 1
	end
	return { unchangedParts = checked, parkedInertOriginals = parked }
end

function Verify.run(): any
	local worlds, displays, fields, lanes, eggs = 0, 0, 0, 0, 0
	for _, world in workspace.Map:GetChildren() do
		assert(
			world:GetAttribute("WorldLayoutVersion") == 1 and world:GetAttribute("WorldLayoutReady"),
			"Layout not ready"
		)
		for _, node in world:GetChildren() do
			assert(
				node.Name == "Lobby" or node.Name == "FootballCourse" or node.Name == "TrainingArea",
				"Unexpected world root: " .. node:GetFullName()
			)
		end
		local shop = assert(Refs.balls(world))
		assert(shop:IsA("Model"), "BallShop must be movable as a whole")
		for _, item in Config.Stones do
			local display = shop.Displays:FindFirstChild(string.format("Display%02d", item.displaySlot))
			assert(display and display:IsA("Model"), "Missing display")
			local ball = assert(display:FindFirstChild("Ball"))
			local label = assert(display:FindFirstChild("LabelAnchor"))
			assert(ball:GetAttribute("BallId") == item.id, "Wrong ball")
			assert(ball.DisplayLabel.Value == label, "Detached label")
			assert(label:FindFirstChildWhichIsA("BillboardGui"), "Missing label GUI")
			assert(display.PurchaseAnchor:FindFirstChildWhichIsA("ProximityPrompt"), "Missing purchase prompt")
			displays += 1
		end
		for i = 1, 8 do
			assert(Refs.field(world, i), "Missing field")
			fields += 1
		end
		for i = 1, 7 do
			local lane = Refs.training(world):FindFirstChild("TrainingLane" .. i)
			assert(
				lane and lane:FindFirstChild("StartingPad") and lane:FindFirstChild("TrainingStrip"),
				"Broken training lane"
			)
			lanes += 1
		end
		for _, egg in Config.Eggs do
			local model = Refs.eggs(world):FindFirstChild("Egg_" .. egg.id)
			assert(model and model:FindFirstChild("EggShell"), "Missing egg")
			eggs += 1
		end
		assert(world.Name == "World1" and Refs.kickZoneFloor(world), "Missing remaining world/launch")
		assert(not world.Lobby:FindFirstChild("Portal"), "Retired portal remains")
		assert(Refs.volcanic(world).InteractionAnchor, "Missing special egg")
		local rankings = Refs.rankings(world)
		if rankings then
			for _, name in { "skill", "wins", "best" } do
				assert(rankings[name].Panel:FindFirstChild("RankingGui"), "Detached leaderboard GUI")
			end
		end
		for _, node in world:GetDescendants() do
			if node:IsA("BasePart") and node.Transparency == 1 then
				assert(node:GetAttribute("PartRole"), "Unclassified invisible part: " .. node:GetFullName())
			end
			assert(
				node.Name ~= "SkippingWorld"
					and node.Name ~= "ImprovedLobbyFlowers"
					and node.Name ~= "SurfaceSeparation",
				"Legacy map bucket remains"
			)
		end
		worlds += 1
	end
	return { worlds = worlds, displays = displays, fields = fields, lanes = lanes, eggs = eggs }
end

-- Work on an unparented disposable copy; the authored scene stays untouched.
function Verify.moveShop(world: Instance): number
	local copy = Refs.balls(world):Clone()
	local ok, result = pcall(function()
		local visuals = require(game.ReplicatedStorage.Shared.BallVisuals)
		local before = {}
		for _, display in copy.Displays:GetChildren() do
			local base, label = visuals.displayOrigin(display.Ball)
			before[display] = { base = base, label = label, prompt = display.PurchaseAnchor.Position }
		end
		local delta = CFrame.new(40, 15, -25) * CFrame.Angles(0, math.pi / 2, 0)
		copy:PivotTo(delta * copy:GetPivot())
		local checked = 0
		for display, initial in before do
			local base, label = visuals.displayOrigin(display.Ball)
			assert(base and label, "Missing local animation origin")
			assert((base.Position - (delta * initial.base).Position).Magnitude < 0.001, "Ball animation snaps back")
			assert((label - delta:PointToWorldSpace(initial.label)).Magnitude < 0.001, "Label animation snaps back")
			assert(
				(display.PurchaseAnchor.Position - delta:PointToWorldSpace(initial.prompt)).Magnitude < 0.001,
				"Detached purchase prompt"
			)
			assert(display.Ball.DisplayLabel.Value == display.LabelAnchor, "Copied label points outside its display")
			checked += 1
		end
		return checked
	end)
	copy:Destroy()
	assert(ok, result)
	return result
end

return Verify
