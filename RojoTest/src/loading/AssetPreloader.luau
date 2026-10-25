--!strict
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Preloader = {}

export type Entry = { id: string, instance: Instance }
type Cancelled = () -> boolean

function Preloader.waitFor(parent: Instance, name: string, cancelled: Cancelled): Instance?
	local deadline = os.clock() + 30
	while not cancelled() do
		local child = parent:FindFirstChild(name)
		if child then
			return child
		end
		assert(os.clock() < deadline, "Loading dependency unavailable: " .. parent.Name .. "." .. name)
		RunService.Heartbeat:Wait()
	end
	return nil
end

-- One typed request per unique content URI/type. In particular, bare audio
-- strings are interpreted as images by PreloadAsync, so use Sound instances.
function Preloader.collect(player: Player, icon: string, cancelled: Cancelled): { Entry }
	local entries: { Entry } = {}
	local seen: { [string]: boolean } = {}
	local function add(class: string, property: string, value: string)
		if value == "" or value == "rbxassetid://0" then
			return
		end
		local assetId = value:match("^rbxassetid://(%d+)$") or value:match("[?&]id=(%d+)")
		local id = if assetId then "rbxassetid://" .. assetId else value
		local version = value:match("[?&]version=(%d+)")
		local key = class .. ":" .. property .. ":" .. id .. (if version then ":version=" .. version else "")
		if seen[key] then
			return
		end
		seen[key] = true
		local instance: any = Instance.new(class)
		-- Normalize only the deduplication key. The request URI may carry an
		-- explicit version, and rewriting it can resurrect a cached fetch failure.
		instance[property] = value
		table.insert(entries, { id = value, instance = instance })
	end
	local shared = Preloader.waitFor(ReplicatedStorage, "Shared", cancelled)
	local playerScripts = Preloader.waitFor(player, "PlayerScripts", cancelled)
	local client = if playerScripts then Preloader.waitFor(playerScripts, "Client", cancelled) else nil
	if not shared or not client then
		return entries
	end
	local configModule = Preloader.waitFor(shared, "GameConfig", cancelled)
	local assetsModule = Preloader.waitFor(client, "UIAssets", cancelled)
	local templates = Preloader.waitFor(shared, "PetTemplates", cancelled)
	if cancelled() or not configModule or not assetsModule or not templates then
		return entries
	end
	local config = require(ReplicatedStorage.Shared.GameConfig)
	-- UIAssets is a runtime PlayerScripts clone; its path is deliberately dynamic.
	local loadModule = require :: (ModuleScript) -> any
	local assets = loadModule(assetsModule :: ModuleScript)
	for _, id in assets.Images do
		add("ImageLabel", "Image", id)
	end
	add("ImageLabel", "Image", assets.Burst)
	add("ImageLabel", "Image", icon)
	add("ImageLabel", "Image", config.StudTexture)
	add("ImageLabel", "Image", config.WaterTexture)
	add("Sound", "SoundId", config.Music)
	local notificationModule = Preloader.waitFor(shared, "NotificationSounds", cancelled)
	local zoneModule = Preloader.waitFor(shared, "ZoneTransitionSound", cancelled)
	if notificationModule and zoneModule then
		for _, sound in require(ReplicatedStorage.Shared.NotificationSounds) do
			add("Sound", "SoundId", sound.id)
		end
		add("Sound", "SoundId", require(ReplicatedStorage.Shared.ZoneTransitionSound).id)
	end
	-- Snapshot only content currently replicated to this client, including the
	-- pet/ball templates. Future streamed regions load through Roblox normally.
	local function scan(node: Instance)
		if node:IsA("ImageLabel") or node:IsA("ImageButton") then
			add("ImageLabel", "Image", node.Image)
		elseif
			node:IsA("Decal")
			or node:IsA("Texture")
			or node:IsA("ParticleEmitter")
			or node:IsA("Beam")
			or node:IsA("Trail")
		then
			add("ImageLabel", "Image", node.Texture)
		elseif node:IsA("Sound") then
			add("Sound", "SoundId", node.SoundId)
		elseif node:IsA("Animation") then
			add("Animation", "AnimationId", node.AnimationId)
		elseif node:IsA("MeshPart") then
			add("SpecialMesh", "MeshId", node.MeshId)
			add("ImageLabel", "Image", node.TextureID)
		elseif node:IsA("SpecialMesh") then
			add("SpecialMesh", "MeshId", node.MeshId)
			add("ImageLabel", "Image", node.TextureId)
		elseif node:IsA("Sky") then
			for _, property in
				{
					"SkyboxBk",
					"SkyboxDn",
					"SkyboxFt",
					"SkyboxLf",
					"SkyboxRt",
					"SkyboxUp",
					"SunTextureId",
					"MoonTextureId",
				}
			do
				add("ImageLabel", "Image", (node :: any)[property])
			end
		end
	end
	for _, container in { workspace, shared, game:GetService("Lighting"), game:GetService("SoundService"), player } do
		for index, node in container:GetDescendants() do
			if cancelled() then
				return entries
			end
			scan(node)
			if index % 400 == 0 then
				RunService.Heartbeat:Wait()
			end
		end
	end
	return entries
end

function Preloader.destroy(entries: { Entry })
	for _, entry in entries do
		entry.instance:Destroy()
	end
end

function Preloader.load(entries: { Entry }, cancelled: Cancelled, changed: (number, number, number) -> ())
	local loaded, failed, completed, nextIndex = 0, 0, 0, 1
	local total = #entries
	local stopped = false
	local deadline = os.clock() + 45
	changed(0, total, 0)
	for _ = 1, math.min(6, total) do
		task.spawn(function()
			while not stopped and not cancelled() do
				local index = nextIndex
				nextIndex += 1
				local entry = entries[index]
				if not entry then
					return
				end
				local resolved, successful = false, true
				local ok = pcall(function()
					ContentProvider:PreloadAsync(
						{ entry.instance },
						function(_id: string, status: Enum.AssetFetchStatus)
							resolved = true
							if status ~= Enum.AssetFetchStatus.Success then
								successful = false
							end
						end
					)
				end)
				entry.instance:Destroy()
				if stopped or cancelled() then
					return
				end
				if ok and resolved and successful then
					loaded += 1
				else
					failed += 1
					warn("[Loading] Asset could not load: " .. entry.id)
				end
				completed += 1
				changed(loaded, total, failed)
			end
		end)
	end
	while completed < total and not cancelled() and os.clock() < deadline do
		RunService.Heartbeat:Wait()
	end
	stopped = true
	-- PreloadAsync itself cannot be cancelled. Active workers free their own
	-- requests on return; discard queued requests and ignore all late callbacks.
	for index = nextIndex, total do
		entries[index].instance:Destroy()
	end
	return { loaded = loaded, failed = failed, pending = total - completed }
end

return Preloader
