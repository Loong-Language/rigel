-- this is the base class for all our compiler IR

IR = {}

IR.IRFunctions = {}

function IR.IRFunctions:visitEach(func)
  local seen = {}
  local value = {}

  local function trav(node)
    if seen[node]~=nil then return value[node] end

    local argList = {}
    for k,v in pairs(node.inputs) do
      argList[k]=trav(v)
    end

    value[node] = func( node, argList )
    seen[node] = 1
    return value[node]
  end

  return trav(self)
end

function IR.IRFunctions:process( func )
  return self:visitEach( 
    function( n, inputs )
      local r = n:shallowcopy()
      for k,v in pairs(n.inputs) do r.inputs[k] = inputs[k] end
      local res = func( r )
      if getmetatable(res)==getmetatable(n) then
        return res
      elseif res~=nil then
        assert(false)
      end
      setmetatable( r, getmetatable(n) )
      return r
    end)
end

-- this basically only copies the actual entires of the table,
-- but doesn't copy children/parents, so 
-- you still have to call darkroom.ast.new on it
function IR.IRFunctions:shallowcopy()
  local newir = {inputs={}}

  for k,v in pairs(self) do
    if k=="inputs" then
      for kk,vv in pairs(v) do newir.inputs[kk] = vv end
    else
      newir[k]=v
    end
  end

  return newir
end

IR._parentsCache=setmetatable({}, {__mode="k"})
function IR.buildParentCache(root)
  assert(IR._parentsCache[root]==nil)
  IR._parentsCache[root]=setmetatable({}, {__mode="k"})
  IR._parentsCache[root][root]=setmetatable({}, {__mode="k"})

  local visited={}
  local function build(node)
    if visited[node]==nil then
      for k,child in node.inputs do
        if IR._parentsCache[root][child]==nil then
          IR._parentsCache[root][child]={}
        end

        -- notice that this is a multimap: node can occur
        -- multiple times with different keys
        table.insert(IR._parentsCache[root][child],setmetatable({node,k},{__mode="v"}))
        build(child)
      end
      visited[node]=1
    end
  end
  build(root)
end

-- this node's set of parents is always relative to some root
-- returns k,v in this order:  parentNode, key in parentNode to access self
-- NOTE: there may be multiple keys per parentNode! A node can hold
-- the same AST multiple times with different keys.
function IR.IRFunctions:parents(root)
  assert(IR.isIR(root))

  if IR._parentsCache[root]==nil then
    -- need to build cache
    IR.buildParentCache(root)
  end

  -- maybe this node isn't reachable from the root?
  assert(type(IR._parentsCache[root][self])=="table")

  -- fixme: I probably didn't implement this correctly

  local list = IR._parentsCache[root][self]

  local function filteredF(s)
    assert(type(s)=="table")
    assert(type(s.i)=="number")

    if s.i>#list then return nil,nil end
    s.i = s.i+1
    return list[s.i-1][1],list[s.i-1][2]
  end

  return filteredF,{i=1},1

end

function IR.IRFunctions:parentCount(root)
  local pc=0
  for k,v in self:parents(root) do pc=pc+1 end
  return pc
end

IR._original=setmetatable({}, {__mode="k"})

function IR.new(node)
  assert(getmetatable(node)==nil)

  IR._original[node]=setmetatable({}, {__mode="kv"})
  for k,v in pairs(node) do
    IR._original[node][k]=v
  end

end

function IR.isIR(v)
  local mt = getmetatable(v)
  if type(mt)~="table" then return false end
  if type(mt.__index)~="table" then return false end
  local mmt = getmetatable(mt.__index)
  if type(mmt)~="table" then return false end

  local t = mmt.__index

  return t==IR.IRFunctions
end

return IR