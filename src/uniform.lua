local types = require "types"
local J = require "common"
local R = require "rigel"
local S = require "systolic"

local UniformFunctions = {}
local UniformMT = {__index=UniformFunctions}
local Uniform = {}

function UniformMT.__tostring(tab)
  if tab.kind=="const" then
    return "Uniform:"..tostring(tab.value)
  elseif tab.kind=="global" then
    return "Uniform:Global:"..tab.global.name
  else
    J.err(false,"Uniform tostring() NYI - "..tab.kind)
  end
end

-- returns a string that can be dumped into a lua file
function UniformFunctions:toEscapedString()
  if self.kind=="const" then
    return tostring(self.value)
  elseif self.kind=="global" then
    return [["]]..self.global.name..[["]]
  else
    J.err(false,"Uniform toEscapedString() NYI - "..self.kind)
  end
end

-- 'tab' should be a map of globals, to which we will append any globals in this uniform
-- this will mutate 'tab'!
function UniformFunctions:appendGlobals(tab)
  if self.kind=="global" then
    assert(tab[self.global]==nil)
    tab[self.global] = 1
  elseif self.kind=="const" then
  else
    J.err(false,"Uniform:appendGlobals() NYI - "..self.kind)
  end
end

-- convert to a verilog string for the value
function UniformFunctions:toVerilog()
  if self.kind=="global" then
    return self.global.name
  elseif self.kind=="const" then
    return S.valueToVerilog( self.value, self.type )
  else
    J.err(false,"Uniform:toVerilog() NYI - "..self.kind)
  end
end

-- convert to a verilog string of the input ports required for any globals
function UniformFunctions:toVerilogPortList()
  if self.kind=="global" then
    return S.declarePort( self.type, self.global.name, true )..","
  elseif self.kind=="const" then
    return ""
  else
    J.err(false,"Uniform:toVerilogPortList() NYI - "..self.kind)
  end
end

local UniformTopMT = {}
setmetatable(Uniform,UniformTopMT)

UniformTopMT.__call = J.memoize(function(tab,arg1,arg2,X)
  assert(X==nil)
  
  local ty, value

  if Uniform.isUniform(arg1) and arg2==nil then
return arg1
  end
  
  if types.isType(arg1) then
    ty, value = arg1, arg2
  elseif types.isType(arg2) then
    ty, value = arg2, arg1
  else
    J.err(false,"Uniform: should be passed a value and a type")
  end

  if R.isGlobal(value) then
    J.err( value.type==ty,"Uniform: global input type ("..tostring(value.type)..") must match requested type ("..tostring(ty)..")")
    J.err( value.direction=="input", "Uniform: global uniform must be an input" )
    local res = {kind="global",global=value,type=ty}
    return setmetatable(res,UniformMT)
  elseif Uniform.isUniform(value) then
    assert(value.type==ty)
    return value
  else
    ty:checkLuaValue(value)
    local res = {kind="const",value=value,type=ty}
    return setmetatable(res,UniformMT)
  end
  
end)
  
function Uniform.isUniform(tab) return getmetatable(tab)==UniformMT end

return Uniform
