local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local DataStoreService=game:GetService("DataStoreService")
local MarketplaceService=game:GetService("MarketplaceService")
local HttpService=game:GetService("HttpService")
local Config=require(ReplicatedStorage.Shared.GameConfig)
local ShotFeedback=require(ReplicatedStorage.Shared.ShotFeedback)
local ShotMotion=require(ReplicatedStorage.Shared.ShotMotion)
local TrainingMotion=require(ReplicatedStorage.Shared.TrainingMotion)
local BallPurchases=require(ReplicatedStorage.Shared.BallPurchases)
local LobbyRankings=require(script.Parent.LobbyRankings)
local AdminAccess=require(script.Parent.AdminAccess)
local AdminService=require(script.Parent.AdminService)
local FlightStreaming=require(script.Parent.FlightStreaming)
local Game={}
local started=false
function Game.start(map,world2)
	if started then return end started=true
	local remote=Instance.new("Folder") remote.Name="SkippingRemotes" remote.Parent=ReplicatedStorage
	local action=Instance.new("RemoteEvent") action.Name="Action" action.Parent=remote
	local update=Instance.new("RemoteEvent") update.Name="Update" update.Parent=remote
	local effect=Instance.new("RemoteEvent") effect.Name="Effect" effect.Parent=remote
	local store=DataStoreService:GetDataStore("StoneSkipping_"..Config.DataVersion)
	local session=game.JobId~="" and game.JobId or HttpService:GenerateGUID(false)
	local states={}
	local admin
	local function arenaFor(player)
		local state=states[player] return state and state.data.world==2 and world2 or map
	end
	local function frameFor(player)
		return Config.arenaFrame(arenaFor(player))
	end
	local function pointFor(player, point)
		return frameFor(player):PointToWorldSpace(point)
	end
	if RunService:IsStudio() then Game.studioState=function(player) return states[player] end end
	local function fresh()
		return {skill=0,wins=0,rebirths=0,best=0,stone="Pebble",stones={Pebble=true},trail="None",trails={None=true},pets={},equipped={},world=1,unlockedWorld2=false,
			perks={},receipts={},settings={sound=100,music=100,shake=true,effects=true,hideHUD=false},daily=0}
	end
	local function normalize(data)
		local defaults=fresh()
		if type(data)~="table" then return defaults end
		for key,value in defaults do if type(data[key])~=type(value) then data[key]=value end end
		for _,key in {"skill","wins","rebirths","best"} do data[key]=math.max(0,math.min(data[key],1e15)) end
		data.stones.Pebble=true data.trails.None=true
		if not Config.find(Config.Stones,data.stone) or not data.stones[data.stone] then data.stone="Pebble" end
		if not Config.find(Config.Trails,data.trail) or not data.trails[data.trail] then data.trail="None" end
		local seen={} local clean={}
		for _,id in data.equipped do if type(id)=="string" and not seen[id] then
			for _,pet in data.pets do if pet.uid==id then table.insert(clean,id) seen[id]=true break end end
		end if #clean>=3 then break end end
		data.equipped=clean
		if data.world~=2 then data.world=1 else data.unlockedWorld2=true end
		return data
	end
	local function rootFor(player)
		local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") local hum=char and char:FindFirstChildOfClass("Humanoid")
		return root,hum
	end
	local function standingHeight(root, hum)
		return root.Size.Y / 2 + (hum.RigType == Enum.HumanoidRigType.R6 and 2 or hum.HipHeight)
	end
	local function releasePose(s)
		local pose = s.pose
		if pose then
			if pose.root.Parent then pose.root.Anchored = pose.anchored end
			if pose.hum.Parent then pose.hum.AutoRotate = pose.autoRotate end
			s.pose = nil
		end
	end
	local function stopTraining(player, block)
		local s = states[player] if not s then return end
		if s.activeShot then
			s.activeShot=nil s.busyUntil=0
			FlightStreaming.stop(player)
			effect:FireClient(player,"ShotCancelled")
		end
		if block then s.blockedLane = s.lane end
		s.lane = nil s.trainingStarted = nil s.nextTraining = nil s.trainingHit = nil s.trainingCycle = nil
		local char = player.Character
		if char then char:SetAttribute("TrainingLane", nil) char:SetAttribute("TrainingStarted", nil) end
		releasePose(s)
	end
	local function lockPose(s, root, hum, cf)
		releasePose(s)
		s.pose = {root=root, hum=hum, anchored=root.Anchored, autoRotate=hum.AutoRotate}
		root.AssemblyLinearVelocity = Vector3.zero root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = cf root.Anchored = true hum.AutoRotate = false
	end
	local function startTraining(player, index)
		local s = states[player] local root, hum = rootFor(player)
		if not s or not root or not hum then return end
		local lane = arenaFor(player).TrainingZone["TrainingLane"..index]
		local pad = lane.StartingPad
		local position = Vector3.new(pad.Position.X-1, Config.trainingSurface(lane)+standingHeight(root, hum), pad.Position.Z)
		lockPose(s, root, hum, CFrame.lookAt(position, position + Vector3.xAxis))
		s.lane = index s.trainingStarted = workspace:GetServerTimeNow()
		s.trainingHit = 1 s.trainingCycle = 0
		s.nextTraining = s.trainingStarted + TrainingMotion.hitTime(index,1)
		s.nextPublish = 0
		player.Character:SetAttribute("TrainingLane", index)
		player.Character:SetAttribute("TrainingStarted", s.trainingStarted)
	end
	local function petBoost(data)
		local bonus=0
		for _,id in data.equipped do for _,pet in data.pets do if pet.uid==id then bonus+=math.max(0,(pet.boost or 1)-1) break end end end
		return 1+bonus
	end
	local function friends(player)
		local count=0
		for _,p in Players:GetPlayers() do if p~=player then local ok,result=pcall(player.IsFriendsWith,player,p.UserId) if ok and result then count+=1 end end end
		return count
	end
	local function multiplier(state)
		local d=state.data
		return (1+d.rebirths)*petBoost(d)*BallPurchases.power(d)*(d.perks.DoubleSkill and 2 or 1)*(1+state.friends*0.1)*(d.world==2 and 3 or 1)
	end
	local function inApron(player)
		local p,h=rootFor(player) if not p or not h or h.Health<=0 then return false end
		local apron=arenaFor(player).Lobby.ThrowingApron local point=apron.CFrame:PointToObjectSpace(p.Position)
		return math.abs(point.X)<=apron.Size.X/2 and math.abs(point.Z)<=apron.Size.Z/2+1 and point.Y>=0 and point.Y<12
	end
	local function publish(player,notice)
		local s=states[player] if not s or not player.Parent then return end
		local d=s.data local level,rebirthRequiredLevel,rebirthProgress=Config.rebirthProgress(d.skill,d.rebirths)
		local view=table.clone(d) view.receipts=nil
		local info={data=view,level=level,multiplier=multiplier(s),canThrow=inApron(player) and os.clock()>=s.busyUntil,
			rebirthRequiredLevel=rebirthRequiredLevel,rebirthRequiredSkill=Config.rebirthRequirement(d.rebirths),rebirthProgress=rebirthProgress,rebirthReady=level>=rebirthRequiredLevel,
			training=s.lane,trainingStarted=s.trainingStarted,shotDistance=Config.shotDistance(d.skill,BallPurchases.power(d),d.world,arenaFor(player)),auto=s.auto,friendBoost=s.friends*10,elapsed=math.floor(os.clock()-s.joined),gifts=s.gifts,notice=notice,
			nextLevel=Config.threshold(math.min(level+1,Config.MaxLevel),d.rebirths),levelStart=Config.threshold(level,d.rebirths),sessionOnly=s.sessionOnly,
			isAdmin=AdminAccess.isAuthorized(player.UserId),adminTest=s.adminOriginal~=nil}
		update:FireClient(player,info)
		local leader=player:FindFirstChild("leaderstats") if leader then leader.Skill.Value=math.floor(d.skill) leader.Wins.Value=math.floor(d.wins) leader.Rebirths.Value=d.rebirths end
		player:SetAttribute("SkippingWorld",d.world)
	end
	local function save(player,release)
		local s=states[player] if not s or s.saving then return false end
		local data,sessionOnly=AdminService.persistence(s)
		if sessionOnly then return false end s.saving=true
		local snapshot=HttpService:JSONDecode(HttpService:JSONEncode(data))
		local ok,record=pcall(function() return store:UpdateAsync("u_"..player.UserId,function(old)
			if type(old)=="table" and old.owner and old.owner~=session and (old.expires or 0)>os.time() then return nil end
			local record={data=snapshot,expires=release and 0 or os.time()+180}
			if not release then record.owner=session end
			return record
		end) end)
		s.saving=false if not ok then warn("StoneSkipping save failed: "..tostring(record)) end
		if ok and record~=nil then task.spawn(LobbyRankings.record,player.UserId,snapshot) end
		return ok and record~=nil
	end
	local function setup(player)
		local data=fresh()
		if not RunService:IsStudio() then
			local acquired=false
			for attempt=1,3 do
				local ok,record=pcall(function() return store:UpdateAsync("u_"..player.UserId,function(old)
					if type(old)=="table" and old.owner and old.owner~=session and (old.expires or 0)>os.time() then return nil end
					return {data=normalize(type(old)=="table" and old.data or nil),owner=session,expires=os.time()+180}
				end) end)
				if ok and record and record.owner==session then data=normalize(record.data) acquired=true break end
				task.wait(attempt)
			end
			if not acquired then player:Kick("Your data is still loading. Please rejoin in a moment.") return end
		end
		if not player.Parent then return end
		states[player]={data=data,joined=os.clock(),gifts={},busyUntil=0,lastAction=0,tokens=12,lane=nil,auto=false,friends=friends(player),sessionOnly=RunService:IsStudio()}
		local leader=Instance.new("Folder") leader.Name="leaderstats" leader.Parent=player
		for _,name in {"Skill","Wins","Rebirths"} do local value=Instance.new("NumberValue") value.Name=name value.Parent=leader end
		local function spawn(char)
			FlightStreaming.stop(player)
			local r=char:WaitForChild("HumanoidRootPart",10)
			local hum=char:WaitForChild("Humanoid",10)
			if r and hum then
				hum.WalkSpeed=Config.CharacterWalkSpeed
				r.AssemblyLinearVelocity=Vector3.zero r.AssemblyAngularVelocity=Vector3.zero
				r.CFrame=Config.apronCharacterPose(arenaFor(player),r,hum,3)
			end
			local s=states[player] if s then stopTraining(player) s.blockedLane=nil s.busyUntil=0 end
			if hum then hum.Died:Connect(function() stopTraining(player) FlightStreaming.stop(player) end) end
			publish(player)
		end
		player.CharacterAdded:Connect(spawn) if player.Character then task.spawn(spawn,player.Character) end
		publish(player,"Train on a pad, then THROW your stone!")
	end
	local function throw(player,adminDistance)
		local s=states[player] if not s or os.clock()<s.busyUntil then return end
		if not inApron(player) then publish(player,"Go to the yellow THROW ZONE") return end
		local d=s.data local trail=Config.find(Config.Trails,d.trail)
		if adminDistance then assert(s.adminOriginal,"Test throw requires an admin test session") end
		local distance=adminDistance or Config.shotDistance(d.skill,BallPurchases.power(d),d.world,arenaFor(player))
		local feedback=ShotFeedback.profile(d.skill,BallPurchases.power(d),d.world)
		local duration=Config.shotDuration(distance,d.world,feedback.intensity)
		stopTraining(player)
		local root,hum=rootFor(player) if not root or not hum then return end
		local frame=frameFor(player)
		lockPose(s,root,hum,Config.apronCharacterPose(arenaFor(player),root,hum,-11))
		local startedAt=workspace:GetServerTimeNow()
		local shot={} s.activeShot=shot
		s.busyUntil=os.clock()+Config.KickWindup+duration+0.7
		task.delay(0.9,function() if states[player]==s and s.activeShot==shot and s.pose and s.pose.root==root and not s.lane then releasePose(s) end end)
		local award=math.max(1,math.floor(distance/8))
		award=math.floor(award*trail.boost*(d.perks.DoubleWins and 2 or 1)*(1+s.friends*0.1)*(d.world==2 and 3 or 1))
		local info={userId=player.UserId,distance=distance,duration=duration,feedback=feedback,stone=d.stone,trail=d.trail,world=d.world,startedAt=startedAt,startPosition=frame:PointToWorldSpace(Vector3.new(-115.35,1.8,-0.3)),direction=frame.LookVector,waterY=frame:PointToWorldSpace(Vector3.new(-116,0.82,0)).Y}
		local character=player.Character
		local skillMultiplier=multiplier(s)
		FlightStreaming.start(player,info,function()
			return states[player]==s and s.data==d and player.Character==character and hum.Health>0 and os.clock()<s.busyUntil
		end)
		effect:FireAllClients("Throw",info)
		publish(player)
		for contact=1,ShotMotion.BounceCount do
			task.delay(ShotMotion.contactTime(contact,duration),function()
				if states[player]~=s or s.data~=d or s.activeShot~=shot or player.Character~=character or hum.Health<=0 then return end
				local gain=Config.shotBounceGain(skillMultiplier)
				d.skill+=gain
				effect:FireClient(player,"ShotBounce",{gain=gain,contact=contact,distance=distance*contact/ShotMotion.BounceCount})
				if contact==ShotMotion.BounceCount then
					s.activeShot=nil d.wins+=award d.best=math.max(d.best,distance)
					effect:FireClient(player,"Result",{wins=award,distance=distance})
					publish(player,"+"..Config.format(award).." WINS • "..Config.format(distance).." m")
				else publish(player) end
			end)
		end
	end
	if RunService:IsStudio() then Game.studioThrow=throw Game.studioPublish=publish end
	local function equipBest(d)
		local sorted=table.clone(d.pets) table.sort(sorted,function(a,b) return a.boost>b.boost end) d.equipped={}
		for i=1,math.min(3,#sorted) do table.insert(d.equipped,sorted[i].uid) end
	end
	local function hatch(player,id,count,testing)
		local s=states[player] local d=s.data local egg=Config.find(Config.Eggs,id)
		if not egg then return end count=count==3 and 3 or 1
		if testing then assert(s.adminOriginal,"Test hatching requires an admin test session") end
		local pos=rootFor(player) if not testing and (not pos or (pos.Position-pointFor(player,Vector3.new(egg.x,4,egg.z))).Magnitude>19) then publish(player,"Walk to the "..egg.name) return end
		if os.clock()<s.busyUntil then publish(player,"Wait for your throw to finish") return end
		if #d.pets+count>60 then publish(player,"Pet storage full (60). Delete a pet first.") return end
		local cost=testing and 0 or egg.cost*(d.world==2 and 10 or 1)
		if d.wins<cost*count then publish(player,"Need "..Config.format(cost*count).." Wins") return end
		d.wins-=cost*count local hatched={}
		for _=1,count do
			local chosen=Config.rollEggPet(id)
			local pet={uid=HttpService:GenerateGUID(false),id=chosen.id,name=chosen.name,boost=chosen.boost*egg.boost*(d.world==2 and 3 or 1),rarity=chosen.rarity}
			table.insert(d.pets,pet) table.insert(hatched,pet)
		end
		equipBest(d) effect:FireClient(player,"Hatch",hatched) publish(player)
	end
	local function purchaseItem(player,list,ownedKey,equippedKey,id)
		local s=states[player] local d=s.data local item=Config.find(list,id) if not item then return end
		if not d[ownedKey][id] then if d.wins<item.cost then publish(player,"Need "..Config.format(item.cost).." Wins") return end d.wins-=item.cost d[ownedKey][id]=true end
		d[equippedKey]=id publish(player,item.name.." equipped!")
	end
	local function rebirth(player,skip)
		local s=states[player] if os.clock()<s.busyUntil then publish(player,"Wait for your throw to finish") return false end
		local level=Config.level(s.data.skill,s.data.rebirths)
		if not skip and level<Config.MaxLevel then publish(player,"Reach Level "..Config.MaxLevel.." to rebirth (Level "..level.." now)") return false end
		stopTraining(player,true) s.data.skill=0 s.data.rebirths+=1
		effect:FireClient(player,"Rebirth",{}) publish(player,"REBIRTH! ×"..(s.data.rebirths+1).." SKILL") return true
	end
	action.OnServerEvent:Connect(function(player,command,value,extra)
		local s=states[player] if not s or type(command)~="string" then return end
		local now=os.clock() s.tokens=math.min(12,s.tokens+(now-s.lastAction)*8) s.lastAction=now
		if s.tokens<1 then return end s.tokens-=1
		if command=="Snapshot" then publish(player)
		elseif command=="Throw" then throw(player)
		elseif command=="Auto" then
			if s.data.perks.AutoThrow then s.auto=not s.auto publish(player)
			else publish(player,"Auto Throw unlocks from the shop") end
		elseif command=="StopTraining" then stopTraining(player,true) s.stopUntil=now+0.5 publish(player)
		elseif command=="Rebirth" then rebirth(player,false)
		elseif command=="Stone" and type(value)=="string" then
			if now<s.busyUntil then publish(player,"Wait for your throw to finish")
			else local _,message=BallPurchases.buyOrEquip(s.data,value) publish(player,message) end
		elseif command=="Trail" and type(value)=="string" then purchaseItem(player,Config.Trails,"trails","trail",value)
		elseif command=="Hatch" and type(value)=="string" then hatch(player,value,extra)
		elseif command=="EquipBest" then equipBest(s.data) publish(player)
		elseif command=="UnequipAll" then s.data.equipped={} publish(player)
		elseif (command=="Pet" or command=="DeletePet") and type(value)=="string" then
			for index,pet in s.data.pets do if pet.uid==value then
				local slot=table.find(s.data.equipped,value)
				if command=="DeletePet" then if slot then table.remove(s.data.equipped,slot) end table.remove(s.data.pets,index)
				elseif slot then table.remove(s.data.equipped,slot)
				elseif #s.data.equipped<3 then table.insert(s.data.equipped,value)
				else publish(player,"Equip up to 3 pets") return end
				publish(player) break
			end end
		elseif command=="Gift" and type(value)=="number" and value==math.floor(value) then
			local gift=Config.Gifts[value]
			if gift and not s.gifts[value] and now-s.joined>=gift.time then s.gifts[value]=true s.data.wins+=gift.wins s.data.skill+=gift.skill publish(player,"Gift claimed!") end
		elseif command=="Daily" then
			local day=math.floor(os.time()/86400)
			if s.data.daily<day then s.data.daily=day s.data.wins+=500 s.data.skill+=100 publish(player,"Daily gift: +500 Wins +100 Skill") else publish(player,"Daily gift already claimed") end
		elseif command=="Setting" and type(value)=="string" then
			if (value=="sound" or value=="music") and type(extra)=="number" and extra==extra then s.data.settings[value]=math.clamp(math.floor(extra),0,100)
			elseif (value=="shake" or value=="effects" or value=="hideHUD") and type(extra)=="boolean" then s.data.settings[value]=extra end
			publish(player)
		elseif command=="Product" and type(value)=="string" then
			if s.adminOriginal then publish(player,"Заверши тестовый режим перед покупкой за Robux.") return end
			local product=Config.Products[value] if not product then return end
			if s.data.perks[value] then publish(player,"Already owned") return end
			if product.id==0 then publish(player,"This purchase is not available yet") else MarketplaceService:PromptProductPurchase(player,product.id) end
		elseif command=="UnlockAuto" then
			if s.data.perks.AutoThrow then s.auto=not s.auto elseif s.data.wins>=2500 then s.data.wins-=2500 s.data.perks.AutoThrow=true s.auto=true else publish(player,"Need 2.5K Wins for Auto Throw") return end publish(player)
		end
	end)
	for index,arena in {map,world2} do
		for _,egg in Config.Eggs do
			arena.SkippingWorld["Egg_"..egg.id].EggShell.ProximityPrompt.Triggered:Connect(function(player) if states[player] and arenaFor(player)==arena then effect:FireClient(player,"Egg",egg.id) end end)
		end
		arena.SkippingWorld.World2Portal.PortalField:FindFirstChildWhichIsA("ProximityPrompt",true).Triggered:Connect(function(player)
			local s=states[player] if not s or arenaFor(player)~=arena then return end
			local portalPrompt=arena.SkippingWorld.World2Portal.PortalField:FindFirstChildWhichIsA("ProximityPrompt",true)
			local portalPosition=portalPrompt.Parent:IsA("Attachment") and portalPrompt.Parent.WorldPosition or portalPrompt.Parent.Position
			local root,hum=rootFor(player) if not root or not hum or (root.Position-portalPosition).Magnitude>15 or os.clock()<s.busyUntil then return end
			if index==1 and not s.data.unlockedWorld2 then
				if s.data.wins<100000 then publish(player,"World 2 needs 100K Wins") return end
				s.data.wins-=100000 s.data.unlockedWorld2=true
			end
			stopTraining(player) s.blockedLane=nil s.data.world=index==1 and 2 or 1
			root.AssemblyLinearVelocity=Vector3.zero root.AssemblyAngularVelocity=Vector3.zero
			root.CFrame=Config.apronCharacterPose(arenaFor(player),root,hum,3)
			publish(player,index==1 and "WORLD 2 • ×3 SKILL & WINS" or "Welcome back to World 1") effect:FireClient(player,"World",s.data.world)
		end)
		for _,p in arena.EmptyItemStand:GetDescendants() do
			if p:IsA("ProximityPrompt") and p:GetAttribute("BallId") then
				p.Triggered:Connect(function(player)
					if states[player] and arenaFor(player)==arena then
						local root=rootFor(player)
						if root and (root.Position-p.Parent.Position).Magnitude<=15 then effect:FireClient(player,"OpenBall",p:GetAttribute("BallId")) end
					end
				end)
			end
		end
		arena.SkippingWorld.HackedAdminEgg.ProximityPrompt.Triggered:Connect(function(player) if states[player] and arenaFor(player)==arena then effect:FireClient(player,"AdminEgg",{}) end end)
	end
	MarketplaceService.ProcessReceipt=function(receipt)
		local player=Players:GetPlayerByUserId(receipt.PlayerId) local s=player and states[player]
		if not s or s.adminOriginal then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if s.data.receipts[receipt.PurchaseId] then return save(player,false) and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet end
		local name,product
		for key,p in Config.Products do if p.id>0 and p.id==receipt.ProductId then name=key product=p break end end
		if not product then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if product.skill then s.data.skill+=product.skill
		elseif name=="SkipRebirth" then s.data.skill=0 s.data.rebirths+=1
		elseif name=="StarterPack" then s.data.wins+=10000 s.data.perks.DoubleSkill=true s.data.perks.StarterPack=true
		elseif name=="AdminEgg" then
			local def=Config.AdminPet
			local pet={uid=HttpService:GenerateGUID(false),id=def.id,name=def.name,boost=def.boost,rarity=def.rarity}
			table.insert(s.data.pets,pet) equipBest(s.data)
		else s.data.perks[name]=true end
		s.data.receipts[receipt.PurchaseId]=true
		if not save(player,false) then return Enum.ProductPurchaseDecision.NotProcessedYet end
		if name=="AdminEgg" then effect:FireClient(player,"Hatch",{s.data.pets[#s.data.pets]}) end
		publish(player,"Purchase received!") return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	admin=AdminService.new({states=states,map=map,remotes=remote,effect=effect,publish=publish,
		stopTraining=stopTraining,rootFor=rootFor,arenaFor=arenaFor,fresh=fresh,equipBest=equipBest,hatch=hatch,throw=throw})
	if RunService:IsStudio() then Game.admin=admin end
	Players.PlayerAdded:Connect(function(p) task.spawn(setup,p) end)
	for _,p in Players:GetPlayers() do task.spawn(setup,p) end
	Players.PlayerRemoving:Connect(function(p)
		FlightStreaming.stop(p)
		stopTraining(p)
		admin:restore(p,false) admin.last[p]=nil admin.busy[p]=nil
		local s=states[p] if s then while s.saving do task.wait(0.1) end save(p,true) states[p]=nil end
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			for player,s in states do
				local pos,hum=rootFor(player) local laneIndex=nil
				if pos and hum and hum.Health>0 and os.clock()>=s.busyUntil then
					for i,def in Config.Lanes do
						local pad=arenaFor(player).TrainingZone["TrainingLane"..i].StartingPad local point=pad.CFrame:PointToObjectSpace(pos.Position)
						if math.abs(point.X)<=pad.Size.X/2+1 and math.abs(point.Z)<=pad.Size.Z/2+1 and point.Y>=0 and point.Y<9 then
							if s.data.rebirths>=def.rebirths then laneIndex=i else if os.clock()>(s.lockNotice or 0) then publish(player,"Need "..def.rebirths.." rebirths for this lane") s.lockNotice=os.clock()+4 end end break
						end
					end
				end
				if not laneIndex then s.blockedLane=nil end
				if s.lane and laneIndex~=s.lane then stopTraining(player) end
				if laneIndex and laneIndex~=s.blockedLane and not s.lane and os.clock()>=(s.stopUntil or 0) then startTraining(player,laneIndex) end
				local serverNow=workspace:GetServerTimeNow()
				local contacts=0
				while s.lane and s.nextTraining and serverNow>=s.nextTraining and contacts<8 do
					local cycleGain=Config.Lanes[s.lane].gain*multiplier(s)*7*Config.TrainingCycle/0.8
					local gain,remainder=TrainingMotion.reward(cycleGain,s.lane,s.gainRemainder)
					s.gainRemainder=remainder s.data.skill+=gain
					effect:FireClient(player,"Train",{gain=gain,lane=s.lane,hit=s.trainingHit})
					s.trainingHit+=1 contacts+=1 s.nextPublish=0
					if s.trainingHit>TrainingMotion.hitCount(s.lane) then s.trainingHit=1 s.trainingCycle+=1 end
					s.nextTraining=s.trainingStarted+s.trainingCycle*Config.TrainingCycle+TrainingMotion.hitTime(s.lane,s.trainingHit)
				end
				if s.auto and not laneIndex and inApron(player) and os.clock()>=s.busyUntil then throw(player) end
				if os.clock()>=(s.nextPublish or 0) then s.nextPublish=os.clock()+0.4 publish(player) end
			end
		end
	end)
	task.spawn(function() while true do task.wait(60) for p,s in states do s.friends=friends(p) task.spawn(save,p,false) end end end)
	game:BindToClose(function()
		local pending=0 for p,s in states do pending+=1 task.spawn(function() while s.saving do task.wait(0.1) end admin:restore(p,false) save(p,true) pending-=1 end) end
		local deadline=os.clock()+25 while pending>0 and os.clock()<deadline do task.wait(0.1) end
	end)
	LobbyRankings.start(map,states)
	print("StoneSkipping ready: 7 lanes, 8 biomes, pets, trails, gifts, rebirths")
end
return Game
