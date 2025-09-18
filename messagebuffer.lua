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
MessageBuffer.init(2)
timer.scheduleFunction( MessageBuffer.onTick,{},timer.getTime()+0.25)
