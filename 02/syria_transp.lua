dofile("c:\\HELL\\pin\\util.lua");
dofile("c:\\HELL\\pin\\pin.lua");

local r_1;
local r_2;
local r_3;

patients_left = 40
local p_weight_normal = 250
local p_weight_light = 200
local p_weight_heavy = 400
local p_weight_giant = 800
local p_table = {0,.1,.6,.9,1}
local out_table = {p_weight_light,p_weight_normal,p_weight_heavy,p_weight_giant}
local message_table = {"Light","Normal","Heavy","Very heavy"}
local cur_weight = nil


local cargow = 0
local hand_pn = nil
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
	
end

local p_units = {"p_cargo"}

function t_tutdone()

	for i,v in pairs(p_units) do
		so = StaticObject.getByName(v)
		if so then
			local name = string.format("Crew Chief guide to: %s",so:getName())
			local r_3  = missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),name,nil, menuP, so)
	
		end
	end
	
end

----


cargow = 0


function next_w()
	
			
	local p = math.random()
	local out  = {}
	for i = 1,(#p_table-1) do
		if p >= p_table[i] and p < p_table[i+1] then
			out.w = out_table[i]
			out.m = message_table[i]
		end
	end
	return out
end

function _load(args,time)
	local outstr = {}
	local elapsed = time-Pinnacle.hoverTimer 
	--outstr = outstr .. tostring(elapsed).. " "
	
	if Pinnacle.gate < 3 then return end



	local statesec = elapsed%10
	local hascargo = patients_left>0
	
	if Pinnacle.alarm == 1 then
		if not hascargo then
			table.insert(outstr, string.format("Nothing to load!"))	
		else 
			table.insert(outstr, string.format("%d Loading patient %d, %d left...  %d"			,statesec, 1+elapsed/10, patients_left , 10 - statesec))
			
			-- tick 0/10
			if statesec==0 then
			
				-- not first time around
				if elapsed > 0 then
					
					loadUnit()
				
				end
				cur_weight = next_w()
				_MB.t(cur_weight.m,20)	
			

			end
			
		
		end
		
	else	
		table.insert(outstr, "Ready - Turn on alarm to commence load")
		Pinnacle.hoverTimer = nil
		
	end
	table.insert(outstr,"\n")
	return table.concat(outstr, "")
end






function loadUnit()
	cargow = cargow + cur_weight.w
	trigger.action.setUnitInternalCargo(Pinnacle.player:getName(),cargow)
	patients_left = patients_left-1
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
end


 
Pinnacle.alarmState = _load
player = Unit.getByName("Rotary-1-1")
Pinnacle.initialize(player)
Pinnacle.modeOff()
MessageBuffer.init(2)

r_1 = missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Load Unit', nil, loadUnit, Pinnacle.player)
r_2 = missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Skip tutorial', nil, menuSkipTutorial, Pinnacle.player)
r_3 = nil

t_tutdone()


timer.scheduleFunction( MessageBuffer.onTick,{},timer.getTime()+0.25)
hand_pn = timer.scheduleFunction(Pinnacle.pn,{},timer.getTime()+0.5)
hand_hov= timer.scheduleFunction(Pinnacle.monitorHover,{},timer.getTime()+0.5)
--StaticObject.getByName("bunker")

--trigger.action.outText(Pinnacle.monitorHover({dropPoint=StaticObject.getByName("bunker"):getPoint()},0),10)