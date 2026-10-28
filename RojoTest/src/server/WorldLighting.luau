--!strict
local Preset = {}
local C = Color3.fromRGB

function Preset.apply()
	local lighting = game:GetService("Lighting")
	local backups = game.ServerStorage:FindFirstChild("WorldBackups")
	if not backups then
		backups = Instance.new("Folder")
		backups.Name, backups.Parent = "WorldBackups", game.ServerStorage
	end
	if not backups:FindFirstChild("BeforeBalancedDaylight") then
		local snapshot = Instance.new("Folder")
		snapshot.Name, snapshot.Parent = "BeforeBalancedDaylight", backups
		for _, key in
			{
				"Ambient",
				"OutdoorAmbient",
				"Brightness",
				"ClockTime",
				"ExposureCompensation",
				"ShadowSoftness",
				"EnvironmentDiffuseScale",
				"EnvironmentSpecularScale",
				"GlobalShadows",
			}
		do
			snapshot:SetAttribute(key, (lighting :: any)[key])
		end
		for _, effect in lighting:GetChildren() do
			if effect:IsA("PostEffect") or effect:IsA("Atmosphere") then
				effect:Clone().Parent = snapshot
			end
		end
	end
	-- One grade and one restrained bloom; old enabled effects otherwise stack.
	for _, effect in lighting:GetChildren() do
		if effect:IsA("ColorCorrectionEffect") or effect:IsA("BloomEffect") or effect:IsA("SunRaysEffect") then
			effect.Enabled = false
		end
	end
	lighting.Ambient, lighting.OutdoorAmbient = C(83, 95, 115), C(135, 148, 165)
	lighting.Brightness, lighting.ExposureCompensation = 2, -0.18
	lighting.ClockTime, lighting.ShadowSoftness = 14.1, 0.45
	lighting.GlobalShadows = true
	lighting.EnvironmentDiffuseScale, lighting.EnvironmentSpecularScale = 0.55, 0.25
	local grade = (
		lighting:FindFirstChild("BalancedDaylightGrade") or Instance.new("ColorCorrectionEffect")
	) :: ColorCorrectionEffect
	grade.Name, grade.Parent = "BalancedDaylightGrade", lighting
	grade.Enabled, grade.Brightness, grade.Contrast, grade.Saturation = true, 0, 0.055, 0.035
	grade.TintColor = C(255, 253, 249)
	local bloom = (lighting:FindFirstChild("BalancedDaylightBloom") or Instance.new("BloomEffect")) :: BloomEffect
	bloom.Name, bloom.Parent = "BalancedDaylightBloom", lighting
	bloom.Enabled, bloom.Intensity, bloom.Size, bloom.Threshold = true, 0.07, 16, 1.9
	local atmosphere = lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		atmosphere.Density, atmosphere.Offset, atmosphere.Haze, atmosphere.Glare = 0.17, 0.1, 0.7, 0
		atmosphere.Color, atmosphere.Decay = C(213, 231, 249), C(164, 185, 212)
	end
	lighting:SetAttribute("BalancedDaylightVersion", 1)
end

return Preset
