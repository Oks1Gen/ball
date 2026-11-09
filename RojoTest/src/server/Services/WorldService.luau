--!strict
local Service: any = {}
function Service:Init(_context: any) end
function Service:Start()
	local root = script.Parent.Parent
	require(root.SingleWorld).apply()
	local worlds = workspace:FindFirstChild("Map")
	local existing = worlds and worlds:FindFirstChild("World1")
	if existing then
		require(root.KickZoneMigration).apply(existing)
	end
	local hierarchy = require(root.MapHierarchy)
	hierarchy.migrate()
	local layout = require(root.WorldLayout)
	for _, world in hierarchy.container():GetChildren() do
		if world.Name == "World1" then
			require(root.CourseLength).apply(world)
			layout.prepare(world)
		end
	end
	local map = require(root.MapBuilder).build()
	require(root.MapPolish).apply(map)
	require(root.MapSurfaceFix).apply(map)
	require(root.SkippingWorld).apply(map)
	require(root.ImportedFields).apply(map)
	require(root.BallStand).apply(map)
	require(root.EnvironmentRefresh).apply(map)
	require(root.EnvironmentRefresh).lighting()
	require(root.LobbyRankings).apply(map)
	require(root.LobbyDecorCleanup).apply(map)
	require(root.LobbyFlowers).apply(map)
	require(root.ImportedEggs).apply(map)
	require(root.SpawnGarden).apply(map)
	require(root.SpawnGardenPolish).apply(map)
	require(root.ExplorerOutpost).apply(map)
	require(root.PalmBeachScenery).apply(map)
	require(root.DesertDunesScenery).apply(map)
	require(root.CandyBeachScenery).apply(map)
	require(root.VioletValleyScenery).apply(map)
	require(root.EmberRiverScenery).apply(map)
	require(root.MoonlightScenery).apply(map)
	require(root.PolarExpeditionScenery).apply(map)
	require(root.SakuraFinaleScenery).apply(map)
	require(root.SakuraJapaneseScenery).apply(map)
	require(root.BiomeLengthExpansion).apply(map)
	require(root.SmallMapFlowers).apply(map)
	require(root.LobbyLayoutTwoAxes).apply(map)
	require(root.VolcanicEgg).apply(map)
	require(root.FootballPitches).apply(map)
	require(root.ZoneDividers).apply(map)
	require(game.ReplicatedStorage.Shared.PetVisuals).prepare()

	require(root.MapCleanup).apply(map)
	hierarchy.organize(map)
	require(root.TrainingLaneSigns).apply(map)
	require(root.EggSigns).apply(map)
	require(root.LobbyRankings).style(map)
	require(root.SurfaceSeparation).apply(map)
	require(root.WorldGeometryPolish).apply(map)
	require(root.CompactLobbyLayout).apply(map)
	require(root.TrainingLaneThemes).apply(map)
	require(root.WorldLighting).apply()
	layout.apply(map)
	require(root.BallShopStyle).apply(map)
	require(root.CourseRegions).apply(map)
	require(root.EntranceArchRemoval).apply(map)
	require(root.LobbyWalls).apply(map)
	require(root.KickZoneStyle).apply(map)
	require(root.LobbyPaths).apply(map)
	require(root.LobbyLawn).apply(map)
	require(root.BallStandSigns).apply(map)
	require(root.TrainingLaneSigns).apply(map)
	require(root.FootballCityScenery).apply(map)
	require(root.FootballCityLandmarks).apply(map)
	require(root.CourseVoxelStyle).apply(map)
	require(root.CloudSea).apply(map)
	require(root.LobbySceneCleanup).apply(map)
	require(root.LobbyWallDecor).apply(map)
	require(root.LobbyDecorRemoval).apply(map)
	require(root.TransparentCleanup).apply(hierarchy.container())
	require(root.EggStandStyle).apply(map)
	require(root.ElementalEggStyle).apply(map)
	require(root.EggSigns).applySolar(map)
	local hdStuds = require(root.WorldHDStuds)
	for _, world in hierarchy.container():GetChildren() do
		if world.Name:match("^World%d+$") and world:FindFirstChild("Lobby") then
			hdStuds.apply(world)
		end
	end
	self.map = map
	local world2 = require(root.Gameplay.WorldTravel).prepare(map)
	if world2 then
		if world2:GetAttribute("WorldScale") == nil then
			world2:SetAttribute("WorldScale", map:GetAttribute("WorldScale"))
		end
		require(root.TrainingLaneSigns).apply(world2)
		require(root.OceanEggStyle).apply(world2)
		require(root.ZoneDividers).applyOcean(world2, map)
	end
	self.world2 = world2
end
return Service
