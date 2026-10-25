--!strict
-- Only organizational containers change class; individual prop models keep pivots.
local Hierarchy = {}
local references: { ObjectValue }? = nil

function Hierarchy.container(): Folder
	local existing = workspace:FindFirstChild("Map")
	if existing then
		assert(existing:IsA("Folder"), "Workspace.Map must be a Folder")
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "Map"
	folder.Parent = workspace
	return folder
end

local function folderFrom(node: Instance): Instance
	if not node:IsA("Model") then
		return node
	end
	local folder = Instance.new("Folder")
	folder.Name = node.Name
	for key, value in node:GetAttributes() do
		folder:SetAttribute(key, value)
	end
	folder:SetAttribute("MapPivot", node:GetPivot())
	for _, tag in node:GetTags() do
		folder:AddTag(tag)
	end
	folder.Parent = node.Parent
	if not references then
		local found: { ObjectValue } = {}
		for _, candidate in game:GetDescendants() do
			if candidate:IsA("ObjectValue") then
				table.insert(found, candidate)
			end
		end
		references = found
	end
	for _, reference in references :: { ObjectValue } do
		if reference.Value == node then
			reference.Value = folder
		end
	end
	for _, child in node:GetChildren() do
		child.Parent = folder
	end
	node:Destroy()
	return folder
end

function Hierarchy.organize(world: Instance)
	for _, section in world:GetChildren() do
		folderFrom(section)
	end
end

function Hierarchy.migrate()
	local maps = Hierarchy.container()
	for index, legacyName in { "ProgressionMap", "World2Map" } do
		local name = "World" .. index
		local legacy = workspace:FindFirstChild(legacyName)
		assert(not (legacy and maps:FindFirstChild(name)), "Both legacy and organized world exist")
		local world = legacy or maps:FindFirstChild(name)
		if world then
			world = folderFrom(world)
			world.Name = name
			world.Parent = maps
		end
	end
end

function Hierarchy.offset(world: Instance, delta: Vector3)
	for _, node in world:GetDescendants() do
		if node:IsA("BasePart") then
			node.CFrame += delta
		elseif node:IsA("Model") then
			node.WorldPivot += delta
		end
	end
end

return Hierarchy
