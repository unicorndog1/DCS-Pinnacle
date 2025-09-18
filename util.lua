function serializeTable(val, name, skipnewlines, depth,maxdepth)
    skipnewlines = skipnewlines or false
    depth = depth or 0
	maxdepth = maxdepth or 100
	if depth>maxdepth then return "" end
    local tmp = string.rep(" ", depth)

    if name then tmp = tmp .. name .. " = " end

    if type(val) == "table" then
        tmp = tmp .. "{" .. (not skipnewlines and "\n" or "")

        for k, v in pairs(val) do
            tmp =  tmp .. serializeTable(v, k, skipnewlines, depth + 1,maxdepth) .. "," .. (not skipnewlines and "\n" or "")
        end

        tmp = tmp .. string.rep(" ", depth) .. "}"
    elseif type(val) == "number" then
        tmp = tmp .. tostring(val)
    elseif type(val) == "string" then
        tmp = tmp .. string.format("%q", val)
    elseif type(val) == "boolean" then
        tmp = tmp .. (val and "true" or "false")
    else
        tmp = tmp .. "\"[inserializeable datatype:" .. type(val) .. "]\""
    end

    return tmp
end


MessageBuffer = {
	messages = {},
	expireTime = {},
	printInterval = 0.25
}


_MB = MessageBuffer


function MessageBuffer.init(n)
	for i = 1,n do
		MessageBuffer.add("nil","nil")
	end
end
function MessageBuffer.add(s,t)

	tval = nil
	if t=="nil"	then
		tval =  "nil"
	else
		tval =  t + timer.getTime()
	end
	table.insert(MessageBuffer.messages,s)
	table.insert(MessageBuffer.expireTime,tval)
	return #MessageBuffer.messages
end	

function doodiefile(x)
	pcall(dofile,x)

end


function MessageBuffer.update(i,s,t)
	MessageBuffer.messages[i] = s
	if not t then
		MessageBuffer.expireTime[i] = "nil"
	else
		MessageBuffer.expireTime[i] = t + timer.getTime()
	end
	return MessageBuffer.expireTime[i]
end	

function MessageBuffer.remove(idx)
	table.remove(MessageBuffer.messages,idx)
	table.remove(MessageBuffer.expireTime,idx)
end

function MessageBuffer.onTick(args,time)
	out = {}


	for i=1,#MessageBuffer.messages do
	
		if  not (MessageBuffer.messages[i] == "nil") then
			if (MessageBuffer.expireTime[i]=="nil") or MessageBuffer.expireTime[i] >= time then
				table.insert(out,MessageBuffer.messages[i])
				if not (MessageBuffer.expireTime[i] == "nil") then
					--table.insert(out,tostring(MessageBuffer.expireTime[i]-time))
				end
			end
		end
	end
	if #out >0 then
		trigger.action.outText(table.concat(out,"\n--------\n"), MessageBuffer.printInterval+1, true)
	end
	return time+MessageBuffer.printInterval
end




function _MB.h(s,t) -- alias for mission editor
	return MessageBuffer.update(1,s,t)
end

function _MB.t(s,t) -- alias for mission editor
	return MessageBuffer.update(2,s,t)
end


function isStopped(unt,eps)
	if not unt:isExist() then
		return false
	end
	local p = unt:getVelocity()
	local eps = eps or 0.1
	local nomove = (p.x <= eps and p.y <= eps and p.z <= eps)
	--net.log(serializeTable(nomove))
	return nomove and not unt:inAir()
end

Smoker ={ U= {}, P= {}, R= {}}

function Smoker.clear(plr,time)
	for i=1,#Smoker.U do
		dist = mist.utils.get2DDist(plr:getPoint(),Smoker.P[i])
		if dist<Smoker.R[i] then
			 trigger.action.effectSmokeStop(Smoker.U[i])
		end
	end
	return time+1
end

function Smoker.smoke(point,remove_rad,name) 
	name = name or "DINGUS"..tostring(#Smoker.U +1)
	remove_rad = remove_rad or 100
	trigger.action.effectSmokeBig(point , 5 , 0.5, name)
	table.insert(Smoker.U,name)
	table.insert(Smoker.P,point)
	table.insert(Smoker.R,remove_rad)
end
