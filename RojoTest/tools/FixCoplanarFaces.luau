-- Edit migration: separate coplanar visible faces in Workspace.Map (2026-11-01). Run in Edit,
-- then save the place. Re-runnable: each pass repeats the CheckSurfaceOverlaps geometry audit and
-- stops when no visible pair is left.
-- A pair is "visible" unless both parts share colour, transparency and a plain material without
-- textures, decals or a MaterialVariant (such a pair cannot flicker). For each visible pair one
-- part moves: never a collidable one, otherwise the part with the smaller face. The moving face
-- is put SEPARATION studs in front of the other face, so decor stays drawn on top of its base.
-- Only that face grows, so the opposite face stays put; a wedge's slope, bottom and back faces
-- (which would change its slope) translate the whole wedge instead.
-- Changed parts keep their first CFrame/Size in BeforeFaceSeparationCFrame/BeforeFaceSeparationSize.
-- Studio Edit only: this script mutates the scene.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio(), "This script must run in Studio, not on a live server")
assert(not RunService:IsRunning(), "This script must run in Edit mode, not during Play")
local TOLERANCE = 0.035
local SEPARATION = 0.06
local MAX_PASSES = 8
local root = workspace.Map
local axes = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
local PLAIN = {
	[Enum.Material.Plastic] = true,
	[Enum.Material.SmoothPlastic] = true,
	[Enum.Material.Neon] = true,
	[Enum.Material.Glass] = true,
	[Enum.Material.ForceField] = true,
}

local function clean(x)
	return if math.abs(x) < 0.0001 then 0 else x
end

-- Same geometry as tools/CheckSurfaceOverlaps.luau; returns the face records of every close pair.
local function audit()
	local bins = {}
	local solid = {}
	for _, p in root:GetDescendants() do
		if ((p:IsA("Part") and p.Shape == Enum.PartType.Block) or p:IsA("WedgePart")) and p.Transparency < 1 then
			if p:IsA("Part") then
				table.insert(solid, p)
			end
			local sizes = { p.Size.X, p.Size.Y, p.Size.Z }
			for a = 1, 3 do
				for _, sign in { -1, 1 } do
					if p:IsA("WedgePart") and ((a == 2 and sign == 1) or (a == 3 and sign == -1)) then
						continue
					end
					local n = p.CFrame:VectorToWorldSpace(axes[a]) * sign
					local key = string.format("%.4f,%.4f,%.4f", clean(n.X), clean(n.Y), clean(n.Z))
					bins[key] = bins[key] or {}
					table.insert(bins[key], {
						p = p,
						n = n,
						c = p.Position + n * sizes[a] / 2,
						u = p.CFrame:VectorToWorldSpace(axes[a % 3 + 1]),
						v = p.CFrame:VectorToWorldSpace(axes[(a + 1) % 3 + 1]),
						h = sizes[a % 3 + 1] / 2,
						k = sizes[(a + 1) % 3 + 1] / 2,
						a = a,
						sign = sign,
					})
				end
			end
			if p:IsA("WedgePart") then
				local n = p.CFrame:VectorToWorldSpace(Vector3.new(0, p.Size.Z, -p.Size.Y).Unit)
				local key = string.format("%.4f,%.4f,%.4f", clean(n.X), clean(n.Y), clean(n.Z))
				bins[key] = bins[key] or {}
				table.insert(bins[key], {
					p = p,
					n = n,
					c = p.Position,
					u = p.CFrame.RightVector,
					v = p.CFrame:VectorToWorldSpace(Vector3.new(0, p.Size.Y, p.Size.Z).Unit),
					h = p.Size.X / 2,
					k = math.sqrt(p.Size.Y ^ 2 + p.Size.Z ^ 2) / 2,
					a = 4,
					sign = 1,
				})
			end
		end
	end
	local grid, large = {}, {}
	local function cell(p)
		return math.floor(p.X / 32) .. "," .. math.floor(p.Y / 32) .. "," .. math.floor(p.Z / 32)
	end
	for _, p in solid do
		local h = p.Size / 2
		local cf = p.CFrame
		local e = Vector3.new(
			math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z,
			math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z,
			math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
		)
		local lo, hi = p.Position - e, p.Position + e
		if (hi.X - lo.X) * (hi.Y - lo.Y) * (hi.Z - lo.Z) > 10000000 then
			table.insert(large, p)
		else
			for x = math.floor(lo.X / 32), math.floor(hi.X / 32) do
				for y = math.floor(lo.Y / 32), math.floor(hi.Y / 32) do
					for z = math.floor(lo.Z / 32), math.floor(hi.Z / 32) do
						local k = x .. "," .. y .. "," .. z
						grid[k] = grid[k] or {}
						table.insert(grid[k], p)
					end
				end
			end
		end
	end
	local function overlap(f, g)
		for _, axis in { f.u, f.v, g.u, g.v } do
			local r = f.h * math.abs(f.u:Dot(axis))
				+ f.k * math.abs(f.v:Dot(axis))
				+ g.h * math.abs(g.u:Dot(axis))
				+ g.k * math.abs(g.v:Dot(axis))
			if r - math.abs((g.c - f.c):Dot(axis)) < 0.015 then
				return false
			end
		end
		return true
	end
	local function exposed(f, g)
		local poly = { { -f.h, -f.k }, { f.h, -f.k }, { f.h, f.k }, { -f.h, f.k } }
		local delta = g.c - f.c
		for _, plane in { { g.u, g.h }, { -g.u, g.h }, { g.v, g.k }, { -g.v, g.k } } do
			local axis, limit = plane[1], plane[2]
			local function distance(q)
				return q[1] * f.u:Dot(axis) + q[2] * f.v:Dot(axis) - delta:Dot(axis) - limit
			end
			local nextPoly = {}
			for i, q in poly do
				local r = poly[i % #poly + 1]
				local dq, dr = distance(q), distance(r)
				if dq <= 0 then
					table.insert(nextPoly, q)
				end
				if (dq < 0) ~= (dr < 0) then
					local t = dq / (dq - dr)
					table.insert(nextPoly, { q[1] + (r[1] - q[1]) * t, q[2] + (r[2] - q[2]) * t })
				end
			end
			poly = nextPoly
			if #poly < 3 then
				return false
			end
		end
		local x, y = 0, 0
		for _, q in poly do
			x += q[1] / #poly
			y += q[2] / #poly
		end
		local samples = { { x, y } }
		for _, q in poly do
			table.insert(samples, { x + (q[1] - x) * 0.9, y + (q[2] - y) * 0.9 })
		end
		for _, q in samples do
			local point = f.c + f.u * q[1] + f.v * q[2] + f.n * 0.025
			local hidden = false
			local candidates = table.clone(grid[cell(point)] or {})
			for _, p in large do
				table.insert(candidates, p)
			end
			for _, p in candidates do
				if p ~= f.p and p ~= g.p and p.Transparency < 0.5 then
					local t = p.CFrame:PointToObjectSpace(point)
					local s = p.Size / 2
					if math.abs(t.X) < s.X - 0.001 and math.abs(t.Y) < s.Y - 0.001 and math.abs(t.Z) < s.Z - 0.001 then
						hidden = true
						break
					end
				end
			end
			if not hidden then
				return true
			end
		end
		return false
	end
	local found = {}
	local binIndex = 0
	for _, faces in bins do
		binIndex += 1
		if binIndex % 100 == 0 then
			task.wait()
		end
		table.sort(faces, function(a, b)
			return a.n:Dot(a.c) < b.n:Dot(b.c)
		end)
		for i = 1, #faces do
			if i % 1000 == 0 then
				task.wait()
			end
			for j = i + 1, #faces do
				local f, g = faces[i], faces[j]
				if g.n:Dot(g.c) - f.n:Dot(f.c) > TOLERANCE then
					break
				end
				if f.p ~= g.p and overlap(f, g) and exposed(f, g) then
					table.insert(found, { f = f, g = g })
				end
			end
		end
	end
	return found
end

local function decorated(p)
	if p.MaterialVariant ~= "" then
		return true
	end
	for _, child in p:GetChildren() do
		if (child:IsA("Texture") or child:IsA("Decal")) and child.Transparency < 1 then
			return true
		end
	end
	return false
end

local function visible(pair)
	local a, b = pair.f.p, pair.g.p
	local function rgb(c)
		return math.round(c.R * 255) .. "," .. math.round(c.G * 255) .. "," .. math.round(c.B * 255)
	end
	return not (
		rgb(a.Color) == rgb(b.Color)
		and a.Material == b.Material
		and PLAIN[a.Material]
		and math.abs(a.Transparency - b.Transparency) < 0.001
		and not decorated(a)
		and not decorated(b)
	)
end

local function remember(p)
	if p:GetAttribute("BeforeFaceSeparationCFrame") == nil then
		p:SetAttribute("BeforeFaceSeparationCFrame", p.CFrame)
		p:SetAttribute("BeforeFaceSeparationSize", p.Size)
	end
end

-- Moves face `face` of its part so that it ends `amount` studs further along its normal.
local function advance(face, amount)
	local p = face.p
	remember(p)
	if (face.a <= 3 and p:IsA("Part")) or face.a == 1 then
		p.Size += axes[face.a] * amount
		p.CFrame += face.n * amount / 2
	else
		p.CFrame += face.n * amount
	end
end

game:GetService("ChangeHistoryService"):SetWaypoint("Before coplanar face separation")
local report = {}
local moved, skipped = 0, 0
for pass = 1, MAX_PASSES do
	local visiblePairs = {}
	for _, pair in audit() do
		if visible(pair) then
			table.insert(visiblePairs, pair)
		end
	end
	table.insert(report, "pass " .. pass .. ": " .. #visiblePairs .. " visible pairs")
	if #visiblePairs == 0 then
		break
	end
	local touched = {}
	for _, pair in visiblePairs do
		local f, g = pair.f, pair.g
		if f.p.CanCollide and g.p.CanCollide then
			skipped += 1
			continue
		end
		-- The collidable part never moves; between two decor parts the smaller face moves.
		local fMoves = g.p.CanCollide or (not f.p.CanCollide and f.h * f.k <= g.h * g.k)
		local mover, other = if fMoves then f else g, if fMoves then g else f
		-- One edit per part per pass: the next audit sees the new geometry.
		if touched[mover.p] then
			continue
		end
		touched[mover.p] = true
		local gap = other.n:Dot(other.c) - mover.n:Dot(mover.c)
		advance(mover, gap + SEPARATION)
		moved += 1
	end
end
game:GetService("ChangeHistoryService"):SetWaypoint("After coplanar face separation")
table.insert(report, "edits " .. moved .. ", skipped (both collide) " .. skipped)
print(table.concat(report, "\n"))
return table.concat(report, "\n")
