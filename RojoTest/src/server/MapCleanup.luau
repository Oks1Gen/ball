--!strict
-- Retired visual layers only. Gameplay anchors and collision volumes stay in place.
local Cleanup = {}
local legacyDecor = {
	PalmFrond = true,
	BiomeDecorStem = true,
	CandyCrown = true,
	CrystalSatellite = true,
	MoonOrb = true,
	HackedPixel = true,
}

function Cleanup.reason(part: BasePart, map: Instance): string?
	if part.Transparency ~= 1 or part.CanCollide or part.CanTouch or part.CanQuery then
		return nil
	end
	if #part:GetTags() > 0 then
		return nil
	end
	for _, child in part:GetChildren() do
		if not (child:IsA("Texture") or child:IsA("Decal")) or child.Transparency ~= 1 then
			return nil
		end
	end
	local section: Instance = part
	while section.Parent and section.Parent ~= map do
		section = section.Parent
	end
	if section.Name == "SurfaceRepairs" then
		return "retired surface overlay"
	elseif section.Name == "EnvironmentPolish" or section.Name == "WaterCorridor" then
		return "retired environment decoration"
	elseif section.Name == "NativeEnvironment" then
		if part:GetAttribute("FinaleVisualHidden") or part:GetAttribute("PolarTreeHidden") then
			return "replaced biome tree"
		end
	elseif section.Name == "SkippingWorld" then
		if legacyDecor[part.Name] or part.Name:match("^TrainingStone%d+$") or part.Name:match("^LaneBoard%d+$") then
			return "retired course decoration"
		end
	elseif section.Name == "TrainingZone" then
		if part.Name == "DistanceMark" or part.Name == "LaneEdge" or part.Name == "Arrow" then
			return "replaced training decoration"
		end
	end
	return nil
end

function Cleanup.apply(map: Instance): number
	if map:GetAttribute("RetiredVisualCleanupVersion") == 1 then
		return 0
	end
	local storage = game:GetService("ServerStorage")
	local backups = storage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name = "WorldBackups"
		backups.Parent = storage
	end
	local archive = backups:FindFirstChild("RetiredMapVisuals")
	local removed = 0
	for i, node in map:GetDescendants() do
		if node:IsA("BasePart") then
			local reason = Cleanup.reason(node, map)
			if reason then
				if not archive then
					archive = Instance.new("Folder")
					archive.Name = "RetiredMapVisuals"
					archive.Parent = backups
				end
				node:SetAttribute("CleanupOriginalPath", node:GetFullName())
				node:SetAttribute("CleanupReason", reason)
				local originalParent = Instance.new("ObjectValue")
				originalParent.Name = "CleanupOriginalParent"
				originalParent.Value = node.Parent
				originalParent.Parent = node
				node.Parent = archive
				removed += 1
			end
		end
		if i % 1000 == 0 then
			task.wait()
		end
	end
	map:SetAttribute("RetiredVisualCleanupVersion", 1)
	return removed
end

return Cleanup
