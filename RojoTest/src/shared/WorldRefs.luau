--!strict
-- Runtime scene contract. Legacy fallbacks are only for the construction phase
-- and old places; gameplay never depends on a historical generator's folder.
local Refs = {}

function Refs.course(world: any): any
	return world and (world:FindFirstChild("FootballCourse") or world:FindFirstChild("SkippingWorld"))
end

function Refs.field(world: any, index: number): any
	local course = Refs.course(world)
	local zones = course and course:FindFirstChild("Zones")
	local zone = zones and zones:FindFirstChild(string.format("Zone%02d", index))
	return if zones then zone and zone:FindFirstChild("Field") else course and course:FindFirstChild("Field_" .. index)
end

function Refs.boundaries(world: any): any
	local course = Refs.course(world)
	return (course and course:FindFirstChild("Boundaries")) or (world and world:FindFirstChild("ZoneDividers"))
end

function Refs.eggs(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	return (lobby and lobby:FindFirstChild("EggShop")) or (world and world:FindFirstChild("SkippingWorld"))
end

function Refs.volcanic(world: any): any
	local eggs = Refs.eggs(world)
	return eggs and (eggs:FindFirstChild("VolcanicEgg") or eggs)
end

function Refs.balls(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	return (lobby and lobby:FindFirstChild("BallShop")) or (world and world:FindFirstChild("EmptyItemStand"))
end

function Refs.training(world: any): any
	local area = world and world:FindFirstChild("TrainingArea")
	return if area then area:FindFirstChild("Lanes") else world and world:FindFirstChild("TrainingZone")
end

function Refs.apron(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	local launch = lobby and lobby:FindFirstChild("LaunchArea")
	return (launch and launch:FindFirstChild("ThrowingApron")) or (lobby and lobby:FindFirstChild("ThrowingApron"))
end

function Refs.rankings(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	return (lobby and lobby:FindFirstChild("Leaderboards")) or (world and world:FindFirstChild("LobbyRankings"))
end

return Refs
