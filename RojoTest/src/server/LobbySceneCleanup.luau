--!strict
-- Narrow final-scene repair. Never rebuilds the authored lobby or changes physics.
local Cleanup = {}
type Flower = { parts: { BasePart }, stem: BasePart, head: BasePart, model: Model? }
type Move = { flower: Flower, delta: Vector3 }
local TURF = {
	GrassShelf = true,
	RearGrassLedge = true,
	GroundTile = true,
	LeftAbutmentGrassCap = true,
	RightAbutmentGrassCap = true,
}
local SOLID = {
	LayeredShrub = true,
	RockMass = true,
	StoneMass = true,
	SmallStone = true,
	StoneShoulder = true,
	Trunk = true,
	Crown = true,
	Canopy = true,
	TreeCrown = true,
	LanternFrame = true,
}
local HEAD = { Pollen = true, FlowerCenter = true, SummitPollen = true }
local STEM = { Stem = true, FlowerStem = true, SummitStem = true }
local PETAL = { Petals = true, FlowerPetals = true, SummitPetals = true }

local function extent(p: BasePart): Vector3
	local cf, h = p.CFrame, p.Size / 2
	return Vector3.new(
		math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
		math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
		math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
	)
end

local function inside(head: BasePart, block: BasePart): boolean
	-- Conservative for wedge rocks: blooms stay clear of the complete silhouette.
	local distance, h = head.Position - block.Position, extent(head) + extent(block)
	return math.abs(distance.X) < h.X - 0.04 and math.abs(distance.Y) < h.Y - 0.04 and math.abs(distance.Z) < h.Z - 0.04
end

local function flowers(environment: Instance): { Flower }
	local result: { Flower } = {}
	for _, head in environment:GetDescendants() do
		if not head:IsA("BasePart") or head.Transparency == 1 or not HEAD[head.Name] then
			continue
		end
		local parent = head.Parent :: Instance
		local stem: BasePart? = nil
		local members = { head }
		for _, p in parent:GetChildren() do
			if p:IsA("BasePart") and p.Transparency < 1 then
				local delta = p.Position - head.Position
				if Vector2.new(delta.X, delta.Z).Magnitude < 0.03 then
					if
						STEM[p.Name]
						and delta.Y < 0
						and delta.Y > -3
						and (not stem or p.Position.Y > stem.Position.Y)
					then
						stem = p
					elseif PETAL[p.Name] and math.abs(delta.Y) < 0.5 then
						table.insert(members, p)
					end
				end
			end
		end
		if stem then
			local model = if parent:IsA("Model") and parent.Name == "SmallFlower" then parent else nil
			if model then
				members = {}
				for _, p in model:GetDescendants() do
					if p:IsA("BasePart") then
						table.insert(members, p)
					end
				end
			else
				table.insert(members, stem)
			end
			table.insert(result, { parts = members, stem = stem, head = head, model = model })
		end
	end
	return result
end

local function repairBlooms(environment: Instance, apply: boolean): number
	local count = 0
	for _, flower in flowers(environment) do
		local head, stem = flower.head, flower.stem
		if
			head.Name ~= "FlowerCenter"
			or math.abs(head.Size.Y - 0.12) > 0.005
			or math.abs(stem.Size.Y - 1.04) > 0.005
		then
			continue
		end
		local scale = stem.Size.Y / 1.3
		local petal: BasePart? = nil
		for _, part in flower.parts do
			if part.Name == "FlowerPetals" then
				petal = part
				break
			end
		end
		local petalSize = Vector3.new(0.95, 0.3, 0.95) * scale
		local petalFrame = stem.CFrame * CFrame.new(0, 0.75 * scale, 0)
		local headSize = Vector3.new(0.32, 0.15, 0.32) * scale
		local headFrame = stem.CFrame * CFrame.new(0, 0.97 * scale, 0)
		if
			petal
			and (petal.Size - petalSize).Magnitude < 0.001
			and (petal.Position - petalFrame.Position).Magnitude < 0.001
			and (head.Size - headSize).Magnitude < 0.001
			and (head.Position - headFrame.Position).Magnitude < 0.001
		then
			continue
		end
		count += 1
		if apply then
			if not petal then
				local p = Instance.new("Part")
				p.Name, p.Color, p.Material = "FlowerPetals", Color3.fromRGB(244, 251, 228), Enum.Material.Plastic
				p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
				p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
				p.Parent = head.Parent
				petal = p
			end
			local complete = assert(petal)
			assert(
				not complete.CanCollide and not complete.CanTouch and not complete.CanQuery,
				"Petal must be cosmetic"
			)
			complete.Size, complete.CFrame = petalSize, petalFrame
			head.Size, head.CFrame = headSize, headFrame
		end
	end
	return count
end

function Cleanup.plan(world: Instance): any
	local lobby = world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	if not lobby or not environment then
		return { moves = {}, props = {}, remove = {}, unresolved = 0, blooms = 0, floating = 0, buried = 0 }
	end
	local surfaces: { BasePart } = {}
	local supports: { BasePart } = {}
	local blockers: { BasePart } = {}
	local extents: { [BasePart]: Vector3 } = {}
	for _, p in lobby:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			if TURF[p.Name] then
				table.insert(surfaces, p)
			end
			if
				not STEM[p.Name]
				and not HEAD[p.Name]
				and not PETAL[p.Name]
				and not SOLID[p.Name]
				and p.Name ~= "Leaf"
			then
				if math.abs(p.CFrame.UpVector.Y) > 0.999 then
					table.insert(supports, p)
				end
			end
			if SOLID[p.Name] then
				table.insert(blockers, p)
				extents[p] = extent(p)
			end
		end
	end
	local all = flowers(environment)
	local moves: { Move } = {}
	local occupied: { Vector3 } = {}
	local repair: { Flower } = {}
	local floating, buried, unresolved = 0, 0, 0
	for i, flower in all do
		local foot = flower.stem.Position - Vector3.new(0, extent(flower.stem).Y, 0)
		local grounded = false
		for _, p in supports do
			local q = p.CFrame:PointToObjectSpace(foot)
			if
				math.abs(q.X) < p.Size.X / 2 + 0.02
				and math.abs(q.Z) < p.Size.Z / 2 + 0.02
				and math.abs(q.Y - p.Size.Y / 2) < 0.14
			then
				grounded = true
				break
			end
		end
		local hidden = false
		for _, bloom in flower.parts do
			if bloom == flower.head or PETAL[bloom.Name] then
				for _, p in blockers do
					if inside(bloom, p) then
						hidden = true
						break
					end
				end
			end
			if hidden then
				break
			end
		end
		if not grounded or hidden then
			table.insert(repair, flower)
			floating += if grounded then 0 else 1
			buried += if hidden then 1 else 0
		else
			table.insert(occupied, foot)
		end
		if i % 100 == 0 then
			task.wait()
		end
	end
	-- Stable ordering makes another normal startup choose the same planting positions.
	table.sort(repair, function(a, b)
		local p, q = a.head.Position, b.head.Position
		return if p.Y ~= q.Y then p.Y < q.Y elseif p.X ~= q.X then p.X < q.X else p.Z < q.Z
	end)
	local offsets = { 0 }
	for n = 1, 12 do
		table.insert(offsets, n)
		table.insert(offsets, -n)
	end
	for i, flower in repair do
		local foot = flower.stem.Position - Vector3.new(0, extent(flower.stem).Y, 0)
		local lo, hi = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, p in flower.parts do
			local h = extent(p)
			lo, hi = lo:Min(p.Position - h - foot), hi:Max(p.Position + h - foot)
			assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Flower must be cosmetic")
		end
		local best: Vector3? = nil
		local score = math.huge
		for _, surface in surfaces do
			local height = surface.Position.Y + surface.Size.Y / 2
			if math.abs(height - foot.Y) > 3 then
				continue
			end
			local q = surface.CFrame:PointToObjectSpace(foot)
			local half = surface.Size / 2
			local x = math.clamp(q.X, -half.X + 1.1, half.X - 1.1)
			local z = math.clamp(q.Z, -half.Z + 1.1, half.Z - 1.1)
			for _, dx in offsets do
				for _, dz in offsets do
					local cx, cz = x + dx * 1.6, z + dz * 1.6
					if math.abs(cx) > half.X - 1.05 or math.abs(cz) > half.Z - 1.05 then
						continue
					end
					local candidate = surface.CFrame:PointToWorldSpace(Vector3.new(cx, half.Y, cz))
					local distance = (candidate - foot).Magnitude
					if distance >= score then
						continue
					end
					local clear = true
					local center = candidate + (lo + hi) / 2
					local radius = (hi - lo) / 2 + Vector3.new(0.2, 0, 0.2)
					for _, p in blockers do
						local b, h = center - p.Position, extents[p]
						if
							math.abs(b.X) < radius.X + h.X
							and math.abs(b.Y) < radius.Y + h.Y
							and math.abs(b.Z) < radius.Z + h.Z
						then
							clear = false
							break
						end
					end
					if clear then
						for _, other in occupied do
							if (other - candidate).Magnitude < 1.35 then
								clear = false
								break
							end
						end
					end
					if clear then
						best, score = candidate, distance
					end
				end
			end
		end
		if best then
			table.insert(moves, { flower = flower, delta = best - foot })
			table.insert(occupied, best)
		else
			unresolved += 1
		end
		if i % 5 == 0 then
			task.wait()
		end
	end
	local remove: { BasePart } = {}
	local tunnel = environment:FindFirstChild("EntranceTunnel")
	local outpost = tunnel and tunnel:FindFirstChild("ExplorerOutpost")
	local props = {}
	if outpost then
		local chest: { BasePart } = {}
		local posts: { BasePart } = {}
		local low, high = Vector3.one * math.huge, -Vector3.one * math.huge
		for _, p in outpost:GetChildren() do
			if p:IsA("BasePart") then
				if p.Name == "SupplyChest" or p.Name:match("^Chest") then
					table.insert(chest, p)
					local h = extent(p)
					low, high = low:Min(p.Position - h), high:Max(p.Position + h)
				elseif p.Name == "MapPost" then
					table.insert(posts, p)
				end
			end
		end
		local shift = 0
		for _, post in posts do
			local h = extent(post)
			if
				low.X < post.Position.X + h.X
				and high.X > post.Position.X - h.X
				and low.Y < post.Position.Y + h.Y
				and high.Y > post.Position.Y - h.Y
				and low.Z < post.Position.Z + h.Z
				and high.Z > post.Position.Z - h.Z
			then
				shift = math.max(shift, post.Position.Z + h.Z + 0.35 - low.Z)
			end
		end
		if shift > 0 then
			for _, part in chest do
				assert(
					part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery,
					"Chest must be cosmetic"
				)
				table.insert(props, { part = part, delta = Vector3.new(0, 0, shift) })
			end
		end
	end
	if tunnel then
		for _, p in tunnel:GetChildren() do
			if p:IsA("BasePart") and p.Name == "Petals" and p.Transparency < 1 then
				local hasFlower = false
				for _, other in tunnel:GetChildren() do
					if
						other:IsA("BasePart")
						and (STEM[other.Name] or HEAD[other.Name])
						and (other.Position - p.Position).Magnitude < 2
					then
						hasFlower = true
						break
					end
				end
				if not hasFlower then
					assert(
						p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery,
						"Petal must be cosmetic"
					)
					table.insert(remove, p)
				end
			end
		end
	end
	if outpost then
		for _, p in outpost:GetDescendants() do
			if p:IsA("BasePart") and p.Name:match("^Chime") then
				assert(p.Anchored and not p.CanCollide and not p.CanTouch and not p.CanQuery, "Chime must be cosmetic")
				table.insert(remove, p)
			end
		end
	end
	return {
		moves = moves,
		props = props,
		remove = remove,
		floating = floating,
		buried = buried,
		unresolved = unresolved,
		blooms = repairBlooms(environment, false),
	}
end

function Cleanup.apply(world: Instance): any
	local lobby = world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	local blooms = if environment then repairBlooms(environment, true) else 0
	local plan = Cleanup.plan(world)
	assert(plan.unresolved == 0, "No clear planting position; lobby left unchanged")
	for _, move in plan.moves do
		for _, p in move.flower.parts do
			if p:GetAttribute("BeforeLobbyGrounding") == nil then
				p:SetAttribute("BeforeLobbyGrounding", p.CFrame)
			end
			p.CFrame += move.delta
		end
	end
	for _, move in plan.props do
		local p = move.part
		if p:GetAttribute("BeforeLobbyGrounding") == nil then
			p:SetAttribute("BeforeLobbyGrounding", p.CFrame)
		end
		p.CFrame += move.delta
	end
	-- Chimes belonged to the removed arch. Delete the obsolete render and source
	-- together, removing provenance entries that could otherwise resurrect them.
	local deleted: { [Instance]: boolean } = {}
	local ids: { [number]: boolean } = {}
	for _, p in plan.remove do
		deleted[p] = true
		local original = p:FindFirstChild("OriginalPart")
		if original and original:IsA("ObjectValue") and original.Value then
			deleted[original.Value] = true
		end
	end
	for p in deleted do
		local id = p:GetAttribute("SurfaceSeparationId")
		if typeof(id) == "number" then
			ids[id] = true
		end
	end
	local state = game.ServerStorage:FindFirstChild("WorldLayoutState")
	local journal = state and state:FindFirstChild(world.Name)
	local refs = journal and journal:FindFirstChild("Moves")
	if refs then
		for _, ref in refs:GetChildren() do
			if ref:IsA("ObjectValue") and ref.Value and deleted[ref.Value] then
				ref:Destroy()
			end
		end
	end
	local sources = journal and journal:FindFirstChild("Sources")
	local separation = world:FindFirstChild("SurfaceSeparation")
		or (sources and sources:FindFirstChild("SurfaceSeparation"))
	if separation then
		local previous = separation:GetAttribute("RetiredRecordIds")
		for id in tostring(previous or ""):gmatch("%d+") do
			ids[tonumber(id) :: number] = true
		end
		local list = {}
		for id in ids do
			table.insert(list, id)
		end
		table.sort(list)
		separation:SetAttribute("RetiredRecordIds", table.concat(list, ","))
	end
	local removed = 0
	for p in deleted do
		p:Destroy()
		removed += 1
	end
	world:SetAttribute("LobbySceneCleanupVersion", 1)
	return {
		replanted = #plan.moves,
		floating = plan.floating,
		buried = plan.buried,
		removed = removed,
		chestParts = #plan.props,
		restoredBlooms = blooms,
	}
end

return Cleanup
