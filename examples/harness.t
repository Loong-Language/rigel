local d = require "darkroom"
local types = require("types")
local cstdlib = terralib.includec("stdlib.h")
local fixed = require("fixed")

local function expectedCycles(hsfn,inputCount,outputCount,underflowTest,offset)
  assert(type(outputCount)=="number")
  assert(type(offset)=="number")

  local EC = inputCount*(hsfn.sdfInput[1][2]/hsfn.sdfInput[1][1])

  if DARKROOM_VERBOSE then print("Expected cycles:",EC,"IC",inputCount,hsfn.sdfInput[1][1],hsfn.sdfInput[1][2]) end

  EC = math.ceil(EC) + offset
  if underflowTest then EC = 1 end
  return EC
end

local function harness( hsfn, infile, inputType, tapInputType, outfile, outputType, id, inputCount, outputCount, underflowTest, earlyOverride, X)
  assert(X==nil)
  assert(type(inputCount)=="number")
  assert(type(outputCount)=="number")
  err( darkroom.isFunction(hsfn), "hsfn must be a function")
  local fixedTapInputType = tapInputType
  if tapInputType==nil then fixedTapInputType = types.null() end

  local slack = math.floor(math.max(outputCount*0.3,inputCount*0.3))
  local EC = expectedCycles(hsfn,inputCount,outputCount,underflowTest,slack)
  local ECTooSoon = expectedCycles(hsfn,inputCount,outputCount,underflowTest,-slack)
  if earlyOverride~=nil then ECTooSoon=earlyOverride end

  local outputBytes = outputCount*8
  local inputBytes = inputCount*8

  -- check that we end up with a multiple of the axi burst size.  If not, just fail.
  -- dealing with multiple frames w/o this alignment is a pain, so don't allow it
  err(outputBytes/128==math.floor(outputBytes/128), "outputBytes not aligned to axi burst size")
  err(inputBytes/128==math.floor(inputBytes/128), "outputBytes not aligned to axi burst size")
 
  local ITYPE = types.tuple{types.null(),fixedTapInputType}
  local inpSymb = d.input( d.Handshake(ITYPE) )
  -- we give this a less strict timing requirement b/c this counts absolute cycles
  -- on our quarter throughput test, this means this will appear to take 4x as long as it should
  local inp = d.apply("underflow_US", d.underflow(ITYPE, inputBytes/8, EC*4, true, ECTooSoon), inpSymb)
  local inpdata = d.apply("inpdata", d.makeHandshake(d.index(types.tuple{types.null(),fixedTapInputType},0)), inp)
  local inptaps = d.apply("inptaps", d.makeHandshake(d.index(types.tuple{types.null(),fixedTapInputType},1)), inp)
  local out = d.apply("fread",d.makeHandshake(d.freadSeq(infile,inputType)),inpdata)
  local hsfninp = out

  if tapInputType~=nil then
    hsfninp = d.apply("HFN",d.packTuple({inputType,tapInputType}), d.tuple("hsfninp",{out,inptaps},false))
  end

  local out = d.apply("HARNESS_inner", hsfn, hsfninp )
  out = d.apply("overflow", d.liftHandshake(d.liftDecimate(d.overflow(outputType, outputCount))), out)
  out = d.apply("underflow", d.underflow(outputType, outputBytes/8, EC, false, ECTooSoon), out)
  local out = d.apply("fwrite", d.makeHandshake(d.fwriteSeq(outfile,outputType)), out )
  return d.lambda( "harness"..id, inpSymb, out )
end

local function harnessAxi( hsfn, inputCount, outputCount, underflowTest)
  local inpSymb = d.input(hsfn.inputType )

  local outputBytes = upToNearest(128,outputCount*8) -- round to axi burst
  local inputBytes = upToNearest(128,inputCount*8) -- round to axi burst

  local EC = expectedCycles(hsfn,inputCount,outputCount,underflowTest,1024)
  local inp = d.apply("underflow_US", d.underflow( d.extractData(hsfn.inputType), inputBytes/8, EC, true ), inpSymb)
  local out = d.apply("hsfna",hsfn,inp)
  out = d.apply("overflow", d.liftHandshake(d.liftDecimate(d.overflow(d.extractData(hsfn.outputType), outputCount))), out)
  out = d.apply("underflow", d.underflow(d.extractData(hsfn.outputType), outputBytes/8, EC, false ), out)
  return d.lambda( "harnessaxi", inpSymb, out )
end

local H = {}

function H.terraOnly(filename, hsfn, inputFilename, tapType, tapValue, inputType, inputT, inputW, inputH, outputType, outputT, outputW, outputH, X)
  local inputCount = (inputW*inputH)/inputT
  local outputCount = (outputW*outputH)/outputT

  -------------
  for i=1,2 do
    local ext=""
    if i==2 then ext="_half" end
    local f = d.seqMapHandshake( harness( hsfn, inputFilename, inputType, tapType, "out/"..filename..ext..".raw", outputType, i, inputCount, outputCount ), inputType, tapType, tapValue, inputW, inputH, inputT, outputW, outputH, outputT, false, i )
    local Module = f:compile()
    if DARKROOM_VERBOSE then print("Call CPU sim, heap size: "..terralib.sizeof(Module)) end
    (terra() 
       cstdio.printf("Start CPU Sim\n")
       var m:&Module = [&Module](cstdlib.malloc(sizeof(Module))); m:reset(); m:process(nil,nil); m:stats(); cstdlib.free(m) end)()
    fixed.printHistograms()

    d.writeMetadata("out/"..filename..ext..".metadata.lua", inputType:verilogBits()/(8*inputT), inputW, inputH, outputType:verilogBits()/(8*outputT), outputW, outputH, inputFilename)
  end

end

function H.sim(filename, hsfn, inputFilename, tapType, tapValue, inputType, inputT, inputW, inputH, outputType, outputT, outputW, outputH, underflowTest, earlyOverride, X)
  assert(X==nil)
  assert( tapType==nil or types.isType(tapType) )
  assert( types.isType(inputType) )
  assert( types.isType(outputType) )
  assert(type(outputH)=="number")
  assert(type(inputFilename)=="string")


  local inputCount = (inputW*inputH)/inputT
  local outputCount = (outputW*outputH)/outputT

  H.terraOnly(filename, hsfn, inputFilename, tapType, tapValue, inputType, inputT, inputW, inputH, outputType, outputT, outputW, outputH, X)

  local simInputH = inputH*2
  local simOutputH = outputH*2
  local simInputCount = (inputW*simInputH)/inputT
  local simOutputCount = (outputW*simOutputH)/outputT

  ------
  for i=1,2 do
    local ext=""
    if i==2 then ext="_half" end
    local f = d.seqMapHandshake( harness(hsfn, "../"..inputFilename..".dup", inputType, tapType, filename..ext..".sim.raw",outputType,2+i, simInputCount, simOutputCount, underflowTest, earlyOverride), inputType, tapType, tapValue, inputW, simInputH, inputT, outputW, simOutputH, outputT, false, i )
    io.output("out/"..filename..ext..".sim.v")
    io.write(f:toVerilog())
    io.close()
  end
  
end

-- AXI must have T=8
function H.axi(filename, hsfn, inputFilename, tapType, tapValue, inputType, inputT, inputW, inputH, outputType, outputT, outputW, outputH,underflowTest,earlyOverride,X)

  assert(X==nil)
  assert( types.isType(inputType) )
  assert( tapType==nil or types.isType(tapType) )
  assert( tapType==nil or type(tapValue)==tapType:toLuaType() )
  assert( types.isType(outputType) )
  assert(type(inputW)=="number")
  assert(type(outputH)=="number")
  assert(type(inputFilename)=="string")
  err(d.isFunction(hsfn), "second argument to harness.axi must be function")

-- axi runs the sim as well
H.sim(filename, hsfn,inputFilename, tapType,tapValue, inputType, inputT, inputW, inputH, outputType, outputT, outputW, outputH, underflowTest,earlyOverride)
  local inputCount = (inputW*inputH)/inputT
local axifn = harnessAxi(hsfn, inputCount, (outputW*outputH)/outputT, underflowTest)
local fnaxi = d.seqMapHandshake( axifn, inputType, tapType, tapValue, inputW, inputH, inputT, outputW, outputH, outputT, true )
io.output("out/"..filename..".axi.v")
io.write(fnaxi:toVerilog())
io.close()
--------
end

return H