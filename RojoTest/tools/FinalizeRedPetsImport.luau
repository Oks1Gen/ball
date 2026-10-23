-- Studio Edit only: finalize the pack uploaded with the 3D Importer.
local RunService = game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(), "Studio Edit mode required")
assert(game.PlaceId == 106456161057435, "Unexpected place")
local storage = game:GetService("ServerStorage")
local imports = storage:FindFirstChild("ImportedPetPacks")
if imports and imports:FindFirstChild("Red30") then
	return "Red30 already imported"
end
local source =
	assert(workspace:FindFirstChild("red-pets30"), "Import red-pets30.fbx with Insert into Workspace enabled")
local ids = {
	"RedPet01Forest",
	"RedPet02Meadow",
	"RedPet03GiftFairy",
	"RedPet04Sakura",
	"RedPet05Mushroom",
	"RedPet06Flame",
	"RedPet07Frost",
	"RedPet08Moon",
	"RedPet09Autumn",
	"RedPet10Cosmos",
	"RedPet11Ocean",
	"RedPet12BambooPanda",
	"RedPet13SakuraShrine",
	"RedPet14Angel",
	"RedPet15AncientRune",
	"RedPet16Shadow",
	"RedPet17Volcano",
	"RedPet18Lotus",
	"RedPet19Rose",
	"RedPet20Love",
	"RedPet21StrawberryCake",
	"RedPet22Dragon",
	"RedPet23CrimsonShrine",
	"RedPet24CherryBlossom",
	"RedPet25ScarletMushroom",
	"RedPet26FireGarden",
	"RedPet27Ruby",
	"RedPet28GoldenDragon",
	"RedPet29Inferno",
	"RedPet30FestivalShrine",
}
local staging = Instance.new("Folder")
staging.Name = "Red30"
staging:SetAttribute("SourcePack", "30 red pets")
staging:SetAttribute("ImportVersion", 1)
for index, id in ids do
	local sourcePart = source:FindFirstChild(id, true)
	assert(sourcePart and sourcePart:IsA("MeshPart"), "Missing pet: " .. id)
	assert(sourcePart.MeshId:match("^rbxassetid://%d+$"), "Pet mesh has not been uploaded: " .. id)
	local surface = sourcePart:FindFirstChildOfClass("SurfaceAppearance")
	assert(sourcePart.TextureID ~= "" or (surface and surface.ColorMap ~= ""), "Pet color texture missing: " .. id)
	local part = sourcePart:Clone()
	part.Name = "Visual"
	part.Color = Color3.new(1, 1, 1)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.RenderFidelity = Enum.RenderFidelity.Precise
	part.PivotOffset = CFrame.new(0, -part.Size.Y / 2, 0)
	local model = Instance.new("Model")
	model.Name = id
	model:SetAttribute("PackIndex", index)
	model:SetAttribute("SourcePack", "red30")
	part.Parent = model
	model.PrimaryPart = part
	model:PivotTo(CFrame.identity)
	model.Parent = staging
end
assert(#staging:GetChildren() == 30, "Incomplete pack")
local backups = storage:FindFirstChild("WorldBackups")
if not backups then
	backups = Instance.new("Folder")
	backups.Name = "WorldBackups"
	backups.Parent = storage
end
assert(not backups:FindFirstChild("OriginalRedPets30Import"), "Inspect the existing source backup")
if not imports then
	imports = Instance.new("Folder")
	imports.Name = "ImportedPetPacks"
	imports.Parent = storage
end
game:GetService("ChangeHistoryService"):SetWaypoint("Before storing imported Red30 pets")
staging.Parent = imports
source.Name = "OriginalRedPets30Import"
source.Parent = backups
game:GetService("Selection"):Set({ staging })
game:GetService("ChangeHistoryService"):SetWaypoint("30 red pets stored as persistent templates")
return { path = staging:GetFullName(), pets = #staging:GetChildren(), persistent = true }
