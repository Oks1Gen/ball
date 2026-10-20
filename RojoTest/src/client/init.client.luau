local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
task.spawn(function() require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("VolcanicEggVisual")).start() end)
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local UserInputService=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local Debris=game:GetService("Debris")
local Config=require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local TrainingMotion=require(ReplicatedStorage.Shared:WaitForChild("TrainingMotion"))
local TrainingCamera=require(ReplicatedStorage.Shared:WaitForChild("TrainingCamera"))
local Icons=require(script:WaitForChild("Icons"))
local BallVisuals=require(ReplicatedStorage.Shared:WaitForChild("BallVisuals"))
local PetVisuals=require(ReplicatedStorage.Shared:WaitForChild("PetVisuals"))
task.spawn(function()
	game:GetService("ContentProvider"):PreloadAsync({ReplicatedStorage.Shared:WaitForChild("PetTemplates")})
end)
local KickAnimation=require(script:WaitForChild("KickAnimation"))
local FlightVisuals=require(script:WaitForChild("FlightVisuals"))
local CollectionService=game:GetService("CollectionService")
local player=Players.LocalPlayer
local remotes=ReplicatedStorage:WaitForChild("SkippingRemotes")
local action,update,effect=remotes.Action,remotes.Update,remotes.Effect
local C=Color3.fromRGB
local white,dark,yellow=C(255,255,255),C(20,22,33),C(255,225,66)
local latest,currentPanel,flight,modalRefresh=nil,nil,nil,nil
local trainingCamera=nil
local function restoreTrainingCamera()
	if trainingCamera then
		local cam=workspace.CurrentCamera local saved=trainingCamera trainingCamera=nil
		cam.CameraType=saved.cameraType cam.CameraSubject=saved.subject cam.FieldOfView=saved.fov
	end
end
local activeEgg="Common"
local hatchBusy=false
local hudRefs={}
local adminUI
local collectorUI
local gui=Instance.new("ScreenGui") gui.Name="SkippingHUD" gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=20 gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling gui.Parent=player:WaitForChild("PlayerGui")
local canvas=Instance.new("Frame") canvas.Name="Canvas" canvas.AnchorPoint=Vector2.new(0.5,0.5) canvas.Position=UDim2.fromScale(0.5,0.5) canvas.Size=UDim2.fromOffset(1280,720) canvas.BackgroundTransparency=1 canvas.Parent=gui
local scale=Instance.new("UIScale") scale.Parent=canvas
local sidePins={}
local function fit()
	local viewport=workspace.CurrentCamera.ViewportSize
	scale.Scale=math.max(0.01,math.min(viewport.X/1280,viewport.Y/720))
	local gutter=(viewport.X/scale.Scale-1280)/2
	local margin=16/scale.Scale
	for _,pin in sidePins do
		local x=pin.side=="left" and (-gutter+margin+pin.offset) or (1280+gutter-margin+pin.offset)
		local position=pin.node.Position
		pin.node.Position=UDim2.new(0,x,position.Y.Scale,position.Y.Offset)
	end
end
fit() workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
local blur=Instance.new("BlurEffect") blur.Name="SkippingMenuBlur" blur.Size=0 blur.Parent=Lighting
local function corner(obj,radius) local r=Instance.new("UICorner") r.CornerRadius=UDim.new(0,radius) r.Parent=obj return r end
local function stroke(obj,thickness,color) local s=Instance.new("UIStroke") s.Thickness=thickness or 2 s.Color=color or dark s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=obj return s end
local function text(parent,name,value,x,y,w,h,size,color)
	local l=Instance.new("TextLabel") l.Name=name l.Position=UDim2.fromOffset(x,y) l.Size=UDim2.fromOffset(w,h) l.Text=value l.BackgroundTransparency=1
	l.Font=Enum.Font.GothamBlack l.TextSize=size or 24 l.TextColor3=color or white l.TextStrokeColor3=dark l.TextStrokeTransparency=1 l.Parent=parent
	local s=Instance.new("UIStroke") s.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual s.Thickness=(size or 24)>=40 and 3.5 or 2 s.Color=dark s.LineJoinMode=Enum.LineJoinMode.Round s.Parent=l return l
end
local function frame(parent,name,x,y,w,h,color)
	local f=Instance.new("Frame") f.Name=name f.Position=UDim2.fromOffset(x,y) f.Size=UDim2.fromOffset(w,h) f.BackgroundColor3=color or dark f.BorderSizePixel=0 f.Parent=parent return f
end
local function pattern(parent,color)
	local tile=Instance.new("ImageLabel") tile.Name="Studs" tile.Size=UDim2.fromScale(1,1) tile.BackgroundTransparency=1 tile.Image=Config.StudTexture tile.ImageColor3=color or white tile.ImageTransparency=0.52
	tile.ScaleType=Enum.ScaleType.Tile tile.TileSize=UDim2.fromOffset(64,64) tile.ZIndex=parent.ZIndex tile.Parent=parent corner(tile,6) return tile
end
local function icon(parent,kind,x,y,w,h,color)
	local box=frame(parent,kind.."Icon",x,y,w,h) box.BackgroundTransparency=1 Icons.draw(box,kind,color) return box
end
local function petIcon(parent,def,x,y,w,h)
	return PetVisuals.preview(parent,def.visual or def.id,x,y,w,h) or icon(parent,"Pets",x,y,w,h,def.color)
end
local function button(parent,name,value,x,y,w,h,color,size,callback)
	local shadow=frame(parent,name.."Shadow",x,y+4,w,h,C(26,26,34)) shadow.BackgroundTransparency=0.25 corner(shadow,8)
	local b=Instance.new("TextButton") b.Name=name b.Position=UDim2.fromOffset(x,y) b.Size=UDim2.fromOffset(w,h) b.BackgroundColor3=color b.BorderSizePixel=0
	b.Text="" b.AutoButtonColor=false b.Parent=parent corner(b,7) stroke(b,2) pattern(b,color:Lerp(white,0.25))
	local gradient=Instance.new("UIGradient") gradient.Rotation=90 gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,white),ColorSequenceKeypoint.new(0.45,C(246,246,246)),ColorSequenceKeypoint.new(1,C(210,210,210))}) gradient.Parent=b
	local caption=text(b,"Caption",value,4,2,w-8,h-4,size or 26)
	caption.TextScaled=true caption.ZIndex=3
	local limit=Instance.new("UITextSizeConstraint") limit.MinTextSize=10 limit.MaxTextSize=size or 26 limit.Parent=caption
	b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=color:Lerp(white,0.2)}):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.1),{BackgroundColor3=color}):Play() end)
	if callback then b.Activated:Connect(callback) end return b
end
local function send(command,value,extra)
	if player:GetAttribute("MapIntroActive") and command~="Snapshot" then return end
	action:FireServer(command,value,extra)
end
local hud=frame(canvas,"HUD",0,0,1280,720) hud.BackgroundTransparency=1
local toast=text(canvas,"Toast","",330,185,620,44,27,yellow) toast.Visible=false toast.ZIndex=30
local toastId=0
local function notice(message)
	if not message or message=="" then return end toastId+=1 local id=toastId toast.Text=message toast.Visible=true
	task.delay(3,function() if toastId==id then toast.Visible=false end end)
end
local function closePanel()
	if collectorUI then collectorUI:close() collectorUI:setHidden(false) end
	if adminUI then adminUI.close() end
	currentPanel=nil modalRefresh=nil hatchBusy=false
	local existing=canvas:FindFirstChild("Modal") if existing then existing:Destroy() end
	TweenService:Create(blur,TweenInfo.new(0.18),{Size=0}):Play()
	if latest then hud.Visible=not latest.data.settings.hideHUD end
end
local function openCollector(name, kind, eggId)
	closePanel() currentPanel=name hud.Visible=false
	if collectorUI then collectorUI:setHidden(true) end
	TweenService:Create(blur,TweenInfo.new(0.18),{Size=14}):Play()
	collectorUI:setHidden(false) collectorUI:open(kind,eggId)
end
local function shell(name,kind,width,height)
	closePanel() currentPanel=name hud.Visible=false
	if collectorUI then collectorUI:setHidden(true) end
	TweenService:Create(blur,TweenInfo.new(0.18),{Size=22}):Play()
	local modal=frame(canvas,"Modal",(1280-width)/2,(720-height)/2,width,height,C(55,63,79)) modal.BackgroundTransparency=0.3 stroke(modal,2)
	local heading=text(modal,"Heading",name,85,-50,width-170,66,63) heading.ZIndex=10 heading.TextScaled=true
	local headingLimit=Instance.new("UITextSizeConstraint") headingLimit.MinTextSize=24 headingLimit.MaxTextSize=63 headingLimit.Parent=heading
	icon(modal,kind,-15,-54,100,100).ZIndex=10
	local close=button(modal,"Close","",width-32,-31,60,60,C(252,24,68),52,closePanel) close.ZIndex=11
	close.BackgroundTransparency=1 close.Studs.Visible=false close.UIStroke.Enabled=false
	modal.CloseShadow.Visible=false icon(close,"Close",0,0,60,60)
	return modal
end
local function scrolling(modal,y,height)
	local s=Instance.new("ScrollingFrame") s.Name="List" s.Position=UDim2.fromOffset(7,y) s.Size=UDim2.new(1,-14,0,height)
	s.BackgroundTransparency=1 s.BorderSizePixel=0 s.ScrollBarThickness=5 s.ScrollBarImageColor3=yellow s.CanvasSize=UDim2.new() s.AutomaticCanvasSize=Enum.AutomaticSize.Y s.Parent=modal
	local layout=Instance.new("UIListLayout") layout.Padding=UDim.new(0,12) layout.SortOrder=Enum.SortOrder.LayoutOrder layout.Parent=s
	return s
end
local openPanel
local function openTrails() openCollector("Trails","Trails") end
local function openSettings()
	local modal=shell("Settings","Settings",585,474) modal.Position=UDim2.fromOffset(348,123) local toggles={}
	for i,info in {{"Sound Effects","sound"},{"Music","music"},{"Camera Shake","shake"},{"Effects","effects"},{"Hide HUD","hideHUD"}} do
		local row=frame(modal,info[2],14,75+(i-1)*75,556,63,C(48,56,70)) row.BackgroundTransparency=0.2 stroke(row,2)
		text(row,"Name",info[1],12,9,280,42,32).TextXAlignment=Enum.TextXAlignment.Left
		if i<=2 then
			local track=frame(row,"Track",310,25,220,12,C(12,27,30)) stroke(track,2)
			local fill=frame(track,"Fill",0,0,220,12,C(70,236,0))
			local b=button(row,"Volume","100",530,10,31,44,C(100,238,8),17) local value=100
			b.UICorner.CornerRadius=UDim.new(0,1) b.Studs.UICorner.CornerRadius=UDim.new(0,1) row.VolumeShadow.UICorner.CornerRadius=UDim.new(0,1)
			local knobShadow=row:FindFirstChild("VolumeShadow")
			local hit=Instance.new("TextButton") hit.Name="Slider" hit.Position=UDim2.fromOffset(300,7) hit.Size=UDim2.fromOffset(248,50) hit.BackgroundTransparency=1 hit.Text="" hit.Parent=row
			local dragging=false
			local function change(point)
				value=math.clamp(math.floor((point.X-track.AbsolutePosition.X)/track.AbsoluteSize.X*100),0,100)
				fill.Size=UDim2.fromScale(value/100,1) b.Position=UDim2.fromOffset(310+220*value/100,10) b.Caption.Text=tostring(value)
				knobShadow.Position=b.Position+UDim2.fromOffset(0,4)
			end
			hit.InputBegan:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then dragging=true change(input.Position) end end)
			local move=UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then change(input.Position) end end)
			local finish=UserInputService.InputEnded:Connect(function(input) if dragging and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then dragging=false send("Setting",info[2],value) end end)
			modal.Destroying:Connect(function() move:Disconnect() finish:Disconnect() end)
			toggles[info[2]]=function(v) if not dragging then value=v fill.Size=UDim2.fromScale(v/100,1) b.Position=UDim2.fromOffset(310+220*v/100,10) knobShadow.Position=b.Position+UDim2.fromOffset(0,4) b.Caption.Text=tostring(v) end end
		else
			local b=button(row,"Toggle","ON",432,8,112,47,C(66,231,29),28,function() if latest then send("Setting",info[2],not latest.data.settings[info[2]]) end end)
			toggles[info[2]]=function(v) b.Caption.Text=v and "ON" or "OFF" b.BackgroundColor3=v and C(61,229,33) or C(249,61,68) b.Studs.ImageColor3=b.BackgroundColor3 end
		end
	end
	modalRefresh=function() if latest then for key,apply in toggles do apply(latest.data.settings[key]) end end end modalRefresh()
end
local function openRebirth()
	local modal=shell("Rebirth","Rebirth",585,395) modal.Position=UDim2.fromOffset(348,163)
	text(modal,"Before","Before",35,43,240,54,37) text(modal,"After","After",349,43,205,54,37)
	local before=button(modal,"BeforeMultiplier","",20,113,240,73,C(255,217,36),28)
	local after=button(modal,"AfterMultiplier","",333,113,240,73,C(255,217,36),28)
	icon(before,"Skill",14,2,65,67) icon(after,"Skill",14,2,65,67)
	before.Caption.Position=UDim2.fromOffset(88,3) before.Caption.Size=UDim2.fromOffset(143,67)
	after.Caption.Position=UDim2.fromOffset(88,3) after.Caption.Size=UDim2.fromOffset(143,67)
	icon(modal,"Arrow",271,121,60,59)
	text(modal,"Warning","Resets your LEVEL and SKILL!",15,207,555,42,30,C(255,61,74))
	local bar=button(modal,"LevelRequirement","Level 1 / Level "..Config.MaxLevel,58,248,466,57,C(22,160,248),30)
	local actionButton=button(modal,"RebirthAction","Rebirth",121,328,155,53,C(82,232,18),29,function() send("Rebirth") end)
	button(modal,"SkipRebirth","Skip Rebirth",325,328,156,53,C(189,128,238),24,function() send("Product","SkipRebirth") end)
	modalRefresh=function() if latest then
		before.Caption.Text="×"..(latest.data.rebirths+1).."\nSKILL" after.Caption.Text="×"..(latest.data.rebirths+2).."\nSKILL"
		bar.Caption.Text="Level "..latest.level.." / Level "..(latest.rebirthRequiredLevel or Config.MaxLevel)
		local ready=latest.rebirthReady==true
		actionButton.Caption.Text=ready and "Rebirth" or "Need Level "..Config.MaxLevel
		actionButton.BackgroundColor3=ready and C(82,232,18) or C(115,127,143)
		actionButton.Studs.ImageColor3=actionButton.BackgroundColor3
	end end modalRefresh()
end
local function openInventory(selectedId)
	local modal=shell("Balls","Inventory",680,470)
	text(modal,"Description","Buy with Crowns • Boost training and hits",25,32,630,38,23,yellow)
	local scroll=scrolling(modal,80,380) local rows={}
	for i,item in Config.Stones do
		local row=frame(scroll,item.id,0,0,650,92,item.color) row.LayoutOrder=i stroke(row,2) pattern(row,item.color)
		BallVisuals.preview(row,item.id)
		text(row,"Name",item.name,115,7,300,38,29).TextXAlignment=Enum.TextXAlignment.Left
		text(row,"Power","×"..item.power.." Training & Hit Power",115,47,340,30,19,yellow).TextXAlignment=Enum.TextXAlignment.Left
		local b=button(row,"Equip","",461,27,171,42,C(85,233,19),23,function() send("Stone",item.id) end) rows[item.id]={b=b,item=item}
	end
	modalRefresh=function() if latest then for id,row in rows do row.b.Caption.Text=latest.data.stone==id and "Equipped" or latest.data.stones[id] and "Equip" or Config.format(row.item.cost).." Crowns" end end end modalRefresh()
	if selectedId then
		for i,item in Config.Stones do if item.id==selectedId then
			local row=scroll:FindFirstChild(item.id)
			if row then row.UIStroke.Color=yellow row.UIStroke.Thickness=4 end
			task.defer(function() if scroll.Parent then scroll.CanvasPosition=Vector2.new(0,math.max(0,(i-1)*102)) end end)
			break
		end end
	end
end
local function openPets() openCollector("Pets","Pets") end
local function openGifts()
	local modal=shell("Gifts","Gifts",650,455)
	button(modal,"Daily","Daily Gift • +500 Wins",30,37,590,52,C(255,205,48),29,function() send("Daily") end)
	local scroll=scrolling(modal,112,330) local rows={}
	for i,gift in Config.Gifts do
		local row=frame(scroll,"Gift"..i,0,0,620,90,C(63,130,184)) pattern(row) stroke(row,2) icon(row,"Gifts",5,5,75,75)
		text(row,"Reward","+"..Config.format(gift.wins).." Wins",92,7,315,37,28,yellow).TextXAlignment=Enum.TextXAlignment.Left
		text(row,"Skill","+"..Config.format(gift.skill).." Skill",92,48,315,29,23).TextXAlignment=Enum.TextXAlignment.Left
		rows[i]=button(row,"Claim","",441,25,160,44,C(84,235,24),24,function() send("Gift",i) end)
	end
	modalRefresh=function() if latest then for i,b in rows do local remaining=Config.Gifts[i].time-latest.elapsed
		b.Caption.Text=latest.gifts[i] and "Claimed" or remaining<=0 and "Claim" or string.format("%02d:%02d",math.floor(remaining/60),remaining%60)
		b.BackgroundColor3=remaining<=0 and C(84,235,24) or C(90,106,136)
	end end end modalRefresh()
end
local function openShop() openCollector("Shop","Shop") end
local function openEgg(id)
	local egg=Config.find(Config.Eggs,id) if not egg then return end
	activeEgg=id openCollector(egg.name,"Eggs",id)
end
openPanel=function(name)
	if currentPanel==name then closePanel() return end
	if name=="Eggs" then openEgg(activeEgg) return end
	if name=="Trails" then openTrails() elseif name=="Settings" then openSettings() elseif name=="Rebirth" then openRebirth()
	elseif name=="Inventory" then openInventory() elseif name=="Pets" then openPets() elseif name=="Gifts" then openGifts() elseif name=="Shop" then openShop() end
end
collectorUI=require(script.CollectorUI).mount({send=send,close=closePanel,
	open=function(name) if name=="Eggs" and currentPanel==Config.find(Config.Eggs,activeEgg).name then closePanel() else openPanel(name) end end,
	selectEgg=function(id) activeEgg=id currentPanel=Config.find(Config.Eggs,id).name end})
-- Legacy stats continue to update without a second navigation surface.
hudRefs.rebirthPercent=text(hud,"RebirthProgress","0%",0,0,1,1,17)
hudRefs.rebirthPercent.Visible=false
script.Destroying:Connect(function() collectorUI:destroy() end)

local auto=button(hud,"AutoThrow","AUTO THROW",564,43,152,43,C(204,37,62),19,function() if latest and latest.data.perks.AutoThrow then send("Auto") else openPanel("Shop") end end)
auto.Caption.Position=UDim2.fromOffset(3,7) auto.Caption.Size=UDim2.fromOffset(146,25) icon(auto,"Wins",55,-15,43,31) text(auto,"Price","ONLY ◉ 25",9,30,133,17,14,yellow)
local settings=button(canvas,"Settings","",160,60,29,29,C(37,47,58),16,function() openPanel("Settings") end) icon(settings,"Settings",3,3,23,23)
local starter=button(hud,"StarterPack","",1080,201,119,83,C(250,201,60),18,function() send("Product","StarterPack") end)
starter.BackgroundTransparency=1 starter.Studs.Visible=false starter.UIStroke.Enabled=false
hud:FindFirstChild("StarterPackShadow").Visible=false
icon(starter,"Pets",24,5,63,59,C(173,107,248)) icon(starter,"Skill",1,-1,37,56) icon(starter,"Rebirth",77,-2,38,39) text(starter,"Caption2","STARTER PACK",3,69,113,16,12)
local skillOffer=button(hud,"DoubleSkill","+2× SKILL",1080,303,125,53,C(164,233,35),23,function() send("Product","DoubleSkill") end)
skillOffer.Caption.Position=UDim2.fromOffset(3,12) skillOffer.Caption.Size=UDim2.fromOffset(119,25) icon(skillOffer,"Skill",50,-13,39,37) text(skillOffer,"Price","ONLY ◉ 5",4,42,117,15,14,yellow)
local winsOffer=button(hud,"DoubleWins","2× WINS",1080,366,125,53,C(255,196,56),23,function() send("Product","DoubleWins") end)
winsOffer.Caption.Position=UDim2.fromOffset(3,9) winsOffer.Caption.Size=UDim2.fromOffset(119,27) text(winsOffer,"Price","ONLY ◉ 59",4,42,117,15,14,yellow)
local throwButton=button(hud,"Throw","THROW",577,406,126,51,C(112,237,10),29,function() send("Throw") end)
local stopButton=button(hud,"StopTraining","STOP TRAINING",533,205,214,51,C(251,65,77),25,function() send("StopTraining") end) stopButton.Visible=false
local skillText=text(hud,"Skill","0 SKILL",377,482,279,30,22,yellow) skillText.TextXAlignment=Enum.TextXAlignment.Left icon(hud,"Skill",345,479,31,39)
local multiText=text(hud,"Multiplier","×1 Multiplier",774,482,205,30,22,yellow) multiText.TextXAlignment=Enum.TextXAlignment.Left
local levelBase=button(hud,"LevelBar","",344,528,592,61,C(15,161,244),30) levelBase.Active=false
local levelFill=frame(levelBase,"Progress",0,0,592,61,C(15,139,232)) corner(levelFill,5) pattern(levelFill,C(80,223,255))
local levelText=text(levelBase,"Level","Level 1",14,4,260,50,29) levelText.TextXAlignment=Enum.TextXAlignment.Left
local maxText=text(levelBase,"Maximum","0 / 2",303,8,271,43,23) maxText.TextXAlignment=Enum.TextXAlignment.Right
for i,offer in {{"+10M","Skill10M",C(255,205,57)},{"+100M","Skill100M",C(250,98,100)},{"+1B","Skill1B",C(174,111,239)}} do
	local b=button(hud,offer[2],offer[1],344+(i-1)*199,600,193,53,offer[3],30,function() send("Product",offer[2]) end)
	icon(b,"Skill",72,-7,40,67) b.Caption.ZIndex=3 text(b,"Price","◉ "..Config.Products[offer[2]].price,117,44,73,23,18,C(142,255,51))
end
icon(hud,"Rebirth",79,554,40,40) local rebirthText=text(hud,"RebirthCount","0",128,556,110,34,31,C(139,233,255)) rebirthText.TextXAlignment=Enum.TextXAlignment.Left
icon(hud,"Wins",78,601,42,43) local winsText=text(hud,"WinsCount","0",128,601,200,44,34,yellow) winsText.TextXAlignment=Enum.TextXAlignment.Left
local friendText=text(hud,"FriendBoost","Friend Boost +0%",74,654,183,27,18) friendText.TextXAlignment=Enum.TextXAlignment.Left
local distanceText=text(hud,"Distance","",414,96,452,46,31,yellow)
local powerText=text(hud,"HitDistance","HIT: 60 m",425,153,430,27,20,C(225,255,255))
local bestText=text(hud,"Best","",980,666,280,26,16) bestText.TextXAlignment=Enum.TextXAlignment.Right
local tutorial=text(hud,"Hint","Walk onto a training pad to gain Skill",360,680,560,24,16) tutorial.TextTransparency=0.15
-- Anchor both side columns to the viewport, including on wider aspect ratios.
for _,name in {"Shop","Rebirth","Pets","Trails","Inventory","Gifts","RebirthIcon","WinsIcon","RebirthCount","WinsCount","FriendBoost"} do
	local node=hud:FindFirstChild(name)
	if node then table.insert(sidePins,{node=node,side="left",offset=node.Position.X.Offset-75}) end
	local shadow=hud:FindFirstChild(name.."Shadow")
	if shadow then table.insert(sidePins,{node=shadow,side="left",offset=shadow.Position.X.Offset-75}) end
end
for _,name in {"StarterPack","DoubleSkill","DoubleWins"} do
	local node=hud:FindFirstChild(name)
	if node then table.insert(sidePins,{node=node,side="right",offset=node.Position.X.Offset-1205}) end
	local shadow=hud:FindFirstChild(name.."Shadow")
	if shadow then table.insert(sidePins,{node=shadow,side="right",offset=shadow.Position.X.Offset-1205}) end
end
table.insert(sidePins,{node=bestText,side="right",offset=-280})
fit()
-- All rewards are determined by the server. These objects are local visual effects.
local effectsFolder=Instance.new("Folder") effectsFolder.Name="SkippingClientEffects" effectsFolder.Parent=workspace
local function makePart(name,size,color,parent)
	local p=Instance.new("Part") p.Name=name p.Size=size p.Color=color p.Anchored=true p.CanCollide=false p.CanTouch=false p.CanQuery=false p.Material=Enum.Material.SmoothPlastic p.Parent=parent or effectsFolder return p
end
local function ripple(pos,color,scale)
	if latest and not latest.data.settings.effects then return end
	scale=scale or 1
	local p=makePart("Splash",Vector3.new(0.1,1,1),color or C(220,255,255)) p.Shape=Enum.PartType.Cylinder p.CFrame=CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2) p.Transparency=0.4
	TweenService:Create(p,TweenInfo.new(0.5),{Size=Vector3.new(0.02,7*scale,7*scale),Transparency=1}):Play() Debris:AddItem(p,0.6)
end
local function floatingGain(gain)
	if currentPanel or (latest and latest.data.settings.hideHUD) then return end
	local t=text(canvas,"SkillGain","+"..Config.format(gain),560+math.random(-100,100),340,160,45,30,yellow) t.ZIndex=25
	icon(t,"Skill",-22,4,30,36) TweenService:Create(t,TweenInfo.new(0.9),{Position=t.Position-UDim2.fromOffset(0,70),TextTransparency=1}):Play() Debris:AddItem(t,1)
end
local function petModel(def)
	local imported=PetVisuals.follower(def.visual or def.id)
	if imported then imported.Parent=effectsFolder return imported end
	local m=Instance.new("Model") m.Name="Pet_"..def.id local body=makePart("Body",Vector3.new(2.4,2.2,2.2),def.color,m)
	local function piece(name,size,pos,color) local p=makePart(name,size,color,m) p.Position=pos return p end
	local earHeight=def.id=="Bunny" and 2.2 or 0.7
	for _,side in {-1,1} do
		piece("Ear",Vector3.new(0.6,earHeight,0.6),Vector3.new(side*0.8,1+earHeight/2,0),def.color)
		local eye=piece("Eye",Vector3.new(0.55,0.7,0.13),Vector3.new(side*0.55,0.22,-1.13),white) eye.Shape=Enum.PartType.Ball
		local pupil=piece("Pupil",Vector3.new(0.24,0.4,0.12),Vector3.new(side*0.55,0.16,-1.22),dark) pupil.Shape=Enum.PartType.Ball
	end
	piece("Nose",Vector3.new(0.3,0.2,0.14),Vector3.new(0,-0.3,-1.16),C(105,66,59))
	if def.id=="Dragon" then for _,side in {-1,1} do local wing=piece("Wing",Vector3.new(1.5,0.2,1.8),Vector3.new(side*1.8,0.3,0.4),def.color:Lerp(white,0.25)) wing.CFrame*=CFrame.Angles(0,0,side*0.4) end end
	m.PrimaryPart=body m:ScaleTo(PetVisuals.FollowerBodyWidth/body.Size.X) m.Parent=effectsFolder return m
end
local petFollowers={} local petSignature="" local petRowWidth=0
local function refreshPets(data)
	local signature=table.concat(data.equipped,",") if signature==petSignature then return end petSignature=signature
	for _,m in petFollowers do m:Destroy() end petFollowers={}
	for _,id in data.equipped do for _,pet in data.pets do if pet.uid==id then table.insert(petFollowers,petModel(Config.pet(pet.id))) break end end end
	petRowWidth=math.max(0,#petFollowers-1)*.65
	for _,m in petFollowers do
		local _,size=m:GetBoundingBox()
		m:SetAttribute("FollowerWidth",size.X) m:SetAttribute("FollowerHeight",size.Y)
		petRowWidth+=size.X
	end
end
local playSound
local function beginThrow(info)
	KickAnimation.play(info.userId,info.startedAt or workspace:GetServerTimeNow())
	local me=info.userId==player.UserId
	local token={}
	if me then restoreTrainingCamera() closePanel() flight=token powerText.Visible=false collectorUI:setHidden(true) end
	local saved=FlightVisuals.start(info,{
		me=me,active=function() return flight==token end,
		effects=function() return not latest or latest.data.settings.effects end,
		shake=function() return latest and latest.data.settings.shake end,
		ripple=ripple,distance=function(value) distanceText.Text=value end,
		kick=function(feedback) playSound("rbxasset://sounds/action_jump.mp3",feedback.kickVolume,feedback.kickPlayback) end,
		finish=function() flight=nil distanceText.Text="" powerText.Visible=true end,
	})
	token.saved=saved
end
local function hatchAnimation(pets)
	if hatchBusy then return end
	closePanel() hatchBusy=true currentPanel="Hatch" hud.Visible=false
	TweenService:Create(blur,TweenInfo.new(0.2),{Size=18}):Play()
	collectorUI:setHidden(false) collectorUI:hatch(pets)
end
local trainingStone=nil
effect.OnClientEvent:Connect(function(kind,info)
	if kind=="Throw" then beginThrow(info)
	elseif kind=="ShotBounce" then floatingGain(info.gain)
	elseif kind=="Train" then floatingGain(info.gain)
		if not trainingStone then
			trainingStone=BallVisuals.create(latest and latest.data.stone or "Pebble",1.6)
			trainingStone.Name="PracticeBall"
			trainingStone.Parent=workspace
		end
	elseif kind=="Result" then notice("+"..Config.format(info.wins).." WINS • "..Config.format(info.distance).." m")
	elseif kind=="Hatch" then task.spawn(hatchAnimation,info)
	elseif kind=="Egg" then openEgg(info)
	elseif kind=="AdminEgg" then
		local modal=shell("Volcanic Inferno Egg","Egg",620,385)
		icon(modal,"Pets",210,65,200,195,Config.AdminPet.color)
		text(modal,"PetName","Glitched Dragon • MYTHIC",20,30,580,37,27,Config.AdminPet.color)
		text(modal,"Boost","×25 Skill",180,252,260,41,29,yellow)
		button(modal,"BuyAdmin","Hatch • 175 Robux",143,312,334,49,C(94,238,22),27,function() send("Product","AdminEgg") end)
	elseif kind=="Open" then openPanel(info)
	elseif kind=="OpenBall" then openInventory(info)
	elseif kind=="Rebirth" then notice("REBIRTH! Your skill multiplier increased!") closePanel()
	elseif kind=="AdminResetView" or kind=="ShotCancelled" then
		restoreTrainingCamera()
		if flight then
			local saved=flight.saved
			if saved and saved.cancel then saved.cancel() end
			flight=nil local camera=workspace.CurrentCamera camera.CameraType=saved and saved.cameraType or Enum.CameraType.Custom
			camera.CameraSubject=player.Character and player.Character:FindFirstChildWhichIsA("Humanoid") camera.FieldOfView=saved and saved.fov or 70
			if saved then camera.CFrame=saved.cframe end
			distanceText.Text="" powerText.Visible=true
		end
	elseif kind=="World" then notice(info==2 and "WORLD 2 • ×3 SKILL & WINS" or "Welcome back to World 1") end
end)
update.OnClientEvent:Connect(function(info)
	if not info.training then restoreTrainingCamera() end
	latest=info if adminUI then adminUI.update(info) end
	collectorUI:update(info)
	collectorUI:setHidden(flight~=nil or (currentPanel~=nil and currentPanel~="Pets" and currentPanel~="Trails" and currentPanel~="Shop" and currentPanel~="Hatch" and currentPanel~=Config.find(Config.Eggs,activeEgg).name))
	local d=info.data skillText.Text=Config.format(d.skill).." SKILL" multiText.Text="×"..string.format("%.2f",info.multiplier).." Multiplier"
	levelText.Text="Level "..info.level maxText.Text=info.level==Config.MaxLevel and "MAX LEVEL" or Config.format(d.skill-info.levelStart).." / "..Config.format(info.nextLevel-info.levelStart)
	local progress=info.level==Config.MaxLevel and 1 or math.clamp((d.skill-info.levelStart)/math.max(1,info.nextLevel-info.levelStart),0,1)
	TweenService:Create(levelFill,TweenInfo.new(0.3),{Size=UDim2.fromOffset(math.max(4,592*progress),61)}):Play()
	rebirthText.Text=tostring(d.rebirths) winsText.Text=Config.format(d.wins) friendText.Text="Friend Boost +"..info.friendBoost.."%"
	powerText.Text="HIT: "..Config.format(info.shotDistance or Config.shotDistance(d.skill,1,d.world)).." m" powerText.Visible=not flight
	bestText.Text=d.best>0 and "BEST: "..Config.format(d.best).." m" or "" hudRefs.rebirthPercent.Text=math.floor((info.rebirthProgress or 0)*100).."%"
	throwButton.Visible=info.canThrow and not flight and not info.training stopButton.Visible=info.training~=nil
	local throwShadow=hud:FindFirstChild("ThrowShadow") if throwShadow then throwShadow.Visible=throwButton.Visible end
	local stopShadow=hud:FindFirstChild("StopTrainingShadow") if stopShadow then stopShadow.Visible=stopButton.Visible end
	auto.Caption.Text=info.auto and "AUTO: ON" or "AUTO THROW" hud.Visible=currentPanel==nil and not d.settings.hideHUD
	tutorial.Visible=not flight tutorial.Text=info.training and "Training! STOP TRAINING or jump to leave" or (info.canThrow and "Press E to kick • Train to increase hit distance" or "Walk onto a training pad to gain Skill")
	if trainingStone and not info.training then trainingStone:Destroy() trainingStone=nil end
	if trainingStone and trainingStone:GetAttribute("BallId")~=d.stone then trainingStone:Destroy() trainingStone=nil end
	if info.training and not trainingStone then trainingStone=BallVisuals.create(d.stone,1.6) trainingStone.Name="PracticeBall" trainingStone.Parent=workspace end
	if modalRefresh then modalRefresh() end refreshPets(d) notice(info.notice)
end)
local musicGroup=Instance.new("SoundGroup") musicGroup.Name="SkippingMusic" musicGroup.Parent=SoundService
local effectsGroup=Instance.new("SoundGroup") effectsGroup.Name="SkippingSounds" effectsGroup.Parent=SoundService
local music=Instance.new("Sound") music.Name="PlayfulTropicalHouse" music.SoundId=Config.Music music.Volume=0.12 music.Looped=true music.SoundGroup=musicGroup music.Parent=SoundService music:Play()
playSound=function(id,volume,speed)
	if latest and latest.data.settings.sound==0 then return end
	local sound=Instance.new("Sound") sound.SoundId=id sound.Volume=volume or 0.3 sound.PlaybackSpeed=speed or 1 sound.SoundGroup=effectsGroup sound.Parent=SoundService sound:Play() Debris:AddItem(sound,3)
end
effect.OnClientEvent:Connect(function(kind)
	if kind=="Result" or kind=="Hatch" or kind=="Rebirth" then playSound("rbxasset://sounds/volume_slider.ogg",0.25,1.4) end
end)
local heldStone=BallVisuals.create("Pebble",1.1)
heldStone.Name="HeldBall"
heldStone.Parent=workspace
local portalBeams={}
local waterTextures={}
task.spawn(function()
	for _,name in {"ProgressionMap","World2Map"} do
		local map=workspace:WaitForChild(name) local world=map:WaitForChild("SkippingWorld")
		for _,p in world.World2Portal:GetChildren() do if p:IsA("BasePart") and p:GetAttribute("AnimatedPortal") then table.insert(portalBeams,p) end end
		for _,p in world:GetChildren() do local t=p:FindFirstChild("WaterCaustics") if t and not p:GetAttribute("FootballPitch") then table.insert(waterTextures,t) end end
	end
end)
RunService.RenderStepped:Connect(function(dt)
	local now=os.clock() local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local hum=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if latest and latest.training and root and hum and hum.Health>0 and not flight then
		local cam=workspace.CurrentCamera
		if not trainingCamera then trainingCamera={cameraType=cam.CameraType,subject=cam.CameraSubject,fov=cam.FieldOfView} end
		cam.CameraType=Enum.CameraType.Scriptable
		local map=workspace:FindFirstChild(latest.data.world==2 and "World2Map" or "ProgressionMap")
		local lane=map and map.TrainingZone:FindFirstChild("TrainingLane"..latest.training)
		if lane then
			local target=TrainingCamera.pose(lane,root.Position,cam.ViewportSize)
			local blend=1-math.exp(-dt*7)
			cam.CFrame=cam.CFrame:Lerp(target,blend)
			cam.FieldOfView+=(TrainingCamera.FieldOfView-cam.FieldOfView)*blend
		end
	elseif trainingCamera then restoreTrainingCamera() end
	for i,beam in portalBeams do beam.Transparency=(latest and latest.data.settings.effects) and (0.2+0.5*(0.5+0.5*math.sin(now*4+i))) or 0.7 end
	for _,t in waterTextures do t.OffsetStudsU=now*0.45 t.OffsetStudsV=now*0.25 end
	local hand=player.Character and (player.Character:FindFirstChild("RightHand") or player.Character:FindFirstChild("Right Arm"))
	if latest and heldStone:GetAttribute("BallId")~=latest.data.stone then
		heldStone:Destroy() heldStone=BallVisuals.create(latest.data.stone,1.1)
		heldStone.Name="HeldBall" heldStone.Parent=workspace
	end
	if hand and latest then heldStone:PivotTo(hand.CFrame*CFrame.new(0,-0.4,-0.2)) end
	BallVisuals.visible(heldStone,hand~=nil and latest~=nil and not flight and not latest.training)
	for _,model in CollectionService:GetTagged("BallStandPreview") do
		if model:IsA("Model") and model:IsDescendantOf(workspace) then
			local base=model:GetAttribute("DisplayBasePivot")
			if base and workspace.CurrentCamera and (workspace.CurrentCamera.CFrame.Position-base.Position).Magnitude<250 then
				local pose,bob=BallVisuals.standPose(base,workspace:GetServerTimeNow(),(model:GetAttribute("DisplaySlot") or 1)*0.55)
				model:PivotTo(pose)
				local link=model:FindFirstChild("DisplayLabel")
				if link and link.Value then link.Value.Position=model:GetAttribute("DisplayLabelBase")+Vector3.new(0,bob,0) end
			end
		end
	end
	if root then
		local edge=-petRowWidth/2
		for i,m in petFollowers do
			local width=m:GetAttribute("FollowerWidth")
			local x=edge+width/2 edge+=width+.65
			local y=math.sin(now*3+i)*.25-.9+(m:GetAttribute("FollowerHeight")-2.8)/2
			local target=root.CFrame*CFrame.new(x,y,4.5)
			m:PivotTo(m:GetPivot():Lerp(target,.13))
		end
	end
	if trainingStone and latest and latest.training and root then
		local map=workspace:FindFirstChild(latest.data.world==2 and "World2Map" or "ProgressionMap")
		local lane=map and map.TrainingZone:FindFirstChild("TrainingLane"..latest.training)
		local started=player.Character:GetAttribute("TrainingStarted") or latest.trainingStarted
		if lane and started then
			local phase=(workspace:GetServerTimeNow()-started)%Config.TrainingCycle
			local radius=0.8
			local start=Vector3.new(root.Position.X+2.2,Config.trainingSurface(lane)+radius,root.Position.Z+0.65)
			local target=Vector3.new(lane.TrainingStrip.Position.X+lane.TrainingStrip.Size.X/2-2,start.Y,start.Z)
			local position=TrainingMotion.position(start,target,phase,latest.training)
			trainingStone:PivotTo(CFrame.new(position)*CFrame.Angles(0,0,-(position.X-start.X)/radius))
			BallVisuals.visible(trainingStone,phase<1.15)
		end
	end
	if latest then effectsGroup.Volume=latest.data.settings.sound/100 musicGroup.Volume=latest.data.settings.music/100 end
end)
UserInputService.InputBegan:Connect(function(input,processed)
	if processed or player:GetAttribute("MapIntroActive") then return end
	if input.KeyCode==Enum.KeyCode.Escape and currentPanel then hatchBusy=false closePanel()
	elseif currentPanel=="Volcanic Inferno Egg" and input.KeyCode==Enum.KeyCode.E then send("Product","AdminEgg")
	elseif currentPanel==Config.find(Config.Eggs,activeEgg).name and input.KeyCode==Enum.KeyCode.E then collectorUI:request("Hatch",activeEgg,1)
	elseif currentPanel==Config.find(Config.Eggs,activeEgg).name and input.KeyCode==Enum.KeyCode.R then collectorUI:request("Hatch",activeEgg,3)
	elseif not currentPanel and latest and latest.canThrow and (input.KeyCode==Enum.KeyCode.E or input.KeyCode==Enum.KeyCode.ButtonX) then send("Throw")
	elseif input.KeyCode==Enum.KeyCode.G then openPanel("Gifts") end
end)
UserInputService.JumpRequest:Connect(function() if latest and latest.training then send("StopTraining") end end)
player.CharacterAdded:Connect(function() restoreTrainingCamera() if flight then flight=nil workspace.CurrentCamera.CameraType=Enum.CameraType.Custom workspace.CurrentCamera.FieldOfView=70 distanceText.Text="" end end)
adminUI=require(script.AdminPanel).mount({frame=frame,text=text,button=button,corner=corner,stroke=stroke,pattern=pattern,petPreview=petIcon,closePanel=closePanel,
	activate=function()
		closePanel() currentPanel="Admin" hud.Visible=false collectorUI:setHidden(true)
		TweenService:Create(blur,TweenInfo.new(.18),{Size=16}):Play()
	end})
if latest then adminUI.update(latest) end
send("Snapshot")
print("StoneSkipping HUD ready")

