local R = require "rigel"
local RM = require "modules"
local types = require("types")
local harness = require "harness"
local fixed = require "fixed_float"

W = 64
H = 32
T = 2

------------
local ainp = fixed.parameter("ainp",types.int(32))
local af = ainp:lift(0) 
--local a = (af-fixed.constant(6540982534034)):toRigelModule("a")
local aa = af*fixed.constant(0.1)
local a = (af-aa):toRigelModule("a")
--local a = (aa):toRigelModule("a")

------------
ITYPE = types.array2d( types.int(32), T )
inp = R.input( ITYPE )
out = R.apply( "a", RM.map( a, T ), inp )
fn = RM.lambda( "fixed_wide", inp, out )
------------
hsfn = RM.makeHandshake(fn)

local OTYPE = types.array2d(types.float(32),T)

harness{ outFile="fixed_float_sub", fn=hsfn, inFile="trivial_64.raw", inSize={W,H}, outSize={W,H} }