--!strict
-- One palette for the World1 lobby: terraces, the entrance tunnel, garden decor and paths.
-- CompactLobbyLayout and the lobby Edit tools (tools/LobbyStyleRefresh.luau) read it; biome
-- scenery, stations and training lanes keep their own colours. Rationale: docs/lobby-style.md.
local RGB = Color3.fromRGB

local Palette = {
	Earth = RGB(214, 139, 62),
	EarthDark = RGB(195, 117, 41),
	WallCheckerDepth = 0.02,
	Grass = RGB(92, 205, 48),
	Leaf = RGB(47, 166, 55),
	LeafLight = RGB(125, 217, 62),
	Stone = RGB(136, 152, 157),
	StoneLight = RGB(163, 173, 172),
	Wood = RGB(135, 89, 49),
	WoodDark = RGB(112, 70, 42),
	Water = RGB(40, 209, 226),
	Path = RGB(169, 173, 180),
	PathChecker = RGB(137, 142, 151),
	PathCheckerCell = 8,
	PathEdge = RGB(112, 117, 126),
	PathCurb = RGB(207, 210, 216),
	PathArrow = RGB(78, 82, 92),
	ThrowZone = RGB(255, 168, 38),
	ThrowZoneChecker = RGB(255, 204, 64),
	ThrowZoneEdge = RGB(226, 128, 22),
	ThrowZoneCell = 4,
	ThrowZoneBand = 1.2,

	Studs = "rbxassetid://88156646156237",
	StudsTransparency = 0.45,
	StudsPerTile = 8,
	CheckerCell = 4,
}

-- Shades that drifted in from separate decor passes snap to the nearest of these tokens.
Palette.SnapTokens = {
	Palette.Leaf,
	Palette.LeafLight,
	Palette.Stone,
	Palette.StoneLight,
	Palette.Wood,
	Palette.WoodDark,
}
Palette.SnapDistance = 16 -- RGB units

return Palette
