--!strict
-- Edit-only migration for an explicitly chosen map subtree. Dry run by default.
return function(root: Instance, apply: boolean?)
	local RunService = game:GetService("RunService")
	assert(RunService:IsStudio() and not RunService:IsRunning(), "Run the HD Studs migration in Studio Edit")
	local map = workspace:FindFirstChild("Map")
	assert(map and (root == map or root:IsDescendantOf(map)), "Choose a subtree of Workspace.Map")

	local HDStuds = require(game.ServerScriptService.Server.HDStuds)
	local plan: { { part: Part, tile: number, textures: { Texture } } } = {}
	local result = { eligible = 0, skipped = 0, removed = 0, unavailable = "", skippedExamples = {} :: { string } }
	local variants: { [MaterialVariant]: boolean } = {}
	local objects = root:GetDescendants()
	table.insert(objects, root)
	for _, instance in objects do
		if not instance:IsA("BasePart") then
			continue
		end
		local textures: { Texture } = {}
		local hasOtherAppearance = false
		for _, child in instance:GetChildren() do
			if child:IsA("Texture") and child.Texture == HDStuds.LegacyImage then
				table.insert(textures, child)
			elseif child:IsA("Decal") or child:IsA("SurfaceAppearance") then
				hasOtherAppearance = true
			end
		end
		local first = textures[1]
		if not first then
			continue
		end
		local tile = first.StudsPerTileU
		local variant = HDStuds.variant(instance.Material, tile)
		local compatible = true
		for _, texture in textures do
			if math.abs(texture.StudsPerTileU - tile) > 0.001 or math.abs(texture.StudsPerTileV - tile) > 0.001 then
				compatible = false
				break
			end
		end
		if
			instance:IsA("Part")
			and instance.Shape == Enum.PartType.Block
			and instance.Transparency == 0
			and instance.MaterialVariant == ""
			and not hasOtherAppearance
			and compatible
			and variant
		then
			table.insert(plan, { part = instance, tile = tile, textures = textures })
			variants[variant] = true
			result.eligible += 1
		else
			result.skipped += 1
			if #result.skippedExamples < 12 then
				table.insert(result.skippedExamples, instance:GetFullName())
			end
		end
	end

	for variant in variants do
		local available, missing = HDStuds.checkMaps(variant)
		if not available then
			result.unavailable = missing
			return result
		end
	end
	if not apply or #plan == 0 then
		return result
	end

	local history = game:GetService("ChangeHistoryService")
	local recording = history:TryBeginRecording("BallHDStuds", "Convert blocks to HD Studs")
	-- Studio MCP may already own the outer undo recording.
	local detached: { { texture: Texture, parent: Instance } } = {}
	local changed: { { part: Part, variant: string } } = {}
	local ok, failure = pcall(function()
		for index, entry in plan do
			table.insert(changed, { part = entry.part, variant = entry.part.MaterialVariant })
			HDStuds.apply(entry.part, entry.tile)
			for _, texture in entry.textures do
				table.insert(detached, { texture = texture, parent = entry.part })
				texture.Parent = nil
				result.removed += 1
			end
			if index % 500 == 0 then
				task.wait()
			end
		end
	end)
	if not ok then
		for _, entry in changed do
			entry.part.MaterialVariant = entry.variant
		end
		for _, entry in detached do
			entry.texture.Parent = entry.parent
		end
	else
		for _, entry in detached do
			entry.texture:Destroy()
		end
	end
	if recording then
		history:FinishRecording(
			recording,
			if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		)
	end
	assert(ok, failure)
	return result
end
