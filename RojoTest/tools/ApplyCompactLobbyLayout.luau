-- Edit migration for reference 3. Validate every original part, including existing custom assets.
assert(not game:GetService("RunService"):IsRunning(), "Run in Edit")
local map = workspace.Map.World1
local backup = assert(
	game.ServerStorage.WorldBackups:FindFirstChild("BeforeCompactLobbyReference3_20261029"),
	"Create paving backup first"
)
local originals, pivots = {}, {}
for index, item in workspace:GetDescendants() do
	if item:IsA("BasePart") then
		originals[item] = {
			item.CFrame,
			item.Size,
			item.Color,
			item.CanCollide,
			item.CanTouch,
			item.CanQuery,
			item.Transparency,
			item.Material,
		}
	elseif item:IsA("Model") then
		pivots[item] = item:GetPivot()
	end
	if index % 1000 == 0 then
		task.wait()
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before compact lobby reference 3")
local source = game.ServerScriptService.Server.CompactLobbyLayout:Clone()
source.Name, source.Parent = "CompactLobbyEditMigration", game.ServerScriptService.Server
local ok, result = pcall(function()
	local module = require(source)
	local root = assert(module.apply(map))
	local hierarchy = require(game.ServerScriptService.Server.MapHierarchy)
	hierarchy.organize(map)
	assert(root:IsA("Folder"), "Map sections must use the canonical Folder container")
	local count = #root:GetDescendants()
	assert(module.apply(map) == root and #root:GetDescendants() == count, "Repeated apply changed the authored result")
	local checked = 0
	for p, state in originals do
		assert(p.Parent, "Original part removed: " .. p.Name)
		assert(p.CFrame == state[1] and p.Size == state[2], "Original geometry moved: " .. p:GetFullName())
		assert(p.Color == state[3] and p.Material == state[8], "Original styling changed: " .. p:GetFullName())
		assert(
			p.CanCollide == state[4] and p.CanTouch == state[5] and p.CanQuery == state[6],
			"Original physics changed"
		)
		if not p:IsDescendantOf(map.GeometryPolish) then
			assert(p.Transparency == state[7], "Protected visual hidden: " .. p:GetFullName())
		end
		checked += 1
		if checked % 1000 == 0 then
			task.wait()
		end
	end
	for model, pivot in pivots do
		assert(model:GetPivot() == pivot, "Original pivot changed: " .. model:GetFullName())
	end
	local parts = 0
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") then
			assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Decoration affects gameplay")
			parts += 1
		end
	end
	return { preservedParts = checked, newCosmeticParts = parts, backup = backup:GetFullName(), idempotent = true }
end)
source:Destroy()
assert(ok, result)
game:GetService("ChangeHistoryService"):SetWaypoint("Compact lobby reference 3")
return game.HttpService:JSONEncode(result)
