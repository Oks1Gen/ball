--!strict
local ContentProvider = game:GetService("ContentProvider")
local MaterialService = game:GetService("MaterialService")

local HDStuds = {}
HDStuds.LegacyImage = "rbxassetid://88156646156237"
local scales = { [3.6] = "3p6", [4.8] = "4p8", [6] = "6", [6.4] = "6p4" }

function HDStuds.variant(base: Enum.Material, tile: number): MaterialVariant?
	local suffix = scales[math.round(tile * 10) / 10]
	if not suffix then
		return nil
	end
	local variant = MaterialService:FindFirstChild("HDStuds_" .. base.Name .. "_" .. suffix)
	if
		variant
		and variant:IsA("MaterialVariant")
		and variant.BaseMaterial == base
		and math.abs(variant.StudsPerTile - tile) < 0.001
	then
		return variant
	end
	return nil
end

-- Check this in Studio before converting any existing surface.
function HDStuds.checkMaps(variant: MaterialVariant): (boolean, string)
	local color, normal = variant.ColorMap, variant.NormalMap
	if color == "" or normal == "" then
		return false, "Missing ColorMap or NormalMap"
	end
	local statuses: { [string]: Enum.AssetFetchStatus } = {}
	local probes = {}
	for _, id in { color, normal } do
		local probe = Instance.new("Texture")
		probe.Texture = id
		table.insert(probes, probe)
	end
	local ok, failure = pcall(function()
		ContentProvider:PreloadAsync(probes, function(id, status)
			statuses[id] = status
		end)
	end)
	for _, probe in probes do
		probe:Destroy()
	end
	if not ok then
		return false, tostring(failure)
	end
	local missing = {}
	for _, id in { color, normal } do
		if statuses[id] ~= Enum.AssetFetchStatus.Success then
			table.insert(missing, id)
		end
	end
	return #missing == 0, table.concat(missing, ", ")
end

-- Set on new blocks before parenting. The variant keeps the part's base material.
function HDStuds.apply(part: BasePart, tile: number)
	local variant = HDStuds.variant(part.Material, tile)
	assert(variant, ("No HDStuds variant for %s at tile %g"):format(part.Material.Name, tile))
	part.MaterialVariant = variant.Name
end

return HDStuds
