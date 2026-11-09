--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local ReactRoblox = require(game.ReplicatedStorage.Packages.ReactRoblox)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local Challenges = require(game.ReplicatedStorage.Shared.Core.Challenges)
local U = require(script.Parent.Parent.CollectorUI.Components)
local T = require(script.Parent.Parent.CollectorUI.Theme)
local e = React.createElement
local View = {}

function View.mount(parent: Frame, context: any): () -> ()
	local host = Instance.new("Frame")
	host.Name = "ProgressionRewards"
	host.BackgroundTransparency = 1
	host.Position = UDim2.fromOffset(16, 52)
	host.Size = UDim2.new(1, -32, 1, -66)
	host.Parent = parent
	local root = ReactRoblox.createRoot(host)
	local alive = true
	host.Destroying:Once(function()
		alive = false
		root:unmount()
	end)
	return function()
		local snapshot = context.snapshot()
		if not alive or not snapshot then
			return
		end
		local data = snapshot.data
		local width = parent.Size.X.Offset - 32
		local children: any = {}
		local rowHeight, gap = 76, 12
		local function row(
			index: number,
			title: string,
			reward: string,
			caption: string,
			ready: boolean,
			action: () -> ()
		)
			children[tostring(index)] = e(U.Surface, {
				Name = "Reward" .. index,
				Position = UDim2.fromOffset(4, (index - 1) * (rowHeight + gap)),
				Size = UDim2.fromOffset(width - 24, rowHeight),
				Color = T.Recess,
				Quiet = true,
				Children = {
					Title = e(U.Label, {
						Text = title,
						Position = UDim2.fromOffset(12, 8),
						Size = UDim2.fromOffset(width - 208, 28),
						TextSize = 19,
						Scaled = true,
					}),
					Reward = e(U.Label, {
						Text = reward,
						Position = UDim2.fromOffset(12, 38),
						Size = UDim2.fromOffset(width - 208, 26),
						TextSize = 16,
						Color = T.Gold,
						Scaled = true,
					}),
					Claim = e(U.Button, {
						Name = "Claim",
						Text = caption,
						Position = UDim2.new(1, -164, 0, 16),
						Size = UDim2.fromOffset(148, 44),
						TextSize = 18,
						Color = T.Colors.Green,
						Disabled = not ready,
						OnActivated = action,
					}),
				},
			})
		end
		for index, goal in Config.Balance.Challenges do
			local key = Challenges.key(data.world, goal.id)
			local progress = (data.challengeProgress or {})[key] or 0
			local claimed = (data.challengeClaims or {})[key] == true
			local ready = not claimed and progress >= goal.hits
			row(
				index,
				goal.title,
				"+" .. goal.wins .. " Wins • " .. goal.material .. " Shards",
				if claimed then "Claimed" elseif ready then "Claim" else progress .. " / " .. goal.hits,
				ready,
				function()
					context.send("ClaimChallenge", goal.id)
				end
			)
		end
		for index, gift in Config.Gifts do
			local claimed = snapshot.gifts[index] == true
			local remaining = math.max(0, gift.time - snapshot.elapsed)
			row(
				#Config.Balance.Challenges + index,
				"Playtime • " .. math.floor(gift.time / 60) .. " min",
				"+" .. gift.wins .. " Wins • +" .. gift.skill .. " Skill",
				if claimed then "Claimed" elseif remaining <= 0 then "Claim" else math.ceil(remaining / 60) .. " min",
				not claimed and remaining <= 0,
				function()
					context.send("Gift", index)
				end
			)
		end
		root:render(e(U.Scroll, {
			Name = "RewardList",
			Size = UDim2.fromScale(1, 1),
			Height = (#Config.Balance.Challenges + #Config.Gifts) * (rowHeight + gap),
			Children = children,
		}))
	end
end

return View
