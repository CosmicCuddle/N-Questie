-- Isolated CS01 scratch only. Fictional fixture IDs; NO real quest/source data.
-- Executed under Lua 5.1 with actual pinned Modules/QuestieStream.lua and Database/compiler.lua.
local function die(x) io.stderr:write("FAIL SOURCE_SETUP: "..tostring(x).."\n");os.exit(1) end
if not bit then
  local function band(a,b)
    a,b=a%4294967296,b%4294967296
    local n,p=0,1
    for i=1,32 do
      if a%2==1 and b%2==1 then n=n+p end
      a,b,p=math.floor(a/2),math.floor(b/2),p*2
    end
    return n
  end
  bit={band=band,lshift=function(n,s)return (n*2^s)%4294967296 end,
       rshift=function(n,s)return math.floor((n%4294967296)/2^s) end}
end
tremove=tremove or table.remove
unpack=unpack or table.unpack
QuestieLoader={}
local modules={}
function QuestieLoader:CreateModule(k)
  if modules[k] then die("duplicate module "..k) end
  modules[k]={};return modules[k]
end
function QuestieLoader:ImportModule(k)
  if not modules[k] then die("missing module "..k) end
  return modules[k]
end
for _,key in ipairs({"QuestieDB","QuestieLib","l10n"}) do QuestieLoader:CreateModule(key) end
QuestieCompat={WOW_PROJECT_ID=2,Is335=true}
Questie={IsSoD=false,IsWotlk=true,IsTBC=false,db={global={},profile={debugEnabled=false}}}
function Questie:Error(...)die("unexpected Questie Error callback") end
assert(loadfile("Modules/QuestieStream.lua"))()
assert(loadfile("Database/compiler.lua"))()
local stream=QuestieLoader:ImportModule("QuestieStreamLib")
local codec=QuestieLoader:ImportModule("DBCompiler")
local function eq(a,b,path)
  assert(type(a)==type(b),path.." type mismatch: "..type(a).."/"..type(b))
  if type(a)~="table" then
    assert(a==b,path.." mismatch: "..tostring(a).."/"..tostring(b));return
  end
  for k,v in pairs(a) do eq(v,b[k],path.."."..tostring(k)) end
  for k in pairs(b) do assert(a[k]~=nil,path.." unexpected key "..tostring(k)) end
end
local function roundtrip(key,value,want)
  local writer,reader,skipper=codec.writers[key],codec.readers[key],codec.skippers[key]
  assert(type(writer)=="function" and type(reader)=="function" and
         type(skipper)=="function",key.." incomplete codec")
  local out=stream:GetStream("raw")
  writer(out,value)
  local binary=out:Save()
  assert(type(binary)=="string" and #binary>0,key.." empty stream")
  local input=stream:GetStream("raw")
  input:Load(binary)
  local got=reader(input)
  local ending=input._pointer
  eq(got,want,key)
  assert(ending==#binary+1,key.." reader under/over-consumption")
  input._pointer=1
  skipper(input)
  assert(input._pointer==ending,key.." skipper/reader boundary disagreement")
  input:finished();out:finished()
end
local passed=0
local function check(name,fn)
  local ok,err=pcall(fn)
  if not ok then io.stderr:write("FAIL "..name..": "..tostring(err).."\n");os.exit(1) end
  passed=passed+1;print("PASS "..name)
end
local spots={[141]={{-1,-1}}}
local ways={[141]={{{-1,-1}}}}
local cases={
  {"u8",12,12},
  {"u16",1023,1023},
  {"s16",-21,-21},
  {"u24",1048576,1048576},
  {"s24",-100,-100},
  {"u32",429496,429496},
  {"u12pair",{201,311},{201,311}},
  {"s24pair",{-12,47},{-12,47}},
  {"u8string","Fictional label","Fictional label"},
  {"u8u16stringarray",{"Fictional goal"},{"Fictional goal"}},
  {"u8u24array",{1001},{1001}},
  {"u16u24array",{9001},{9001}},
  {"u8s24pairs",{{1,-2}},{{1,-2}}},
  {"faction","AH","AH"},
  {"spawnlist",spots,spots},
  {"waypointlist",ways,ways},
  {"trigger",{"Signal",spots},{"Signal",spots}},
  {"questgivers",{{201},{302}},{{201},{302}}},
  {"objectives",{{{101,"Synthetic objective"}},nil,nil,{5,7}},{{{101,"Synthetic objective"}},nil,nil,{5,7}}},
  {"extraobjectives",{{spots,444,"Synthetic note",2,{{"monster",777}}}},{{spots,444,"Synthetic note",2,{{"monster",777}}}}}
}
assert(#cases==20,"Expected exactly twenty root codec cases")
for _,c in ipairs(cases) do
  local t=c
  check("root_"..t[1],function()roundtrip(t[1],t[2],t[3])end)
end
check("sentinel_root_nil",function()roundtrip("u8string","nil",nil)end)
check("sentinel_array_nil_literal",function()roundtrip("u8u16stringarray",{"nil"},{"nil"})end)
check("sentinel_zero_u12pair",function()roundtrip("u12pair",{0,0},nil)end)
check("sentinel_zero_s24pair",function()roundtrip("s24pair",{0,0},nil)end)
check("sentinel_nil_trigger",function()roundtrip("trigger",nil,nil)end)
check("sentinel_blank_objective",function()roundtrip("objectives",{{{211,""}}},{{{211}}})end)
assert(passed==26,"Expected exactly 26 checks, got "..passed)
print("SOURCE HARNESS RESULT: 26/26 PASS")
