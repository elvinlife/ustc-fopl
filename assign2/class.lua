local Object
Object = {
  isinstance = function(cls) return cls == Object end,
  constructor = function() end,
  methods = {},
  data = {},
  metamethods = {}
}

-- This is a utility function you will find useful during the metamethods section.
function table.merge(src, dst)
  for k,v in pairs(src) do
    if not dst[k] then dst[k] = v end
  end
end

local function class(parent, child)
  local methods = child.methods or {}
  local data = child.data or {}
  local constructor = child.constructor or parent.constructor
  local metamethods = child.metamethods or {}

  local Class = {}
  Class.methods = {}
  Class.data = {}
  Class.metamethods = {}
  Class.constructor = constructor
  Class.isinstance = function(cls)
    return cls == Class or parent.isinstance(cls)
  end
  -- copy from parent
  for k, funct in pairs(parent.methods) do Class.methods[k] = funct end
  for k, var in pairs(parent.data) do Class.data[k] = var end
  for k, meta in pairs(parent.metamethods) do Class.metamethods[k] = meta end
  -- self class override
  for k, funct in pairs(methods) do Class.methods[k] = funct end
  for k, entry in pairs(data) do Class.data[k] = entry end
  for k, meta in pairs(metamethods) do Class.metamethods[k] = meta end
  
  Class.new = function(...)
    local public_inst = {}
    local private_inst = {}
    -- define data
    for k, var in pairs(Class.data) do
      private_inst[k] = var
    end
    -- define function
    for k, funct in pairs(Class.methods) do
      public_inst[k] = function(self, ...)
        return funct(private_inst, ...)
      end
      private_inst[k] = funct
    end
    -- define meta
    setmetatable(public_inst, Class.metamethods)
    -- define isinstance
    public_inst.isinstance = function(self, cls)
      return Class.isinstance(cls)
    end
    private_inst.isinstance = public_inst.isinstance
    -- construct the instance
    constructor(private_inst, ...)
    return public_inst
  end
  return Class
end

return {class = class, Object = Object}
