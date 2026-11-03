--!strict
-- Names from saved places and their reversible layout journal; no geometry changes.
local Migration = {}
local names = {
	LaunchArea = "KickZone",
	ThrowingApron = "KickZoneFloor",
	ThrowZonePrint = "KickZonePrint",
	ThrowZoneLabel = "KickZoneLabel",
	ThrowZoneLettering = "KickZoneLettering",
	ThrowZoneChecker = "KickZoneChecker",
	ThrowZoneFrame = "KickZoneFrame",
	ThrowZoneStuds = "KickZoneStuds",
	SkippingApronStuds = "KickZoneStuds",
	ThrowZonePath = "KickZonePath",
	ThrowZoneThreshold = "KickZoneThreshold",
	ThrowPathArrows = "KickPathArrows",
	VFX_ThrowPathArrows = "VFX_KickPathArrows",
	ThrowPad = "KickPad",
}

function Migration.apply(world: Instance): number
	local changed = 0
	local roots = { world }
	local states = game.ServerStorage:FindFirstChild("WorldLayoutState")
	local state = states and states:FindFirstChild(world.Name)
	if state then
		table.insert(roots, state)
	end
	for _, root in roots do
		for i, node in root:GetDescendants() do
			local name = names[node.Name]
			if name then
				node.Name = name
				changed += 1
			end
			local original = node:GetAttribute("OriginalName")
			if typeof(original) == "string" and names[original] then
				node:SetAttribute("OriginalName", names[original])
			end
			local key = node:GetAttribute("LayoutKey")
			if typeof(key) == "string" then
				node:SetAttribute("LayoutKey", (key:gsub("/LaunchArea$", "/KickZone")))
			end
			if node:IsA("ObjectValue") then
				node.Name = node.Name:gsub("/LaunchArea$", "/KickZone")
			end
			if node:IsA("TextLabel") and node.Text:upper() == "THROW ZONE" then
				node.Text = "KICK ZONE"
			end
			if i % 1500 == 0 then
				task.wait()
			end
		end
	end
	return changed
end

return Migration
