local R = require "rigel"
local RM = require "modules"
local types = require("types")
local harness = require "harness"

W = 128
H = 64
--T = 8

scaleX = 2
------------
function MAKE(T)
  local ITYPE = types.array2d( types.uint(8), 8 ) -- always 8 for AXI

  local inp = R.input( R.Handshake(ITYPE) )
  local out = R.apply("reducerate", RM.liftHandshake(RM.changeRate(types.uint(8),1,8,T)), inp )
  out = R.apply("DS", RM.liftHandshake(RM.liftDecimate(RM.downsampleXSeq( types.uint(8), W,H,T,scaleX))), out)
  local downsampleT = math.max(T/scaleX,1)
  out = R.apply("incrate", RM.liftHandshake(RM.changeRate(types.uint(8),1,downsampleT,8)), out )
  local hsfn = RM.lambda("hsfn", inp, out)

  harness.axi( "downsamplex_wide_handshake_"..T, hsfn, "frame_128.raw", nil, nil, ITYPE, 8,W,H, ITYPE,8,W/scaleX,H)
end

local t = string.sub(arg[0],string.find(arg[0],"%d+"))
MAKE(tonumber(t))