--!strict
local Input = game:GetService("UserInputService")
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Presentation = {}

function Presentation.keyboard(): boolean
	return Input.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
end

function Presentation.kickHint(canThrow: boolean, training: boolean): string
	if training then
		return "Tap the purple target for ×2 Skill • Leave the lane to stop"
	end
	if not canThrow then
		return "Walk or stand on a training lane to gain Skill"
	end
	local action = if Input.PreferredInput == Enum.PreferredInput.Touch
		then "Tap KICK"
		elseif Input.PreferredInput == Enum.PreferredInput.Gamepad then "Press X to kick"
		else "Press E to kick"
	return action .. " • Train to increase hit distance"
end

function Presentation.readyGifts(snapshot: any): number
	local count = 0
	if snapshot then
		for i, gift in Config.Gifts do
			if not snapshot.gifts[i] and snapshot.elapsed >= gift.time then
				count += 1
			end
		end
	end
	return count
end

function Presentation.countdown(seconds: number): string
	local value = math.max(0, math.ceil(seconds))
	if value < 3600 then
		return string.format("%02d:%02d", math.floor(value / 60), value % 60)
	end
	return string.format("%02d:%02d:%02d", math.floor(value / 3600), math.floor(value / 60) % 60, value % 60)
end

return Presentation
