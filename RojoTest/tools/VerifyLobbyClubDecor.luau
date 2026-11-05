-- Read-only Edit/Server audit of the lobby club dressing (docs/lobby-club-decor.md).
local world = workspace.Map.World1
local lobby = world.Lobby
local refs = require(game.ReplicatedStorage.Shared.WorldRefs)
local Palette = require(game.ServerScriptService.Server.LobbyPalette)
local Scale = require(game.ReplicatedStorage.Shared.WorldScale)

local found = 0
for _, child in lobby.Environment:GetChildren() do
	if child.Name == "ClubDecor" then
		found += 1
	end
end
assert(found == 1, "Expected one ClubDecor, found " .. found)
local decor = lobby.Environment.ClubDecor
assert(decor:GetAttribute("ClubDecorVersion") == 2, "Unexpected ClubDecor version")
local EXPECTED = {
	"Scoreboard",
	"Trees",
	"SubsBench",
	"TrophyMonument",
	"WallGreenery",
	"LobbyBalls",
	"FreeChest",
	"PremiumEggStand",
	"WorldPortal",
}
for _, name in EXPECTED do
	assert(decor:FindFirstChild(name), "Missing club decor object: " .. name)
end
-- Removed on request: no garlands, banners or training corner come back.
for _, name in { "Garlands", "Banners", "TrainingCorner" } do
	assert(not decor:FindFirstChild(name), "Removed club decor object is back: " .. name)
end
-- The premium egg floats like the shop eggs: tagged for EggDisplay, with its caption anchor.
local stand = decor.PremiumEggStand
local egg = stand:FindFirstChild("GoldEgg")
assert(egg and egg:HasTag("FloatingDisplayEgg") and egg:GetAttribute("ElementalEggTheme"), "Premium egg must float")
local anchor = stand:FindFirstChild("EggSignAnchor")
assert(anchor and anchor:FindFirstChild("EggSign"), "Premium egg needs its caption")
assert(stand:FindFirstChild("SeatPad"), "Premium egg sits on the shop seat pad")

local pitch = Palette.GroundStudPitch * Scale.factor(world)
local AXES = {
	[Enum.NormalId.Top] = { "X", "Z" },
	[Enum.NormalId.Bottom] = { "X", "Z" },
	[Enum.NormalId.Left] = { "Y", "Z" },
	[Enum.NormalId.Right] = { "Y", "Z" },
	[Enum.NormalId.Front] = { "X", "Y" },
	[Enum.NormalId.Back] = { "X", "Y" },
}
local function obb(p)
	local cf = p.CFrame
	return {
		p = p,
		h = { p.Size.X / 2, p.Size.Y / 2, p.Size.Z / 2 },
		axes = { cf.RightVector, cf.UpVector, cf.LookVector },
	}
end
-- Separating-axis test; a 0.05 contact margin still counts as clear.
local function overlap(a, b)
	local d = b.p.Position - a.p.Position
	local axes = { a.axes[1], a.axes[2], a.axes[3], b.axes[1], b.axes[2], b.axes[3] }
	for _, u in a.axes do
		for _, v in b.axes do
			local n = u:Cross(v)
			if n.Magnitude > 0.001 then
				table.insert(axes, n.Unit)
			end
		end
	end
	for _, axis in axes do
		local radius = 0
		for k = 1, 3 do
			radius += math.abs(a.axes[k]:Dot(axis)) * a.h[k] + math.abs(b.axes[k]:Dot(axis)) * b.h[k]
		end
		if math.abs(d:Dot(axis)) >= radius - 0.05 then
			return false
		end
	end
	return true
end

local stations = {}
local function collect(root)
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			table.insert(stations, obb(p))
		end
	end
end
for _, root in { lobby.BallShop, lobby.EggShop, lobby.KickZone, lobby.Leaderboards } do
	collect(root)
end
for i = 1, 7 do
	collect(refs.training(world)["TrainingLane" .. i])
end

local parts, solid, textures, conflicts = 0, 0, 0, {}
for _, p in decor:GetDescendants() do
	if p:IsA("BasePart") then
		parts += 1
		assert(p.Anchored and not p.CanTouch, "Decor must be anchored without touch: " .. p:GetFullName())
		assert(p.CanCollide == p.CanQuery, "Decor collision and query must match: " .. p:GetFullName())
		assert(
			p.Transparency < 1 or (p:GetAttribute("PartRole") and p:GetAttribute("Purpose")),
			"Invisible decor needs PartRole and Purpose: " .. p:GetFullName()
		)
		if p.CanCollide then
			solid += 1
		end
		local box = obb(p)
		for _, station in stations do
			if overlap(box, station) then
				table.insert(conflicts, p:GetFullName() .. " / " .. station.p:GetFullName())
			end
		end
	elseif p:IsA("Texture") and p.Name == "DecorStuds" then
		textures += 1
		assert(math.abs(p.StudsPerTileU - pitch * Palette.StudsPerTexture) < 0.001, "Wrong stud tile")
		local size = p.Parent.Size
		for _, axis in AXES[p.Face] do
			local n = size[axis] / pitch
			assert(math.abs(n - math.round(n)) < 0.001, "Studs on a partial-stud face: " .. p.Parent:GetFullName())
		end
	end
end
if #conflicts > 0 then
	error("Decor overlaps a station: " .. conflicts[1])
end

-- The removal and terrace passes leave the club dressing alone.
for _, name in { "LobbyDecorRemoval", "LobbyWallDecor" } do
	local source = game.ServerScriptService.Server[name]:Clone()
	source.Parent = game.ServerStorage
	local ok, plan = pcall(function()
		return require(source).plan(world)
	end)
	source:Destroy()
	assert(ok, plan)
	local targets = if name == "LobbyDecorRemoval" then plan.targets else plan
	for _, target in targets do
		assert(not target:IsDescendantOf(decor) and target ~= decor, name .. " would remove club decor")
	end
end
return { parts = parts, solid = solid, studTextures = textures, stationConflicts = 0 }
