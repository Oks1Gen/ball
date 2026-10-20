local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local TextService=game:GetService("TextService")
local Config=require(game.ReplicatedStorage.Shared.GameConfig)
local PetVisuals=require(game.ReplicatedStorage.Shared.PetVisuals)
local Panel={}
local C=Color3.fromRGB
local purple,blue,green=C(158,99,238),C(42,157,222),C(91,220,40)

function Panel.mount(context)
	local gui=Instance.new("ScreenGui") gui.Name="AdminTools" gui.ResetOnSpawn=false gui.IgnoreGuiInset=true gui.DisplayOrder=35 gui.Parent=Players.LocalPlayer.PlayerGui
	local frame,text,button=context.frame,context.text,context.button
	local authorized,testing,busy=false,false,false
	local window,statusLabel,summary,modeButton,body=nil,nil,nil,nil,nil
	local status,rows,tab={},nil,"Проверки"
	local selectedEgg="Uncommon"
	local clientLogs={}
	game:GetService("LogService").MessageOut:Connect(function(message,kind)
		if kind==Enum.MessageType.MessageError or kind==Enum.MessageType.MessageWarning then
			table.insert(clientLogs,{ok=false,title=os.date("%H:%M:%S").." · "..kind.Name,detail=message:sub(1,500)})
			if #clientLogs>30 then table.remove(clientLogs,1) end
		end
	end)
	local width,height,bodyWidth=980,620,948
	local build,renderPage,request,open
	local launcher=button(gui,"AdminLauncher","ADMIN · F2",16,112,150,38,purple,19,function() open() end)
	launcher.Visible=false gui.AdminLauncherShadow.Visible=false
	local indicator=text(gui,"TestIndicator","ТЕСТОВЫЙ РЕЖИМ · F2",0,6,430,30,19,C(255,222,81))
	indicator.AnchorPoint=Vector2.new(.5,0) indicator.Position=UDim2.new(.5,0,0,6) indicator.Visible=false
	local function close()
		if window then window:Destroy();window=nil end
		launcher.Visible=authorized gui.AdminLauncherShadow.Visible=authorized
	end
	local function refreshSummary()
		indicator.Visible=authorized and testing
		if not window then return end
		modeButton.Caption.Text=testing and "Завершить тест" or "Начать тест"
		window.Mode.Text=testing and "Тестовая копия прогресса" or "Основной прогресс защищён"
		summary.Text=string.format("Мир %s · Wins %s · Skill %s · RB %s · Петов %s/60",status.world or 1,Config.format(status.wins or 0),Config.format(status.skill or 0),status.rebirths or 0,status.pets or 0)
	end
	request=function(command,value)
		if command=="ClientLogs" then
			rows={} for i=#clientLogs,1,-1 do table.insert(rows,clientLogs[i]) end
			if #rows==0 then rows={{ok=true,title="Ошибок клиента нет",detail="Журнал собирается с момента загрузки панели."}} end
			renderPage() statusLabel.Text="Журнал клиента." return
		end
		if busy then return end busy=true
		if statusLabel and statusLabel.Parent then statusLabel.Text="Выполняется…" end
		task.spawn(function()
			local ok,result=pcall(function() return game.ReplicatedStorage.SkippingRemotes.Admin:InvokeServer(command,value) end)
			busy=false
			if not ok then result={ok=false,message="Нет ответа сервера. Повтори команду."} end
			if result.status then status=result.status testing=status.testing end
			if result.rows then rows=result.rows end
			refreshSummary()
			if window and window.Parent then
				statusLabel.Text=result.message or "Готово."
				statusLabel.TextColor3=result.ok and C(183,240,161) or C(255,165,135)
				if command=="Diagnostics" or command=="Logs" then renderPage() end
			end
		end)
	end
	local function grid(items,y,minWidth,cellHeight)
		local columns=math.max(1,math.floor((bodyWidth+10)/(minWidth+10)))
		local cellWidth=(bodyWidth-(columns-1)*10)/columns
		for i,item in items do
			local x=((i-1)%columns)*(cellWidth+10) local row=math.floor((i-1)/columns)
			button(body,"Action"..i.."_"..y,item.label,x,y+row*(cellHeight+10),cellWidth,cellHeight,item.color or blue,18,function() request(item.command,item.value) end)
		end
		return y+math.ceil(#items/columns)*(cellHeight+10)
	end
	local function label(value,y)
		text(body,"Section"..y,value,2,y,bodyWidth-4,28,20).TextXAlignment=Enum.TextXAlignment.Left
		return y+36
	end
	renderPage=function()
		if not body or not body.Parent then return end
		for _,child in body:GetChildren() do child:Destroy() end
		local y=4
		if tab=="Проверки" then
			y=grid({{label="Запустить проверки",command="Diagnostics",color=green},{label="Обновить данные",command="Status"},{label="Ошибки сервера",command="Logs",color=purple},{label="Ошибки клиента",command="ClientLogs",color=purple}},y,210,42)
			if not rows then
				rows={{ok=true,title="Проверяй изменения в тестовой копии",detail="Включи тестовый режим. Валюта, питомцы, открытия и результаты бросков вернутся к исходным после завершения теста."},
					{ok=true,title="Что проверяет панель",detail="Стыки и опоры биомов, состав яиц, модели петов, тренировочные площадки, мячи, арку, дальность и ID покупок."}}
			end
			for i,row in rows do
				local title=(row.ok and "ОК · " or "ВНИМАНИЕ · ")..row.title
				local th=TextService:GetTextSize(title,18,Enum.Font.GothamBlack,Vector2.new(bodyWidth-24,10000)).Y
				local dh=TextService:GetTextSize(row.detail,16,Enum.Font.GothamBlack,Vector2.new(bodyWidth-24,10000)).Y
				local h=th+dh+22 local card=frame(body,"Check"..i,0,y,bodyWidth,h,C(40,48,64));context.corner(card,6)
				local heading=text(card,"Title",title,10,5,bodyWidth-20,th+3,18,row.ok and C(163,235,132) or C(255,197,102));heading.TextWrapped=true heading.TextXAlignment=Enum.TextXAlignment.Left
				local detail=text(card,"Detail",row.detail,10,th+12,bodyWidth-20,dh+3,16,C(224,232,241));detail.TextWrapped=true detail.TextXAlignment=Enum.TextXAlignment.Left
				y+=h+9
			end
		elseif tab=="Прогресс" then
			local columns=bodyWidth>=700 and 3 or 1 local cw=(bodyWidth-(columns-1)*12)/columns
			for i,field in {{"wins","Wins"},{"skill","Skill"},{"rebirths","Rebirths"}} do
				local x=((i-1)%columns)*(cw+12) local top=y+math.floor((i-1)/columns)*101
				text(body,"Stat"..field[1],field[2],x,top,cw,27,21).TextXAlignment=Enum.TextXAlignment.Left
				local input=Instance.new("TextBox") input.Name="Input_"..field[1];input.Position=UDim2.fromOffset(x,top+33);input.Size=UDim2.fromOffset(cw-112,40)
				input.BackgroundColor3=C(32,40,57) input.TextColor3=Color3.new(1,1,1) input.Text=tostring(status[field[1]] or 0) input.Font=Enum.Font.GothamBlack input.TextSize=18 input.ClearTextOnFocus=false input.Parent=body context.corner(input,6)
				button(body,"Set"..field[1],"Задать",x+cw-104,top+33,104,40,blue,17,function() request("SetStat",{key=field[1],amount=input.Text}) end)
			end
			y+=math.ceil(3/columns)*101
			y=grid({{label="Wins: 100K",command="SetStat",value={key="wins",amount=100000}},{label="Skill: 1M",command="SetStat",value={key="skill",amount=1000000}},
				{label="Rebirths: 16",command="SetStat",value={key="rebirths",amount=16}},{label="Открыть всё",command="Unlock",color=green},{label="Сбросить тест",command="Reset",color=purple}},y,170,42)
			y=label("Проверка броска",y+8)
			y=grid({{label="Бросок: 60 м",command="Throw",value=60},{label="Бросок: 629 м",command="Throw",value=629},{label="Максимальный бросок",command="Throw",value="max",color=green}},y,210,42)
		elseif tab=="Петы / яйца" then
			local egg=Config.find(Config.Eggs,selectedEgg) or Config.Eggs[1]
			selectedEgg=egg.id
			local eggColumns=math.max(1,math.min(#Config.Eggs,math.floor((bodyWidth+10)/155)))
			local eggWidth=(bodyWidth-(eggColumns-1)*10)/eggColumns
			for i,option in Config.Eggs do
				button(body,"SelectEgg_"..option.id,option.name,((i-1)%eggColumns)*(eggWidth+10),y+math.floor((i-1)/eggColumns)*48,eggWidth,38,option.id==selectedEgg and purple or blue,18,function()
					selectedEgg=option.id renderPage()
				end)
			end
			y+=math.ceil(#Config.Eggs/eggColumns)*48
			local worldBoost=status.world==2 and 3 or 1
			y=label(egg.name.." · "..Config.format(egg.cost*(status.world==2 and 10 or 1)).." Wins",y+4)
			local pool=Config.eggPets(egg.id)
			local columns=math.max(1,math.floor((bodyWidth+10)/220)) local cw=(bodyWidth-(columns-1)*10)/columns
			for i,pet in pool do
				local x=((i-1)%columns)*(cw+10) local top=y+math.floor((i-1)/columns)*204
				local card=frame(body,"AdminPet_"..pet.id,x,top,cw,192,pet.color);context.corner(card,7)
				card:SetAttribute("EggId",egg.id)
				text(card,"Name",pet.name,6,3,cw-12,26,19)
				if context.petPreview then context.petPreview(card,pet,10,32,cw-20,88)
				else PetVisuals.preview(card,pet.visual or pet.id,10,32,cw-20,88) end
				text(card,"Chance",pet.weight.."% · ×"..pet.boost*egg.boost*worldBoost,5,120,cw-10,25,18)
				button(card,"Give_"..pet.id,"Выдать",12,151,cw-24,32,green,18,function() request("GivePet",{egg=egg.id,pet=pet.id}) end)
			end
			y+=math.ceil(#pool/columns)*204
			y=grid({{label="Открыть яйцо",command="Egg",value=egg.id},{label="Тест: 1 яйцо",command="Hatch",value={egg=egg.id,count=1},color=green},
				{label="Тест: 3 яйца",command="Hatch",value={egg=egg.id,count=3},color=green},{label="Выдать всех: "..#pool,command="GiveEggPets",value=egg.id,color=purple}},y,200,42)
			y=label("Особый питомец",y+8)
			y=grid({{label="Выдать "..Config.AdminPet.name,command="GivePet",value=Config.AdminPet.id,color=purple}},y,260,42)
		elseif tab=="Карта" then
			local items={}
			for i,biome in Config.Biomes do table.insert(items,{label=i.." · "..(i==8 and "Сакура" or biome.name),command="Teleport",value=i}) end
			y=grid(items,y,210,42)
			y=grid({{label="Вернуться в лобби",command="Teleport",value="Lobby",color=green},{label="К финальной арке",command="Teleport",value="Sakura",color=purple},
				{label="Мир 1",command="Teleport",value="World1"},{label="Мир 2",command="Teleport",value="World2"}},y+10,210,42)
			y=label("Тренировочные площадки",y+8)
			local lanes={} for i=1,7 do table.insert(lanes,{label="Площадка "..i,command="Training",value=i}) end
			y=grid(lanes,y,125,40)
		elseif tab=="Мячи / трейлы" then
			y=label("Экипировать тестовый мяч",y)
			local items={} for _,ball in Config.Stones do table.insert(items,{label=ball.name,command="Stone",value=ball.id,color=blue}) end
			y=grid(items,y,210,42)
			y=label("Экипировать тестовый трейл",y+8)
			items={} for _,trail in Config.Trails do table.insert(items,{label=trail.name,command="Trail",value=trail.id,color=purple}) end
			y=grid(items,y,210,42)
		end
		body.CanvasSize=UDim2.fromOffset(0,y+14) body.CanvasPosition=Vector2.zero
	end
	build=function()
		close()
		local viewport=workspace.CurrentCamera.ViewportSize
		width=math.min(980,viewport.X-24) height=math.min(620,viewport.Y-36) bodyWidth=width-42
		window=frame(gui,"AdminWindow",0,0,width,height,C(48,57,75));window.AnchorPoint=Vector2.new(.5,.5);window.Position=UDim2.fromScale(.5,.5);context.corner(window,9);context.stroke(window,2)
		local header=frame(window,"Header",0,0,width,54,purple);context.corner(header,9);context.pattern(header,purple)
		text(header,"Title","Панель проверок",16,4,width-90,45,27).TextXAlignment=Enum.TextXAlignment.Left
		button(header,"Close","×",width-54,7,40,36,C(246,55,77),27,function() context.closePanel() end)
		text(window,"Mode","",16,64,width-32,27,21,C(255,222,81)).TextXAlignment=Enum.TextXAlignment.Left
		summary=text(window,"Summary","",16,99,width-32,24,16,C(220,229,242));summary.TextXAlignment=Enum.TextXAlignment.Left
		modeButton=button(window,"TestMode","Начать тест",16,139,math.min(300,width-32),36,green,20,function() request(testing and "End" or "Begin") end)
		local tabs=Instance.new("ScrollingFrame") tabs.Name="Tabs" tabs.Position=UDim2.fromOffset(16,190);tabs.Size=UDim2.fromOffset(width-32,46);tabs.BackgroundTransparency=1 tabs.BorderSizePixel=0 tabs.ScrollBarThickness=3 tabs.ScrollingDirection=Enum.ScrollingDirection.X tabs.CanvasSize=UDim2.fromOffset(920,0) tabs.Parent=window
		for i,name in {"Проверки","Прогресс","Петы / яйца","Карта","Мячи / трейлы"} do
			button(tabs,"Tab"..i,name,(i-1)*184,0,174,36,name==tab and purple or blue,18,function() tab=name rows=tab=="Проверки" and rows or nil;build() end)
		end
		body=Instance.new("ScrollingFrame") body.Name="Body" body.Position=UDim2.fromOffset(16,247) body.Size=UDim2.fromOffset(width-32,height-299);body.BackgroundTransparency=1 body.BorderSizePixel=0 body.ScrollBarThickness=5 body.ScrollBarImageColor3=C(194,160,255) body.Parent=window
		statusLabel=text(window,"Status","Тестовые изменения можно отменить кнопкой «Завершить тест».",16,height-45,width-32,39,16,C(206,220,240));statusLabel.TextWrapped=true statusLabel.TextXAlignment=Enum.TextXAlignment.Left
		launcher.Visible=false gui.AdminLauncherShadow.Visible=false
		refreshSummary() renderPage()
	end
	open=function()
		if not authorized then return end
		if window then context.closePanel() return end
		context.activate() build() request("Status")
	end
	Input.InputBegan:Connect(function(input,processed)
		if input.KeyCode==Enum.KeyCode.F2 and not processed and not Input:GetFocusedTextBox() then open() end
	end)
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if window then build() end end)
	return {close=close,open=open,update=function(info)
		authorized=info.isAdmin==true testing=info.adminTest==true
		launcher.Visible=authorized and not window gui.AdminLauncherShadow.Visible=launcher.Visible
		if info.data then status.wins=info.data.wins status.skill=info.data.skill status.rebirths=info.data.rebirths status.world=info.data.world status.pets=#info.data.pets end
		refreshSummary()
	end}
end
return Panel
