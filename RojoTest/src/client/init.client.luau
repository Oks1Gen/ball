--!strict
local controllers: { any } =
	{ require(script.Controllers.GameplayController), require(script.Controllers.OceanPreviewController) }
for _, controller in controllers do
	controller:Init({})
end
for _, controller in controllers do
	controller:Start()
end
print("[Ball] Client started - BUILD stack-1")
