local d = require "darkroom"
local Im = require "image"
local ffi = require("ffi")
local types = require("types")
local S = require("systolic")
local cstdio = terralib.includec("stdio.h")
local cstring = terralib.includec("string.h")
local harness = require "harness"

W = 128
H = 64
T = 8

scaleX = 2
------------
--function MAKE(T)
  local ITYPE = types.array2d( types.uint(8), 8 ) -- always 8 for AXI

  local inp = d.input( d.StatefulHandshake(ITYPE) )
--  local out = d.apply("reducerate", d.liftHandshake(d.changeRate(types.uint(8),1,8,T)), inp )
  local out = d.apply("DS", d.makeHandshake(d.makeStateful(d.upsampleXSeq( types.uint(8), W,H,T,scaleX))), inp)
  local upsampleT = T*scaleX
  out = d.apply("incrate", d.liftHandshake(d.changeRate(types.uint(8),1,upsampleT,8)), out )
  local hsfn = d.lambda("hsfn", inp, out)

  harness.axi( "upsamplex_wide_handshake", hsfn, ITYPE, nil, nil, W,H, ITYPE,W*scaleX,H)
--end

--local t = string.sub(arg[0],string.find(arg[0],"%d+"))
--MAKE(tonumber(t))