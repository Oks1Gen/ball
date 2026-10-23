-- Studio MCP Edit/Play. Uses a separate audio handle, muted groups and no profile/network writes.
local RunService = game:GetService("RunService")
local client = RunService:IsRunning() and game.Players.LocalPlayer.PlayerScripts.Client
	or game.StarterPlayer.StarterPlayerScripts.Client
local Audio = require(client.Controllers.AudioEffects)
local folder = Instance.new("Folder")
folder.Name = "ImpactAudioVerification"
folder.Parent = workspace
local canvas = Instance.new("Frame")
local settings = { sound = 0, effects = false }
local audio = Audio.mount({
	canvas = canvas,
	effectsFolder = folder,
	snapshot = function()
		return { data = { settings = settings } }
	end,
	panelOpen = function()
		return false
	end,
})
audio.applyVolumes(0, 0)
local assertions = 0
local function check(value, message)
	assert(value, message)
	assertions += 1
end
local position = workspace.CurrentCamera.CFrame.Position + Vector3.new(0, 0, -5)
local ok, result = pcall(function()
	local sources = folder.TrailImpactAudio
	audio.bounce(position, "Red", 1, 1)
	check(#sources:GetChildren() == 0, "Sound setting zero suppresses impacts")
	settings.sound = 100
	audio.bounce(position + Vector3.yAxis * 300, "Blue", 1, 1)
	check(#sources:GetChildren() == 0, "Distance culling")
	for _, id in { "None", "White", "Red", "Blue", "Purple", "Rainbow" } do
		audio.bounce(position, id, 1, 0.7)
		task.wait(0.09)
		local source
		for _, candidate in sources:GetChildren() do
			if candidate:GetAttribute("TrailStyle") == id then
				source = candidate
			end
		end
		check(source ~= nil, "Impact with visual Effects off: " .. id)
		local sounds = {}
		for _, item in source:GetChildren() do
			if item:IsA("Sound") then
				table.insert(sounds, item)
			end
		end
		check(#sounds == (id == "Rainbow" and 2 or 1), "Sound layers: " .. id)
		game:GetService("ContentProvider"):PreloadAsync(sounds)
		for _, sound in sounds do
			check(sound.IsLoaded and sound.TimeLength > 0, "Built-in audio loaded")
			check(sound.SoundGroup.Volume == 0 and sound.RollOffMaxDistance == 85, "Volume bus and spatial rolloff")
		end
		if id == "Purple" then
			check(sounds[1]:FindFirstChildWhichIsA("EchoSoundEffect") ~= nil, "Magic echo")
		end
		if id == "Red" then
			check(sounds[1]:FindFirstChildWhichIsA("EqualizerSoundEffect") ~= nil, "Fire equalizer")
		end
	end
	for _ = 1, 12 do
		audio.bounce(position, "Red", 8, 0)
		task.wait(0.05)
	end
	check(#sources:GetChildren() <= 8, "Voice budget")
	task.wait(1.2)
	check(#sources:GetChildren() == 0, "Automatic voice cleanup")
	return { assertions = assertions, families = 6, profileChanged = false }
end)
audio.destroy()
canvas:Destroy()
folder:Destroy()
assert(ok, tostring(result))
return result
