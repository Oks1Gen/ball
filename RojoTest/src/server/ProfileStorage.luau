--!strict
-- Server-only storage routing. Production keeps its existing namespace.
export type Environment = {
	name: string,
	storeName: string,
	legacyStoreName: string?,
}

local Studio: Environment = table.freeze({
	name = "Studio",
	storeName = "BallProfiles_Studio_v1",
})
local Production: Environment = table.freeze({
	name = "Production",
	storeName = "BallProfiles_v1",
	legacyStoreName = "StoneSkipping_1",
})

local Storage = {}
Storage.AccessTimeout = 20

function Storage.select(isStudio: boolean): Environment
	return if isStudio then Studio else Production
end

function Storage.canPersist(state: string): boolean
	return state == "Access"
end

return table.freeze(Storage)
