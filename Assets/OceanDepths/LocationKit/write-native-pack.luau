-- Run from the repository root: lune run Assets/OceanDepths/LocationKit/write-native-pack.luau
local fs=require("@lune/fs")
local serde=require("@lune/serde")
local roblox=require("@lune/roblox")
local root="Assets/OceanDepths/LocationKit/"
local data=serde.decode("json",fs.readFile(root.."native-architecture.json"))
local function value(v)
	if type(v)~="table" or not v.type then return v end
	if v.type=="EnumItem"then return roblox.Enum[v.enum][v.value]end
	return roblox[v.type].new(table.unpack(v.value))
end
local count=0
local function node(n)
	local instance=roblox.Instance.new(n.class);instance.Name=n.name
	for key,v in n.properties do instance[key]=value(v)end
	for key,v in n.attributes do instance:SetAttribute(key,value(v))end
	for _,child in n.children do node(child).Parent=instance end
	count+=1
	return instance
end
local models={}
for _,m in data.models do table.insert(models,node(m))end
local bytes=roblox.serializeModel(models,true)
fs.writeFile(root.."native-architecture.rbxmx",bytes)
local decoded=roblox.deserializeModel(bytes)
assert(#decoded==#models,"Round-trip model count")
print("Native architecture:",#models,"models;",count,"instances; XML round-trip passed")
