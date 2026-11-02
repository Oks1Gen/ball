--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldRefs = require(ReplicatedStorage.Shared.WorldRefs)
local IntroStreaming = {}
function IntroStreaming.start()
	local remote = Instance.new("RemoteEvent")
	remote.Name = "MapIntroStreaming"
	remote.Parent = ReplicatedStorage
	local sessions, used = {}, {}
	local function release(player)
		local anchors = sessions[player]
		sessions[player] = nil
		if not anchors then
			return
		end
		for _, anchor in anchors do
			pcall(function()
				player:RemoveReplicationFocus(anchor)
			end)
			anchor:Destroy()
		end
	end
	remote.OnServerEvent:Connect(function(player, command)
		if command == "Finish" then
			release(player)
			return
		end
		if command ~= "Prepare" or used[player] then
			return
		end
		used[player] = true
		local anchors = {}
		sessions[player] = anchors
		-- Server-owned positions read from the scene; the client cannot request arbitrary regions.
		local positions = {}
		local map = workspace:FindFirstChild("Map")
		local world = map and map:FindFirstChild("World1")
		local spawn = world and WorldRefs.spawn(world)
		if spawn then
			table.insert(positions, spawn.Position + Vector3.new(0, 10, 0))
		end
		local last: BasePart? = nil
		for i = 1, 8 do
			local field = world and WorldRefs.field(world, i)
			if field then
				table.insert(positions, Vector3.new(field.Position.X - 7, field.Position.Y + 9.4, field.Position.Z))
				last = field
			end
		end
		if last then
			table.insert(positions, last.Position + Vector3.new(0, 50, 7 - last.Size.Z / 2))
		end
		for _, position in positions do
			local anchor = Instance.new("Part")
			anchor.Name = "IntroStreamingFocus"
			anchor.Size = Vector3.one
			anchor.Anchored = true
			anchor.Transparency = 1
			anchor.CanCollide = false
			anchor.CanTouch = false
			anchor.CanQuery = false
			anchor.Position = position
			anchor.Parent = workspace
			table.insert(anchors, anchor)
			player:AddReplicationFocus(anchor)
		end
		-- Also release if a client disconnects or never sends completion.
		task.delay(45, function()
			if sessions[player] == anchors then
				release(player)
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		release(player)
		used[player] = nil
	end)
end
return IntroStreaming
