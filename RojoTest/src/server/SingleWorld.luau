--!strict
-- Remove remnants of the retired second arena while preserving the authored Ocean Depths.
local Single = {}

function Single.apply(): any
	local removed, parts = 0, 0
	for _, root in { workspace } do
		local targets: { [Instance]: boolean } = {}
		for i, node in root:GetDescendants() do
			local name = node.Name
			if
				(name == "World2" and node:GetAttribute("OceanDepthsPreview") ~= true)
				or name == "World2Map"
				or name:match("^World2Map_")
				or name == "World2Portal"
				or (
					name == "Portal"
					and node.Parent
					and node.Parent.Name == "Lobby"
					and node.Parent.Parent
					and node.Parent.Parent.Name == "World1"
				)
			then
				targets[node] = true
			end
			if i % 3000 == 0 then
				task.wait()
			end
		end
		for node in targets do
			if not node:IsDescendantOf(root) then
				continue
			end
			local parent = node.Parent
			local covered = false
			while parent and parent ~= root do
				if targets[parent] then
					covered = true
					break
				end
				parent = parent.Parent
			end
			if covered then
				continue
			end
			removed += 1
			for _, child in node:GetDescendants() do
				removed += 1
				if child:IsA("BasePart") then
					parts += 1
				end
			end
			node:Destroy()
			task.wait()
		end
	end
	return { objects = removed, parts = parts }
end

return Single
