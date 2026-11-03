--!strict
-- Historical builders run between WorldLayout.prepare and WorldLayout.apply.
-- These child contracts describe that temporary layout, not runtime world paths.
export type Lobby = Model & { KickZoneFloor: Part, MapSpawn: SpawnLocation }
export type Lane = Model & { TrainingStrip: Part, StartingPad: Part, Foundation: Part }
export type Training = Model
export type Playfield = Model & {
	KickZonePrint: Part & { KickZoneLabel: SurfaceGui & { TextLabel: TextLabel } },
}
export type World = Folder & {
	Lobby: Lobby,
	SkippingWorld: Playfield,
	TrainingZone: Training,
	FieldCorridor: Model & { RiverBed: Part },
	PerimeterWalls: Model & { LobbyLeft: Part, LobbyRight: Part, LobbyBack: Part },
	CorridorBarriers: Model,
	EmptyItemStand: Model & { LowerTier: Part },
	SurfaceRepairs: Model,
	EnvironmentPolish: Model,
	NativeEnvironment: Model & { ShoreGardens: Folder & { BiomeGarden8: Model } },
	SpawnGarden: Model & { SideTerraces1: Model },
	SpawnGardenPolish: Model & { EntranceTunnel: Model },
	SmallMapFlowers: Model,
	LobbyRankings: Model & { skill: Model, wins: Model, best: Model },
}
return {}
