pcall( dofile, "c:\\HELL\\pin\\util.lua");
pcall( dofile, "c:\\HELL\\pin\\pin.lua");

local r_1;
local r_2;
local r_3;



local fodderGrp = Group.getByName("Fodder")
local cloneme = Group.getByName("cloneme")
local numsold = 0
local cargow = 0
local hand_pn = nil
local hand_hov = nil
local hand_hov = nil
local spawned_units = {}
--- MISSION SPECFIC TRIGGER


function unitNearStatic(static, count,radius)
	local z = StaticObject.getByName(static)

	if not z then
		net.log("Staic not found "..z)
	end		
	out = 0
	for i,g in pairs(spawned_units) do
		u = g:getUnits()[1]
		if (mist.utils.get2DDist(u:getPosition().p,z:getPoint())<radius)  then
			out = out +1 
		end
		
	end
	return out>=count

end
	
function droppedInZone(zonename, count)
	local z = trigger.misc.getZone(zonename)
	if not z then
		net.error("Zone not found "..zonename)
	end		
	out = 0
	for i,g in pairs(spawned_units) do
		u = g:getUnits()[1]
		if (mist.utils.get2DDist(u:getPosition().p,z.point)<z.radius)  then
			out = out +1 
		end
		
	end
	return out>=count

end
	
function is_stopped()
	return isStopped(Pinnacle.player)
end


function ch()


end

function t_pad()
	Pinnacle.dropPoint=StaticObject.getByName("pad"):getPoint();

end


function t_pad2()
Pinnacle.dropPoint=StaticObject.getByName("pad2"):getPoint();
end

function t_bunker()
Pinnacle.dropPoint=StaticObject.getByName("bunker"):getPoint();
end

function menuP(u)
	ch()
	Pinnacle.dropPoint=u:getPoint()
	Smoker.smoke(u:getPoint())
end

local p_units = {"p_pad","p_large","p_bunker","p_hospital","p_oil","p_office","p_tank","p_containterstack","p_hq"}
local p_names = {"Landing Pad","Large Landing Pad","Bunker","Hospital","Oil platform","Office","Fuel Tank","Container Stack","HQ Building"}

local p_mtn_units = {"p_cow1","p_cow2","p_cow3","p_cow4"}
function t_tutdone()
	ch()

	r_3 = missionCommands.addSubMenuForGroup(Pinnacle.player:getGroup():getID(),"Crew Chief - Practice area",nil)
	r_4 = missionCommands.addSubMenuForGroup(Pinnacle.player:getGroup():getID(),"Crew Chief - Mountain landings",nil)
	r_5 =  missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Find Mark on Map (\"pin\")', nil, markToLanding, Pinnacle.player)
	for i,v in pairs(p_units) do
		so = StaticObject.getByName(v)
		if so then
		    name =string.format("Crew Chief guide to: %s",so:getName())
			missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),p_names[i],r_3, menuP, so)
		end
	end
	
	
	for i,v in pairs(p_mtn_units) do
		so = StaticObject.getByName(v)
		if so then
		    name =string.format("Crew Chief guide to: %s",so:getName())
			missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),tostring(i),r_4, menuP, so)
		end
	end
	
end


----

function markToLanding(args)
	for i,m in pairs(mist.DBs.markList) do
		if  string.lower(m.text) == "pin" then
			
			g = {x = m.pos.x, y =0, z= m.pos.z}
			h = Pinnacle.findHeight(g)
			y = h
			Pinnacle.dropPoint = g
			
			
			Smoker.smoke(g)
		end
		_MB.t("Mark found!",20)
		 trigger.action.removeMark(m.markId )
		return true
	end
	_MB.t("Could not find mark.  The mark must have text \"pin\"",20)
	return false
end
function Pinnacle.alarmState(args,time)
	local outstr = {}
	local elapsed = time-Pinnacle.hoverTimer 
	--outstr = outstr .. tostring(elapsed).. " "
	
	
	
	local state = math.floor(elapsed / 5)
	state = state%2
	local statesec = elapsed%5
	local startleft = math.floor(cargow/150)
	local hascargo = startleft>0

	
	if Pinnacle.alarm == 1 then
		if not hascargo then
			table.insert(outstr, string.format("Nothing to unload!"			, 10 - statesec))	
		elseif state ==  0 then	
			table.insert(outstr, string.format("Unloading unit %d, %d left...  %d"			, 1+elapsed/10, startleft , 10 - statesec))
		elseif state == 1 then
			table.insert(outstr, string.format("Unloading unit %d, %d left...  %d"			, 1+elapsed/10, startleft , 5 - statesec))
			if statesec == 4 then
				
				unloadUnit(nil)
			end	
			
		end
		
	else	
		table.insert(outstr, "Ready - Turn on alarm to commence unload")
		Pinnacle.hoverTimer = nil
		
	end
	table.insert(outstr,"\n")
	return table.concat(outstr, "")
end





function loadUnit(plr)
	if Pinnacle.gate < 3 then return end
	missionCommands.removeItemForGroup(Pinnacle.player:getGroup():getID(),r_1)
	local done = false
	cargow = #(fodderGrp:getUnits())*150
	fodderGrp:destroy()


	 trigger.action.setUnitInternalCargo(Pinnacle.player:getName(),cargow)
end
ctr = 0


function unloadUnit(plr)
	if cargow <= 0 then
		_MB.t("No one onboard!",10)
	end
	
	vars = {
		
			["groupName"]  = "cloneme",
			["point"] = Pinnacle.tailgatePoint,
			["radius"] = 1,
		    ["action"] = "clone",
			["visible"] = true
			}
			ctr=ctr+1
	
	local nm = mist.teleportToPoint(vars)
	g = nil
	if nm then
		g = Group.getByName(nm.name)
		g:activate()
		
		table.insert(spawned_units,g)
	
	else	
		_MB.t("Unable to unload unit, please leave airport",10)
	end
	if Pinnacle.dropPoint and g then
		dist = mist.utils.get2DDist(Pinnacle.dropPoint, Pinnacle.tailgatePoint)
		_MB.t("Unit unloaded.  Distance to drop point: "..string.format("%.2f",dist),10)
	else
		_MB.t("Unit unloaded",10)
	end
	cargow = math.max(0,cargow - 150,0)
	trigger.action.setUnitInternalCargo(Pinnacle.player:getName(),cargow)
end

function menuSkipTutorial(plr)
	trigger.action.setUserFlag("tutdone" , 1 ) 
	missionCommands.removeItemForGroup(Pinnacle.player:getGroup():getID(),r_2)	
	
end


 
player = Unit.getByName("Rotary-1-1")
Pinnacle.initialize(player)
Pinnacle.modeOff()
MessageBuffer.init(2)

r_1 = missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Load Unit', nil, loadUnit, Pinnacle.player)
r_2 = missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Skip tutorial', nil, menuSkipTutorial, Pinnacle.player)
r_3 = nil


timer.scheduleFunction( MessageBuffer.onTick,{},timer.getTime()+0.25)

hand_pn = timer.scheduleFunction(Pinnacle.pn,{},timer.getTime()+0.5)
hand_hov= timer.scheduleFunction(Pinnacle.monitorHover,{},timer.getTime()+0.5)
--StaticObject.getByName("bunker")
timer.scheduleFunction( Smoker.clear,Pinnacle.player,timer.getTime()+1)
--trigger.action.outText(Pinnacle.monitorHover({dropPoint=StaticObject.getByName("bunker"):getPoint()},0),10)