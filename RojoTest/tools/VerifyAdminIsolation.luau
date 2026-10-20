-- Run in Edit. Uses plain mock state; never touches player saves or currency.
local source=game.ServerScriptService.Server.AdminService:Clone()
source.Name="AdminIsolationCheck" source.Parent=game.ServerScriptService.Server
local Service=require(source)
source:Destroy()
local Access=require(game.ServerScriptService.Server.AdminAccess)
local H=game:GetService("HttpService")
local owner={UserId=11792184677}
local original={wins=17,skill=23,rebirths=1,pets={},equipped={},world=1,stone="Pebble",stones={Pebble=true},trail="None",trails={None=true},perks={},receipts={},settings={}}
local gifts={[2]=true}
local state={data=original,gifts=gifts,joined=12,sessionOnly=false,saving=false,busyUntil=0}
local states={[owner]=state}
local context={states=states,stopTraining=function()end,rootFor=function()return nil end,publish=function()end,effect={FireClient=function()end}}
local service=setmetatable({context=context,logs={},last={},busy={}},Service)
local before=H:JSONEncode(original)
assert(Access.isAuthorized(owner.UserId))
assert(not Access.isAuthorized(0) and not Access.isAuthorized("11792184677"))
assert(not service:handle({UserId=1234},"Begin").ok)
assert(not pcall(service.dispatch,service,owner,"SetStat",{key="wins",amount=99}))
service:dispatch(owner,"Begin")
assert(state.data~=original and state.gifts~=gifts)
service:dispatch(owner,"SetStat",{key="wins",amount=1000000})
assert(state.data.wins==1000000 and original.wins==17)
state.data.receipts.fakeReceipt=true state.gifts[1]=true
local persisted,sessionOnly=Service.persistence(state)
assert(persisted==original and sessionOnly==false,"Live saves must refresh the original lease, not test data")
assert(not pcall(service.dispatch,service,owner,"SetStat",{key="wins",amount=math.huge}))
assert(not pcall(service.dispatch,service,owner,"SetStat",{key="wins",amount=0/0}))
assert(not pcall(service.dispatch,service,owner,"SetStat",{key="wins",amount=-1}))
assert(not pcall(service.dispatch,service,owner,"SetStat",{key="adminOriginal",amount=1}))
service:restore(owner,false)
assert(state.data==original and state.gifts==gifts and state.joined==12 and state.sessionOnly==false)
assert(not state.adminOriginal and not state.data.receipts.fakeReceipt and not state.gifts[1])
assert(H:JSONEncode(original)==before)
return {unauthorizedDenied=true,mutationRequiresSandbox=true,invalidStatsDenied=true,originalPersistence=true,rollback=true}
