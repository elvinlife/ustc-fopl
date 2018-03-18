local util = require("common.util")
local posix = require("posix")
local Pipe = util.Pipe
local mod = {}

function mod.serialize(o)
	-- every type has a suffix
	-- save number as str
	if type(o) == "number" then
	  return 'n' .. tostring(o)
	end
	-- save boolean as 1/0
	if type(o) == "boolean" then
	  return 'b' .. (o and "1" or "0")
	end
	-- directly save string
	if type(o) == "string" then
	  return 's' .. o
	end
	-- table = 't' + ('(' + key + ')' + '(' + value + ')')*
	if type(o) == "table" then
	  local list = {}
	  for k, v in pairs(o) do
		table.insert(list, '(' .. mod.serialize(k) .. ")(" .. mod.serialize(v) .. ')')
	  end
	  return 't' .. table.concat(list)
	end
	-- nil save as 'e'(error)
	if type(o) == "nil" then
	  return 'e'
	end
  end


-- split by the first occurance
function mod.split2(str, pat) 
	local words = {}
	idx = string.find(str, pat)
	if idx == nil then
		return words
	end
	table.insert(words, string.sub(str, 1, idx - 1))
	table.insert(words, string.sub(str, idx + 1))
	return words
end


function mod.deserialize(s)
  local id = s:sub(1,1)
  if id == "n" then
    return tonumber(s:sub(2,-1))
  end
  if id == "b" then
    assert(#s == 2)
    return (s:sub(2,2) == '1' and true or false)
  end
  if id == "s" then
    return s:sub(2,-1)
  end
  if id == "t" then
    local t = {}
    local list = util.parens(s:sub(2,-1))
    assert(#list % 2 == 0)
    for i = 1, #list, 2 do
			local key = mod.deserialize(list[i])
		-- avoid the key to be nil
	  	if key ~= nil then	
        t[key] = mod.deserialize(list[i+1])
      end
    end
    return t
  end
  if id == "x" then
    return nil
  end
end

function tablelength(T)
	local count = 0
	for _ in pairs(T) do
		count = count + 1
	end
	return count
end


function mod.rpcify(class)
	local MyClassRPC = {}
	function MyClassRPC.new()
		local wpipe = Pipe.new()
		local rpipe = Pipe.new()
		local pid = posix.fork()
		if pid == 0 then
			-- build the reading and writing pipe, create the child 
			-- process's class instance
			wpipe, rpipe = rpipe, wpipe
			inst = class.new()
			-- start to keep reading from rpipe
			while true do
				local order = Pipe.read(rpipe)
				Pipe.write(wpipe, "ready")
				-- order to stop the child process
				if order == "exit" then
					os.exit()
				end
				-- call the method
				local param = Pipe.read(rpipe)
				local ret = class[order](inst, table.unpack(mod.deserialize(param))) 
				-- write to father process
				Pipe.write(wpipe, mod.serialize(ret))
			end
		else
			return {wpipe=wpipe, rpipe=rpipe, pid=pid}
		end
	end
	for name, func in pairs(class) do
		if type(func) == "function" and name ~= "new" then
			MyClassRPC[name] = function(inst, ...)
				--send func name
				Pipe.write(inst.wpipe, name)
				Pipe.read(inst.rpipe)
				--send func parameter
				Pipe.write(inst.wpipe, mod.serialize({...}))
				return mod.deserialize(Pipe.read(inst.rpipe))
			end
			MyClassRPC[name .. "_async"] = function(inst, ...)
				Pipe.write(inst.wpipe, name)
				Pipe.read(inst.rpipe)
				Pipe.write(inst.wpipe, mod.serialize({...}))
				return function()
					return mod.deserialize(Pipe.read(inst.rpipe))
				end
			end
		end
	end
	function MyClassRPC.exit(inst)
		Pipe.write(inst.wpipe, "exit")
		posix.wait(inst.pid)
		return MyClassRPC
	end
	return MyClassRPC
end


return mod
