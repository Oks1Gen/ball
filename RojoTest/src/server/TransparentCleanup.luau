--!strict
-- Delete reviewed, retired visual layers only. Transparency alone is insufficient.
local Cleanup = {}
local Refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Goal = require(game.ReplicatedStorage.Shared.TrainingGoal)

local function top(part: BasePart): number
	local cf, size = part.CFrame, part.Size
	return part.Position.Y
		+ (
				math.abs(cf.RightVector.Y) * size.X
				+ math.abs(cf.UpVector.Y) * size.Y
				+ math.abs(cf.LookVector.Y) * size.Z
			)
			/ 2
end

local function protectInputs(map: Instance): { [Instance]: string }
	local protected: { [Instance]: string } = {}
	for _, world in map:GetChildren() do
		local lanes = Refs.training(world)
		if lanes then
			for _, lane in lanes:GetChildren() do
				if lane:IsA("Model") then
					local pad = lane:FindFirstChild("StartingPad")
					if pad then
						protected[pad] = "training start anchor"
					end
					local net = Goal.net(lane)
					if net then
						protected[net] = "training shot target"
					end
					-- TrainingLaneSigns also reads the highest imported Goal part.
					local imported = lane:FindFirstChild("ImportedField")
					local highest: BasePart? = nil
					local height = -math.huge
					if imported then
						for _, part in imported:GetChildren() do
							if part:IsA("BasePart") and part.Name:find("Goal", 1, true) and top(part) > height then
								highest, height = part, top(part)
							end
						end
					end
					if highest then
						protected[highest] = "training sign height guide"
					end
				end
			end
		end
	end
	local layout = game.ServerStorage:FindFirstChild("WorldLayoutState")
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	local function remember(target: Instance?, source: Instance)
		-- A disabled GUI's self-Adornee is not an external dependency.
		if target and target ~= source and not source:IsDescendantOf(target) then
			protected[target] = "referenced by " .. source:GetFullName()
		end
	end
	for i, node in game:GetDescendants() do
		local value: any = node
		if node:IsA("ObjectValue") then
			-- Layout provenance is bookkeeping; stale entries are pruned on delete.
			if not (layout and node:IsDescendantOf(layout)) and not (backups and node:IsDescendantOf(backups)) then
				remember(value.Value, node)
			end
		elseif node:IsA("Model") then
			remember(value.PrimaryPart, node)
		elseif node:IsA("JointInstance") or node:IsA("WeldConstraint") then
			remember(value.Part0, node)
			remember(value.Part1, node)
		elseif node:IsA("Beam") or node:IsA("Trail") or node:IsA("Constraint") then
			remember(value.Attachment0, node)
			remember(value.Attachment1, node)
		elseif
			node:IsA("BillboardGui")
			or node:IsA("SurfaceGui")
			or node:IsA("Highlight")
			or node:IsA("PVAdornment")
		then
			remember(value.Adornee, node)
		elseif node:IsA("Camera") then
			remember(value.CameraSubject, node)
		end
		if i % 2500 == 0 then
			task.wait()
		end
	end
	return protected
end

local function reason(part: BasePart, protected: { [Instance]: string }): string?
	if part.Transparency ~= 1 or part.CanCollide or part.CanTouch or part.CanQuery or not part.Anchored then
		return nil
	end
	if protected[part] or #part:GetTags() > 0 or part:GetAttribute("AnimatedPortal") == true then
		return nil
	end
	local disabledGui = false
	for _, child in part:GetDescendants() do
		if #child:GetTags() > 0 then
			return nil
		elseif child:IsA("BillboardGui") or child:IsA("SurfaceGui") then
			if child.Enabled then
				return nil
			end
			disabledGui = true
		elseif child:IsA("GuiObject") or child:IsA("UIComponent") then
			continue
		elseif child:IsA("Decal") then
			if child.Transparency < 1 then
				return nil
			end
		elseif child:IsA("ProximityPrompt") and not child.Enabled and part.Name:match("^DisplayStone_") then
			continue -- Retired ball placeholders are never installed as live prompts.
		elseif child:IsA("DataModelMesh") then
			continue
		elseif child:IsA("ObjectValue") and child.Name == "OriginalPart" then
			continue
		else
			-- Includes prompts, scripts, lights, attachments, particles and joints.
			return nil
		end
	end
	if part.Name:match("^DisplayStone_") then
		return "retired ball-stand placeholder"
	elseif disabledGui then
		return "disabled legacy caption"
	elseif
		part.Parent
		and part.Parent.Name == "ImportedField"
		and part:GetAttribute("BeforeBiomeTransparency") ~= nil
	then
		return "replaced imported training decoration"
	elseif
		part:GetAttribute("BeforeCompactLobbyTransparency") ~= nil
		or part:GetAttribute("BeforeGeometryPolish") ~= nil
	then
		return "replaced paving or arrows"
	elseif part:GetAttribute("SurfaceSource") ~= nil then
		return "retired surface overlay"
	elseif part:GetAttribute("JapaneseBannerHidden") or part:GetAttribute("PolarCrystalHidden") then
		return "replaced biome decoration"
	elseif part.Name == "EggSpot" then
		return "spots on replaced egg shell"
	elseif part.Name == "GrassWallCrown" then
		return "replaced wall crown"
	elseif part.Name == "PortalTop" or (part.Name == "EnergyBeam" and part:GetAttribute("AnimatedPortal") == false) then
		return "replaced portal decoration"
	elseif part.Name == "MainPlazaPath" then
		return "retired lobby paving sentinel"
	end
	return nil
end

function Cleanup.plan(map: Instance): any
	local protected = protectInputs(map)
	local parts, reasons, paths = {}, {}, {}
	local transparent, physical, mapCandidates, sourceCandidates = 0, 0, 0, 0
	local roots: { Instance } = { map }
	local state = game.ServerStorage:FindFirstChild("WorldLayoutState")
	if state then
		for _, world in state:GetChildren() do
			local retired = world:FindFirstChild("RetiredVisuals")
			-- Retired-world state is a historical archive, outside active-map cleanup.
			if retired and map:FindFirstChild(world.Name) then
				table.insert(roots, retired)
			end
		end
	end
	for _, root in roots do
		for i, node in root:GetDescendants() do
			if node:IsA("BasePart") and node.Transparency == 1 then
				if root == map then
					transparent += 1
					if node.CanCollide or node.CanTouch or node.CanQuery then
						physical += 1
					end
				end
				local why = reason(node, protected)
				if why then
					if root == map then
						mapCandidates += 1
					else
						sourceCandidates += 1
					end
					table.insert(parts, node)
					table.insert(paths, node:GetFullName())
					reasons[why] = (reasons[why] or 0) + 1
				end
			end
			if i % 2000 == 0 then
				task.wait()
			end
		end
	end
	return {
		parts = parts,
		protected = protected,
		report = {
			transparentBefore = transparent,
			keptPhysicalParts = physical,
			candidateParts = #parts,
			mapCandidates = mapCandidates,
			sourceCandidates = sourceCandidates,
			reasons = reasons,
			paths = paths,
		},
	}
end

function Cleanup.apply(map: Instance): any
	assert(map == workspace:FindFirstChild("Map"), "Cleanup is restricted to the live Map")
	for _, world in map:GetChildren() do
		assert(world:GetAttribute("WorldLayoutReady") == true, "Finish layout before cleaning transparent parts")
	end
	local plan = Cleanup.plan(map)
	local dead: { [Instance]: boolean } = {}
	local removedDescendants = 0
	for i, part in plan.parts do
		assert(reason(part, plan.protected), "Cleanup candidate changed during audit")
		local ancestor = part.Parent
		while ancestor and ancestor ~= map do
			if ancestor:IsA("Model") then
				ancestor.WorldPivot = ancestor:GetPivot()
			end
			ancestor = ancestor.Parent
		end
		local world: any = part
		if part:IsDescendantOf(map) then
			while world.Parent ~= map do
				world = world.Parent
			end
		else
			local retired = part:FindFirstAncestor("RetiredVisuals")
			world = retired and retired.Parent and map:FindFirstChild(retired.Parent.Name)
		end
		if part.Name == "MainPlazaPath" and world then
			world:SetAttribute("RetiredLobbyPaving", true)
		end
		removedDescendants += #part:GetDescendants()
		dead[part] = true
		part:Destroy()
		if i % 200 == 0 then
			task.wait()
		end
	end
	local state = game.ServerStorage:FindFirstChild("WorldLayoutState")
	if state then
		for _, world in state:GetChildren() do
			local moves = world:FindFirstChild("Moves")
			if moves and map:FindFirstChild(world.Name) then
				for _, reference in moves:GetChildren() do
					if reference:IsA("ObjectValue") and (reference.Value == nil or dead[reference.Value]) then
						reference:Destroy()
					end
				end
			end
		end
	end
	local report = plan.report
	report.removedParts = #plan.parts
	report.removedDescendants = removedDescendants
	report.transparentAfter = report.transparentBefore - report.mapCandidates
	for _, world in map:GetChildren() do
		world:SetAttribute("TransparentCleanupVersion", 1)
	end
	return report
end

return Cleanup
