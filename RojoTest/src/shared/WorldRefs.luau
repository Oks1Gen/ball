--!strict
-- Runtime scene contract. Legacy fallbacks are only for the construction phase
-- and old places; gameplay never depends on a historical generator's folder.
local Refs = {}

function Refs.world(index: number): any
	local map = workspace:FindFirstChild("Map")
	return map and map:FindFirstChild("World" .. index)
end

function Refs.course(world: any): any
	return world and (world:FindFirstChild("FootballCourse") or world:FindFirstChild("SkippingWorld"))
end

function Refs.zone(world: any, index: number): any
	local course = Refs.course(world)
	local zones = course and course:FindFirstChild("Zones")
	return zones and zones:FindFirstChild(string.format("Zone%02d", index))
end

function Refs.field(world: any, index: number): any
	local course = Refs.course(world)
	local zones = course and course:FindFirstChild("Zones")
	local zone = Refs.zone(world, index)
	return if zones then zone and zone:FindFirstChild("Field") else course and course:FindFirstChild("Field_" .. index)
end

function Refs.portal(world: any): Model?
	local lobby = world and world:FindFirstChild("Lobby")
	local environment = lobby and lobby:FindFirstChild("Environment")
	local decor = environment and environment:FindFirstChild("ClubDecor")
	local portal = decor and (decor:FindFirstChild("BathyscapheHatch") or decor:FindFirstChild("WorldPortal"))
	return if portal and portal:IsA("Model") then portal else nil
end

function Refs.portalZone(world: any): BasePart?
	local portal = Refs.portal(world)
	local zone = portal and portal:FindFirstChild("TravelZone")
	return if zone and zone:IsA("BasePart") then zone else nil
end

function Refs.insidePortal(zone: BasePart, position: Vector3): boolean
	local localPosition = zone.CFrame:PointToObjectSpace(position)
	return math.abs(localPosition.X) <= zone.Size.X / 2
		and math.abs(localPosition.Z) <= zone.Size.Z / 2
		and localPosition.Y >= 0
		and localPosition.Y <= 8
end

function Refs.finish(world: any): BasePart?
	local course = Refs.course(world)
	local zones = course and course:FindFirstChild("Zones")
	local zone = zones and zones:FindFirstChild("Zone08")
	local boundaries = zone and zone:FindFirstChild("Boundaries")
	return boundaries and boundaries:FindFirstChild("ShotFinish") :: BasePart?
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

function Refs.eggStation(world: Instance?, id: string): (Instance?, BasePart?, Model?)
	if not world then
		return nil, nil, nil
	end
	local scenery = Refs.eggs(world)
	local fifth = id == "SolarCrown" or id == "AdminEgg"
	if fifth and id ~= (if world.Name == "World2" then "AdminEgg" else "SolarCrown") then
		return nil, nil, nil
	end
	local stand: Instance? = if fifth then Refs.volcanic(world) else scenery and scenery:FindFirstChild("Egg_" .. id)
	if not stand then
		return nil, nil, nil
	end
	local part = if fifth
		then stand:FindFirstChild("InteractionAnchor") or stand:FindFirstChild("HackedAdminEgg")
		else stand:FindFirstChild("EggShell")
	local visual = stand:FindFirstChild(if fifth then "Visual" else "ImportedVisual")
	return stand,
		if part and part:IsA("BasePart") then part else nil,
		if visual and visual:IsA("Model") then visual else nil
end

function Refs.balls(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	return (lobby and lobby:FindFirstChild("BallShop")) or (world and world:FindFirstChild("EmptyItemStand"))
end

function Refs.training(world: any): any
	local area = world and world:FindFirstChild("TrainingArea")
	return if area then area:FindFirstChild("Lanes") else world and world:FindFirstChild("TrainingZone")
end

function Refs.kickZoneFloor(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	local launch = lobby and lobby:FindFirstChild("KickZone")
	return (launch and launch:FindFirstChild("KickZoneFloor")) or (lobby and lobby:FindFirstChild("KickZoneFloor"))
end

function Refs.spawn(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	local spawns = lobby and lobby:FindFirstChild("Spawns")
	return spawns and spawns:FindFirstChildWhichIsA("SpawnLocation")
end

function Refs.rankings(world: any): any
	local lobby = world and world:FindFirstChild("Lobby")
	return (lobby and lobby:FindFirstChild("Leaderboards")) or (world and world:FindFirstChild("LobbyRankings"))
end

function Refs.workshop(world: Instance): Model?
	local lobby = world:FindFirstChild("Lobby")
	local model = lobby and lobby:FindFirstChild("PetWorkshop")
	return if model and model:IsA("Model") then model else nil
end
return Refs
