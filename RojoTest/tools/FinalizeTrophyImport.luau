-- Studio Edit only. Run after importing assets/trophy/golden-trophy.fbx.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit mode required")
assert(game.PlaceId == 106456161057435, "Unexpected place")

local current = assert(workspace:FindFirstChild("ImportedTrophy"), "Current trophy missing")
if current:GetAttribute("DurableMeshVersion") == 1 then
	return "Trophy already uses persistent mesh assets"
end
local imported = assert(workspace:FindFirstChild("golden-trophy"), "Import golden-trophy.fbx first")
local pivot = current:GetPivot()
local _, targetSize = current:GetBoundingBox()
local sourceBounds, sourceSize = imported:GetBoundingBox()
assert(math.abs(sourceSize.Y - 8) < 0.01, "Unexpected imported trophy dimensions")

local count = 0
for _, part in imported:GetDescendants() do
	if part:IsA("BasePart") then
		assert(part:IsA("MeshPart") and part.MeshId:match("^rbxassetid://%d+$"), "Unuploaded trophy mesh")
		count += 1
	end
end
assert(count == 28, "Expected all 28 original trophy parts")

local replacement = imported:Clone()
replacement.Name = "ImportedTrophy"
replacement.PrimaryPart = nil
-- The FBX uses world-aligned axes and a bottom-center origin.
replacement.WorldPivot = CFrame.new(sourceBounds.Position - Vector3.new(0, sourceSize.Y / 2, 0))
replacement:ScaleTo(imported:GetScale() * targetSize.Y / sourceSize.Y)
replacement:PivotTo(pivot)
for name, value in current:GetAttributes() do
	replacement:SetAttribute(name, value)
end
replacement:SetAttribute("PendingMeshUpload", false)
replacement:SetAttribute("DurableMeshVersion", 1)

for _, part in replacement:GetDescendants() do
	if part:IsA("MeshPart") then
		local name = part.Name:lower()
		local highlight = name:find("diamond")
			or name:find("jewel")
			or name:find("crystal")
			or name:find("spear")
			or name:find("rim")
			or name:find("facet")
		part.Color = highlight and Color3.fromRGB(255, 220, 79) or Color3.fromRGB(255, 189, 43)
		part.Material = Enum.Material.Metal
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.RenderFidelity = Enum.RenderFidelity.Precise
		part.CollisionFidelity = Enum.CollisionFidelity.Box
	end
end

local bounds, size = replacement:GetBoundingBox()
assert((size - targetSize).Magnitude < 0.01, "Replacement dimensions changed")
assert((replacement:GetPivot().Position - pivot.Position).Magnitude < 0.001, "Replacement pivot moved")
assert(math.abs(bounds.Position.Y - size.Y / 2 - pivot.Position.Y) < 0.01, "Replacement base moved")

local backups = game.ServerStorage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = game.ServerStorage
end
assert(not backups:FindFirstChild("BeforePersistentTrophy_20261022"), "Inspect existing trophy backup")
assert(not backups:FindFirstChild("OriginalTrophyFBX_20261022"), "Inspect existing import backup")
game:GetService("ChangeHistoryService"):SetWaypoint("Before persistent trophy replacement")
current.Name = "BeforePersistentTrophy_20261022"
current.Parent = backups
imported.Name = "OriginalTrophyFBX_20261022"
imported.Parent = backups
replacement.Parent = workspace
game:GetService("Selection"):Set({ replacement })
game:GetService("ChangeHistoryService"):SetWaypoint("Trophy restored with persistent mesh IDs")
return { parts = count, size = tostring(size), pivot = tostring(pivot), persistent = true }
