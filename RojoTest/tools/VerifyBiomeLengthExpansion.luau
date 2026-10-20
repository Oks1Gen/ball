-- Read-only route checks in Edit or Server. Does not modify player progression.
local map=workspace.ProgressionMap
local world=map.SkippingWorld
local front=map:GetAttribute("RouteFrontZ")
assert(map:GetAttribute("BiomeLengthScale")==1.5)
assert(map:GetAttribute("RouteLengthStuds")==2160)
local checks=0
local rp=RaycastParams.new()
rp.FilterType=Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances={map.WaterCorridor,world}
for i=1,8 do
	local water=world["Water_"..i]
	assert(math.abs(water.Size.Z-270)<.01)
	assert(math.abs(water.Position.Z-(front-(i-.5)*270))<.01)
	assert(math.abs(water.Size.X-111.6)<.01)
	local banks=0
	for _,b in world:GetChildren() do
		if b.Name:match("^BiomeBank"..i.."_[12]$") then
			banks+=1
			assert(math.abs(b.Size.Z-270)<.01 and math.abs(b.Position.Z-water.Position.Z)<.01)
		end
	end
	assert(banks==4)
	for _,x in {-50,-35,-25,-13,110,120,132,146} do
		for _,t in {1,45,135,225,269} do
			local top=(x< -29.9 or x>126.1) and 29 or 24
			local z=front-(i-1)*270-t
			local hit=workspace:Raycast(Vector3.new(x,top+.1,z),Vector3.new(0,-3,0),rp)
			assert(hit and math.abs(hit.Position.Y-top)<.31,"Floor gap at "..x..", "..z)
			checks+=1
		end
	end
end
local back=front-2160
assert(math.abs(world.SakuraJapaneseFinale.SakuraGatewayFrame:GetPivot().Position.Z-(back+7))<.01)
assert(math.abs(world.RiverEndSafety.Position.Z-(back-2))<.01)
assert(math.abs(map.PerimeterWalls.CorridorEnd.Position.Z-(back-3))<.01)
for _,name in {"CorridorLeft","CorridorRight"} do
	local a,b=map.PerimeterWalls[name],map.PerimeterWalls[name.."FinalExtension"]
	assert(math.abs((a.Position.Z-a.Size.Z/2)-(b.Position.Z+b.Size.Z/2))<.01)
	assert(math.abs(b.Position.Z-b.Size.Z/2-back)<.01)
end
-- Clone only the module to avoid Edit require caches after a Rojo source update.
local module=game.ReplicatedStorage.Shared.GameConfig:Clone()
module.Parent=game.ServerStorage
local Config=require(module)
module:Destroy()
local limit=Config.shotLimit(1,map)
assert(Config.shotDistance(1000000,1,1,map)==limit)
assert(Config.shotDistance(100000,1,1,map)>Config.shotDistance(10000,1,1,map)*2.5)
assert(Config.shotDistance(1e15,10,2)==Config.shotLimit(2))
assert(Config.shotDuration(limit,1)>13)
assert(Config.shotDuration(Config.shotLimit(2),2)==10)
local frame=Config.arenaFrame(map)
local start=frame:PointToWorldSpace(Vector3.new(-115.35,1.8,-.3))
local finish=start+frame.LookVector*(limit/Config.DistancePerStud)
assert(finish.Z>back and finish.Z<back+270,"Maximum flight must finish in Sakura")
assert(math.abs(finish.Z-world.SakuraJapaneseFinale.SakuraGatewayFrame:GetPivot().Position.Z)<.25,"Maximum shot reaches the gateway plane")
return {biomes=8,lengthPerBiome=270,totalLength=2160,floorChecks=checks,maxShot=limit,finish=tostring(finish)}
