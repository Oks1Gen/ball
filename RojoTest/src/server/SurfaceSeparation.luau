--!strict
-- Apply measured cosmetic corrections only; never move gameplay/collision volumes.
local Repair = {}
local HttpService = game:GetService("HttpService")
local records: any = HttpService:JSONDecode(require(script.Parent.SurfaceSeparationData))

function Repair.apply(map: any)
	local folder = map:FindFirstChild("SurfaceSeparation")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name, folder.Parent = "SurfaceSeparation", map
	end
	local changed, missing = 0, 0
	for index, record in records do
		if record[1][1] ~= map.Name then
			continue
		end
		local parents: { Instance } = { map }
		for i = 2, #record[1] do
			local matches = {}
			for _, parent in parents do
				for _, child in parent:GetChildren() do
					if child.Name == record[1][i] then
						table.insert(matches, child)
					end
				end
			end
			parents = matches
		end
		local target: BasePart? = nil
		local already = false
		for _, parent in parents do
			for _, child in parent:GetChildren() do
				if child.Name == record[2] and child:IsA("BasePart") then
					if child:GetAttribute("SurfaceSeparationId") == index then
						already = true
						break
					end
					if
						not child:GetAttribute("SurfaceSeparationId")
						and (child.Position - Vector3.new(unpack(record[3]))).Magnitude < 0.005
						and (child.Size - Vector3.new(unpack(record[4]))).Magnitude < 0.005
					then
						target = child
					end
				end
			end
		end
		if already then
			continue
		end
		if not target then
			missing += 1
			continue
		end
		local render = target:Clone()
		for _, tag in render:GetTags() do
			render:RemoveTag(tag)
		end
		for _, child in render:GetChildren() do
			if not (child:IsA("Decal") or child:IsA("DataModelMesh") or child:IsA("SurfaceAppearance")) then
				child:Destroy()
			end
		end
		render.Size = Vector3.new(unpack(record[5]))
		render.CFrame = target.CFrame * CFrame.new(Vector3.new(unpack(record[6])))
		render.CanCollide, render.CanTouch, render.CanQuery = false, false, false
		render:SetAttribute("SurfaceSeparationId", index)
		local source = Instance.new("ObjectValue")
		source.Name, source.Value, source.Parent = "OriginalPart", target, render
		render.Parent = folder
		target:SetAttribute("SurfaceSeparationId", index)
		target:SetAttribute("SurfaceSeparationTransparency", target.Transparency)
		target.Transparency = 1
		for _, child in target:GetChildren() do
			if child:IsA("Decal") then
				child:SetAttribute("SurfaceSeparationTransparency", child.Transparency)
				child.Transparency = 1
			end
		end
		changed += 1
		if changed % 100 == 0 then
			task.wait()
		end
	end
	if missing > 0 then
		warn("[SurfaceSeparation] " .. map.Name .. ": " .. missing .. " authored parts changed; skipped safely")
	end
	return { changed = changed, missing = missing }
end

return Repair
