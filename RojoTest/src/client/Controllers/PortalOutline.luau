--!strict
local Outline = {}

function Outline.new(): (BasePart?, boolean) -> ()
	local group = Instance.new("Folder")
	group.Name = "WorldPortalBoundary"
	local current: BasePart?
	local edges: { { start: Vector3, direction: Vector3, length: number, spacing: number, parts: { Part } } } = {}
	local lastFrame = 0
	return function(zone: BasePart?, animate: boolean)
		if current ~= zone then
			current = zone
			group:ClearAllChildren()
			table.clear(edges)
			group.Parent = if zone then workspace else nil
			lastFrame = 0
			if zone then
				local x, z = zone.Size.X / 2, zone.Size.Z / 2
				local points = {
					Vector3.new(-x, 0, -z),
					Vector3.new(x, 0, -z),
					Vector3.new(x, 0, z),
					Vector3.new(-x, 0, z),
				}
				for side, start in points do
					local vector = points[side % 4 + 1] - start
					local count = math.round(vector.Magnitude / 1.35)
					local parts: { Part } = {}
					for _ = 0, count do
						local dash = Instance.new("Part")
						dash.Name = "Dash"
						dash.Anchored, dash.CastShadow = true, false
						dash.CanCollide, dash.CanTouch, dash.CanQuery = false, false, false
						dash.Color = Color3.fromRGB(255, 251, 231)
						dash.Material = Enum.Material.Neon
						dash.Transparency = 1
						dash.Parent = group
						table.insert(parts, dash)
					end
					table.insert(edges, {
						start = start,
						direction = vector.Unit,
						length = vector.Magnitude,
						spacing = vector.Magnitude / count,
						parts = parts,
					})
				end
			end
		end
		local now = os.clock()
		if not zone or now - lastFrame < 1 / 30 then
			return
		end
		lastFrame = now
		local phase = if animate then (now * 1.7) % 1 else 0.3
		for _, edge in edges do
			for index, part in edge.parts do
				local center = (index - 2 + phase) * edge.spacing
				local left = math.max(0, center - edge.spacing * 0.32)
				local right = math.min(edge.length, center + edge.spacing * 0.32)
				if right - left > 0.015 then
					local localPoint = edge.start + edge.direction * ((left + right) / 2)
					part.Size = Vector3.new(0.18, 0.045, right - left)
					part.CFrame = zone.CFrame * CFrame.lookAt(localPoint, localPoint + edge.direction)
					part.Transparency = 0.05
				else
					part.Transparency = 1
				end
			end
		end
	end
end

return Outline
