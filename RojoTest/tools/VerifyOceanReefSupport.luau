-- Read-only Studio check. Run after applying the Ocean Depths lobby and reef.
local Server = game:GetService("ServerScriptService").Server
local Ground = require(Server.OceanReefGround)
local w = workspace.Map.World2
local reef = w.FootballCourse.Zones.Zone01.Environment.CoralGardens
local lobby = w.Lobby
local reefGround = Ground.collect(
	w.FootballCourse.Zones.Zone01,
	{ LawnTop = true, SandShoulder = true, SandShelf = true, Seabed = true }
)
local lobbyGround = Ground.collect(lobby, { CapSurface = true, LawnCell = true })
local stone = {}
for _, p in reef:GetDescendants() do
	if p:IsA("BasePart") and p.Name == "BlueLimestone" then
		table.insert(stone, p)
	end
end
local rockFailures = {}
local function overlaps(a, b)
	local delta = a.Position - b.Position
	local size = (a.Size + b.Size) / 2
	return math.abs(delta.X) < size.X - 0.035
		and math.abs(delta.Y) < size.Y - 0.035
		and math.abs(delta.Z) < size.Z - 0.035
end
for i, p in stone do
	local bottom = p.Position.Y - p.Size.Y / 2
	local support = table.clone(reefGround)
	for j, q in stone do
		if q.Position.Y + q.Size.Y / 2 <= bottom + 0.035 then
			Ground.add(support, q)
		end
		if j > i and overlaps(p, q) then
			table.insert(rockFailures, "overlap " .. tostring(p.Position) .. " and " .. tostring(q.Position))
		end
	end
	local ok, msg =
		pcall(Ground.fit, support, p.CFrame * CFrame.new(0, -p.Size.Y / 2, 0), Vector2.new(p.Size.X, p.Size.Z), 0.04)
	if not ok then
		table.insert(rockFailures, tostring(msg))
	end
end
for _, p in stone do
	Ground.add(reefGround, p)
end
local plantFailures = {}
local count = 0
for _, entry in { { reef, reefGround }, { lobby.Environment.CoralGardens, lobbyGround } } do
	for _, m in entry[1]:GetDescendants() do
		local fp = m:GetAttribute("SupportFootprint")
		if m:IsA("Model") and fp then
			count += 1
			local ok, msg = pcall(Ground.fit, entry[2], m:GetPivot(), fp, 0.04)
			if not ok then
				table.insert(plantFailures, m.Name .. " " .. tostring(msg))
			end
		end
	end
end
assert(#plantFailures == 0, table.concat(plantFailures, "\n"))
assert(#rockFailures == 0, table.concat(rockFailures, "\n"))
return string.format("Full support: %d plant bases and %d rock tiers", count, #stone)
