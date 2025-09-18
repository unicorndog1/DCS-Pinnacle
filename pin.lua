


Pinnacle = {}
function Pinnacle.initialize(player)
	Pinnacle.probe = StaticObject.getByName("Probe2")
	Pinnacle.probeHome = Pinnacle.probe:getPosition()		
	Pinnacle.on = false	
	Pinnacle.err = 0.25
	Pinnacle.player = player
end

function Pinnacle.modeOff()

	Pinnacle.on = false
	if r_3 then
		missionCommands.removeItemForGroup(Pinnacle.player:getGroup():getID(),r_3)
	end
	r_3= missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Turn Pinnacle mode on', nil, Pinnacle.modeOn, player)

end
function Pinnacle.modeOn()
	Pinnacle.on = true
	if r_3 then
		missionCommands.removeItemForGroup(Pinnacle.player:getGroup():getID(),r_3)
	end
	r_3= missionCommands.addCommandForGroup(Pinnacle.player:getGroup():getID(),'Turn Pinnacle mode off', nil, Pinnacle.modeOff, player)

end
function Pinnacle.getGateStatus()
	gate = Pinnacle.player:getDrawArgumentValue(85)
	plat = Pinnacle.player:getDrawArgumentValue(86)

	  k=0
	  if gate == 0 and plat == 0 then
		k=0
	  elseif gate == 0 and  plat >0  and plat< .1  then
		k=1
	   elseif gate == 0 and plat>.6 and plat<.9 then
		k=2
	  elseif gate == 0 and plat>.9 then
		 k=3
	  elseif gate ==1 and plat>.9 then
		k = 4
	  else 
		k=-1
	  end
	return k
end
 function Pinnacle.findHeight(p)
 	vars = {
			
			["groupName"]  = "Probe2",
			["point"] = p,
			["radius"] = 0,
		    ["action"] = "clone",
			["visible"] = true
			}
	
	local nm = mist.teleportToPoint(vars )
	if not nm then
		return -1	
	end
	local prob_grp = (StaticObject.getByName(nm.name))
	local prob = prob_grp:getPosition()
	out = prob.p.y
	prob_grp:destroy()
	return out
 end
function Pinnacle.pn(a,time)
	Pinnacle.gate = Pinnacle.getGateStatus()
	Pinnacle.alarm = trigger.misc.getUserFlag(666)

	if not Pinnacle.on and Pinnacle.player:isExist() then return time+1 end
	
	local unitpos = Pinnacle.player:getPosition()
	--local Heading = math.atan2(unitpos.x.z, unitpos.x.x)
	--local Pitch = math.asin(unitpos.x.y)
	
	local length          = 15.54  -- half body length (no rotor)
	local outLength       = length + 4
	local height          = 1.94*2 -- half body height
	
	if Pinnacle.gate < 2 then
		-- give guidance point like fully extended
		length = length -1
	elseif Pinnacle.gate == 2 then
		length = length -1.6
		height = height -1
	elseif Pinnacle.gate == 3 then
		length = length -1
	elseif Pinnacle.gate == 4 then
		length = length - 0.5
	end
	
	local gateLoc = {
		x = unitpos.p.x + -length/2 * unitpos.x.x,
		y = unitpos.p.y + -length/2 * unitpos.x.y - height/2,
		z = unitpos.p.z + -length/2 * unitpos.x.z
	   }
	local unloadLoc = {
		x = unitpos.p.x + -outLength/2 * unitpos.x.x,
		y = unitpos.p.y + -outLength/2 * unitpos.x.y - height/2,
		z = unitpos.p.z + -outLength/2 * unitpos.x.z
	   }
	--ok = mist.utils.get2DDist(z.point, gateLoc)
	l = land.getHeight({x = gateLoc.x, y = gateLoc.z})


	g = {x = gateLoc.x, y =0, z= gateLoc.z}
	h = Pinnacle.findHeight(g)
	
	Pinnacle.probeheight = h--prob.p.y 
	Pinnacle.tailgatePoint = unloadLoc
	

	
	if false then
		trigger.action.outText("v:".. tostring(ok).." "..tostring(z.radius).. " ".. tostring(Pitch).. " " ,4)
		trigger.action.outText("v:".. tostring(unitpos.p.y).." "..tostring(l) ,4)
	end
	Pinnacle.err = 0.3
	
	Pinnacle.gateOnGroundFudge = Pinnacle.probeheight+Pinnacle.err >= gateLoc.y
	Pinnacle.gateOnGround  = Pinnacle.probeheight >= gateLoc.y
	Pinnacle.gatediff =  gateLoc.y- Pinnacle.probeheight

	return time+0.25
end






function Pinnacle.monitorHover(args,time)
	if not Pinnacle.on and Pinnacle.player:isExist() then return time+1 end

	args.timeRequired=args.timeRequired or 1000 -- do event on time out
	args.maxDist= args.maxDist or 7.5           -- max distance from point to allow drop 
	args.useAlarm = args.useAlarm or true      -- use the alarm for dropping troops
	args.enforceRange = args.enforceRange or true
	args.enteredRange = args.enteredRange or false
	--args.alarmPretime = args.alarmPretime or 5      -- use the alarm for dropping troops

	
	if not Pinnacle.player:isExist() then
		return
	end
	local outstr = {}

----- gate guidance

	table.insert(outstr, "PINNACLE LANDING STATUS:\n")
	if  (Pinnacle.gateOnGroundFudge and Pinnacle.gate >=2)then 
	
		if Pinnacle.hoverTimer == nil then
			
			Pinnacle.hoverTimer = time
		else
			
		end
		local elapsed = time-Pinnacle.hoverTimer 

		if elapsed > args.timeRequired then
			Pinnacle.hoverTimer = nil
			return nil
		end
		
		if   args.useAlarm  then
			table.insert(outstr, Pinnacle.alarmState(args,time))
		else
			--outstr = outstr .. string.format("Stabilize and hold ...\n"			)
		end
	else
		if Pinnacle.gate<2 then
			table.insert(outstr,"Gate not down\n")
		else
			table.insert(outstr,"Gate not on ground\n")
		end
		Pinnacle.hoverTimer = nil
	end
	
	--- GUIDANCE
	

	
	table.insert(outstr, "CREW CHIEF GUIDANCE\n")
	if not Pinnacle.dropPoint then
		table.insert(outstr, "Waiting for target for lateral guidance\n")
	end
	table.insert(outstr, Pinnacle.guidance(args,time))
	_MB.h(table.concat(outstr,""),1)
	return time+0.25
end

function Pinnacle.guidance(args,time)
	local outstr = {}
	local destination = Pinnacle.dropPoint	
	local playerloc = Pinnacle.tailgatePoint
	
	if not destination then	
		return  string.format("Distance to ground:  %d\n",Pinnacle.gatediff)
	end
	
	local alt_diff = (playerloc.y)-(destination.y)
	local dist = mist.utils.get2DDist(playerloc,destination)
	
	if dist < 100  then
		p2 = playerloc
		p1 = destination
		dx =p1.x-p2.x
		dy =p1.y-p2.y
		dz =p1.z-p2.z
		
        heading = mist.getHeading(Pinnacle.player)

		coz = math.cos(heading)
		zin = math.sin(heading)
		
		dzrot = coz*dz - zin*dx
		dxrot = zin*dz + coz*dx
		args.enteredRange = true
		strstatus = nil
		
	

		
		local _format = "%.2f"
		
			
		if dzrot>0 then
			table.insert(outstr,"Right    ".. string.format(_format,math.abs(dzrot)))
			
		else
			table.insert(outstr,"Left     ".. string.format(_format,math.abs(dzrot)))
			--outstr = outstr .. "Left     ".. string.format(_format,math.abs(dzrot))
		end
		
		if dzrot<5 then
			table.insert(outstr,"         HOLD\n")
			
		else
			table.insert(outstr," \n")
			
		end


		if dxrot>0 then
			table.insert(outstr, "Forward ".. string.format(_format,math.abs(dxrot)))
		else
			table.insert(outstr, "Back    ".. string.format(_format,math.abs(dxrot)))
		end

		if dxrot<5 then
			table.insert(outstr,"         HOLD\n")
		else
			table.insert(outstr,         " \n")
		end
		
		table.insert(outstr,string.format("Distance to ground:  %.2f",Pinnacle.gatediff))
		if Pinnacle.gatediff<=Pinnacle.err then
			table.insert(outstr,"         HOLD\n")
		else
			table.insert(outstr,         " \n")
		end
	else
		local angle = math.deg(mist.utils.getHeadingPoints(playerloc,destination)) + 15
		
		table.insert(outstr, string.format("Distance to target: %2.f Bearing: %d \n",dist,angle))
	end
	return table.concat(outstr,"")
end