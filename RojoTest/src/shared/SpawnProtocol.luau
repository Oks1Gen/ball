--!strict
-- Client -> server: CharacterSpawnReady(character: Model), no extra arguments.
-- Only releases the sender's current, pending, server-positioned character.
return {
	Remote = "CharacterSpawnReady",
	Positioned = "SpawnPositioned",
	Ready = "SpawnReady",
}
