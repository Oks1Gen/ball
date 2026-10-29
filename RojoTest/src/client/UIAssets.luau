--!strict
-- Individual generated football UI images. Sources and prompts: Assets/UI/.
local Assets = {
	Sunburst = "rbxassetid://100836241976168",
	Burst = "rbxassetid://135516711069753",
	Images = {
		Shop = "rbxassetid://104677004413399",
		Rebirth = "rbxassetid://117395426215941",
		Auras = "rbxassetid://122142548634924",
		Pets = "rbxassetid://90000264183054",
		Trails = "rbxassetid://133259536806674",
		Inventory = "rbxassetid://136822923699289",
		Gifts = "rbxassetid://80164859809768",
		Wins = "rbxassetid://114161247280750",
		Daily = "rbxassetid://140481827195284",
		Offline = "rbxassetid://79379405188057",
		Close = "rbxassetid://120816444454980",
		Ball = "rbxassetid://81860763257111",
		Egg = "rbxassetid://134171391259810",
		Items = "rbxassetid://133556621296720",
		Relic = "rbxassetid://71988075139344",
		WhiteTrail = "rbxassetid://87843827315556",
		RedTrail = "rbxassetid://137645592170260",
		BlueTrail = "rbxassetid://114339554508731",
		PurpleTrail = "rbxassetid://73386437552168",
		RainbowTrail = "rbxassetid://104569410708834",
		Settings = "rbxassetid://82267402301590",
		UpdateLog = "rbxassetid://106721086001751",
		Arrow = "rbxassetid://124139408657162",
		Plus = "rbxassetid://125108671199271",
		Check = "rbxassetid://113367733100050",
		Alert = "rbxassetid://137225788311504",
		Lock = "rbxassetid://81632895708261",
		Luck = "rbxassetid://79885069948688",
		WinBoost = "rbxassetid://118899933674575",
		LuckyCat = "rbxassetid://72721187698931",
		Titles = "rbxassetid://127815495659903",
		Skill = "rbxassetid://121378767438034",
		Robux = "rbxassetid://90468580391337",
	},
}
local Aliases: { [string]: string } = { Stone = "Ball", Eggs = "Egg" }
function Assets.resolve(kind: string): (string, Vector2, Vector2)
	local name = Aliases[kind] or kind
	return Assets.Images[name] or "", Vector2.zero, Vector2.zero
end
-- A newly shared image can retain a failed URI fetch in Studio. This fallback
-- uses the same authorized asset, with one shared allocation per image URI.
local editable: { [string]: EditableImage } = {}
local waiting: { [string]: { ImageLabel } } = {}
function Assets.bind(label: ImageLabel)
	local uri = label.Image
	if uri == "" then
		return
	end
	if editable[uri] then
		label.ImageContent = Content.fromObject(editable[uri])
		return
	end
	task.delay(2, function()
		if not label.Parent or label.IsLoaded then
			return
		end
		if editable[uri] then
			label.ImageContent = Content.fromObject(editable[uri])
			return
		end
		if waiting[uri] then
			table.insert(waiting[uri], label)
			return
		end
		waiting[uri] = { label }
		local ok, result = pcall(function()
			return game:GetService("AssetService"):CreateEditableImageAsync(Content.fromUri(uri))
		end)
		local labels = waiting[uri]
		waiting[uri] = nil
		if not ok or not result then
			warn("[FootballUI] Image could not load: " .. uri .. ": " .. tostring(result))
			return
		end
		editable[uri] = result
		for _, target in labels do
			if target.Parent then
				target.ImageContent = Content.fromObject(result)
			end
		end
	end)
end
return Assets
