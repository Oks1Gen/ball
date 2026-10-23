-- Studio Edit verification. Never changes player profiles or currency.
local shared = game.ReplicatedStorage.Shared
local configSource = shared.GameConfig:Clone()
configSource.Parent = shared
local Config = require(configSource)
configSource:Destroy()
local visualSource = shared.PetVisuals:Clone()
visualSource.Parent = shared
local Visuals = require(visualSource)
Visuals.prepare()
local expected = { ScarletMushroom = 45, StrawberryCake = 30, AutumnCat = 20, FlameCat = 5 }
local boosts = { ScarletMushroom = 1.2, StrawberryCake = 1.5, AutumnCat = 2.5, FlameCat = 8 }
local egg = Config.find(Config.Eggs, "Common")
assert(egg.cost == 50 and egg.boost == 1 and #Config.eggPets("Common") == 4)
local counts = {}
for roll = 1, 100 do
	local pet = Config.rollEggPet("Common", roll)
	assert(expected[pet.id] and pet.visual == pet.id)
	assert(pet.boost * egg.boost == boosts[pet.id] and pet.eggBoost == 1)
	counts[pet.id] = (counts[pet.id] or 0) + 1
end
for id, chance in expected do
	assert(counts[id] == chance, "Wrong red-egg chance")
	local model = assert(Visuals.create(id, 2.8), "Missing red-egg preview")
	local cf, size = model:GetBoundingBox()
	assert(cf.Position.Magnitude < 0.001 and math.abs(math.max(size.X, size.Y, size.Z) - 2.8) < 0.001)
	local part = assert(model:FindFirstChildWhichIsA("MeshPart", true))
	assert(part.MeshSize.Magnitude > 0 and part.MeshId ~= "", "Mesh failed to hydrate")
	assert(part.TextureID == "rbxassetid://123032152483532", "Hydration lost the color atlas")
	assert(part.Anchored and not part.CanCollide and not part.CanTouch and not part.CanQuery)
	model:Destroy()
	local follower = assert(Visuals.follower(id), "Missing follower")
	follower:Destroy()
end
for _, id in { "Dog", "Cat", "Bunny", "Fox", "Dragon" } do
	assert(Config.pet(id), "Saved pet definition lost")
end
local profileSource = game.ServerScriptService.Server.Services.ProfileService:Clone()
profileSource.Parent = game.ServerScriptService.Server:WaitForChild("Services")
local ProfileService = require(profileSource)
ProfileService:Init({
	ProfileStore = {
		New = function()
			return { Mock = {} }
		end,
	},
})
for _, list in { Config.Pets, Config.LegacyPets } do
	for _, pet in list do
		assert(ProfileService.catalog.pets[pet.id], "Profile whitelist lost a pet")
	end
end
local Data = require(shared.Core.ProfileData)
local saved = Data.normalize({
	pets = {
		{ uid = "old-dog", id = "Dog", boost = 1.2 },
		{ uid = "new-flame", id = "FlameCat", boost = 8 },
	},
	equipped = { "old-dog", "new-flame" },
}, ProfileService.catalog)
assert(#saved.pets == 2 and #saved.equipped == 2, "Profile normalization discarded old/new pets")
profileSource:Destroy()
visualSource:Destroy()
return { price = egg.cost, chances = counts, legacyPets = "preserved", meshes = "four persistent textured assets" }
