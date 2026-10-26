-- Part 35: independent Lua 5.1-safe coroutine driver lease proposal.
-- TEST ONLY: execute pinned, unmodified Questie GetDBHandle and stream code.
-- No live SavedVariables, private sources, production patch or game client.
tremove=tremove or table.remove
unpack=unpack or table.unpack
local function band(a,b)
  a,b=a%4294967296,b%4294967296
  local n,p=0,1
  for _=1,32 do
    if a%2==1 and b%2==1 then n=n+p end
    a,b,p=math.floor(a/2),math.floor(b/2),p*2
  end
  return n
end
bit={band=band,lshift=function(n,s) return (n*2^s)%4294967296 end,
     rshift=function(n,s) return math.floor((n%4294967296)/2^s)end}
QuestieLoader={}
local modules={}
function QuestieLoader:CreateModule(name)
  assert(not modules[name],"duplicate module "..name)
  modules[name]={}
  return modules[name]
end
function QuestieLoader:ImportModule(name)
  assert(modules[name],"missing module "..name)
  return modules[name]
end
for _,name in ipairs({"QuestieDB","QuestieLib","l10n"}) do
  QuestieLoader:CreateModule(name)
end
QuestieCompat={WOW_PROJECT_ID=2,Is335=true}
Questie={IsSoD=false,IsWotlk=true,IsTBC=false,db={global={},profile={debugEnabled=false}}}
function Questie:Error(...) error("unexpected Questie error",0) end
GetTime=function() return 1 end
local lib=QuestieLoader:ImportModule("QuestieLib")
function lib:GetAddonVersionString() return "fiction" end
local loc=QuestieLoader:ImportModule("l10n")
function loc:GetUILocale() return "enUS" end
setmetatable(loc,{__call=function(_,message)return message end})
local function load(path)
  local file,err=loadfile(path)
  assert(file,"pinned source unavailable "..path..": "..tostring(err))
  file()
end
load("Modules/QuestieStream.lua")
for _,kind in ipairs({"npc","object","quest","item"})do
  load("Database/"..kind.."DB.lua")
end
load("Database/compiler.lua")
local compiler=QuestieLoader:ImportModule("DBCompiler")
local db=QuestieLoader:ImportModule("QuestieDB")
local streams=QuestieLoader:ImportModule("QuestieStreamLib")
local skip=compiler:BuildSkipMap(db.npcCompilerTypes,db.npcCompilerOrder)
local out=streams:GetStream("raw")
local validPtrs=compiler:EncodePointerMap(out,{[101]=1})
out:finished()
assert(type(validPtrs)=="string" and #validPtrs==8,"invalid real-source pointer setup")

-- The original compiler holds one stream object in a Lua upvalue. We only
-- instrument that object's GetStream method inside this fictional test.
local function readerOwner()
  for i=1,40 do
    local name,value=debug.getupvalue(compiler.GetDBHandle,i)
    if name=="QuestieStream" then
      assert(type(value)=="table" and type(value.GetStream)=="function")
      return value
    end
    if name==nil then break end
  end
  error("pinned GetDBHandle reader owner not found")
end
local owner=readerOwner()
local busy=false
local epoch=0
local published={revision=7,data="OLD"}
local function run(opts)
  opts=opts or {}
  if busy then return {status="BUSY",leases=0,releases=0,yields=0} end
  busy=true
  local originalGet=owner.GetStream
  local leases={}
  local generation=epoch
  owner.GetStream=function(self,mode)
    if opts.failAcquire then error("SYNTHETIC_ACQUIRE_FAILURE",0) end
    local s=originalGet(self,mode)
    local originalFinished,originalLoad=s.finished,s.Load
    local lease={stream=s,done=false,count=0}
    leases[#leases+1]=lease
    s.finished=function(current,...)
      assert(current==s and not lease.done,"double or wrong stream release")
      lease.done=true
      lease.count=lease.count+1
      current.finished=originalFinished
      current.Load=originalLoad
      return originalFinished(current,...)
    end
    if opts.failLoad then
      s.Load=function() error("SYNTHETIC_LOAD_FAILURE",0) end
    end
    return s
  end
  local thread=coroutine.create(function()
    local handle=compiler:GetDBHandle("X",opts.ptrs or validPtrs,skip,db.npcKeys,nil)
    assert(handle and handle.pointers and handle.pointers[101]==1,
      "pinned pointer decoding/readback mismatch")
    if epoch~=generation then error("SOURCE_EPOCH_CHANGED",0) end
    if opts.failAfterHandle then error("SYNTHETIC_READBACK_FAILURE",0) end
    handle.stream:finished()
    return "SUCCESS"
  end)
  local status,why,yields,wasBusyProbe=nil,nil,0,false
  for _=1,32 do
    local ok,value=coroutine.resume(thread)
    if not ok then
      why=tostring(value)
      status=(why:find("SOURCE_EPOCH_CHANGED",1,true) and "RETRY") or "ERROR"
      break
    end
    if coroutine.status(thread)=="dead" then
      status=value
      break
    end
    yields=yields+1
    -- Suspended streams are NEVER returned to their pool. This driver
    -- continues or fails the coroutine before lease finalization.
    for _,lease in ipairs(leases) do
      assert(not lease.done,"in-use stream returned while coroutine suspended")
    end
    if opts.aba and yields==1 then
      -- Effective data may return to original: the monotonic epoch does not.
      epoch=epoch+1
      epoch=epoch+1
    end
    if opts.probeBusy and yields==1 then
      local inner=run({})
      wasBusyProbe=(inner.status=="BUSY" and inner.leases==0)
    end
  end
  if not status then
    -- Do not pool streams owned by a still-suspended coroutine.
    error("lease fixture exceeded bounded resume budget")
  end
  assert(coroutine.status(thread)=="dead",
    "never pool stream from a live or suspended coroutine")
  owner.GetStream=originalGet
  -- The driver owns leases even if GetDBHandle errors before it returns a
  -- handle. Return only unreleased streams, exactly once.
  for _,lease in ipairs(leases) do
    if not lease.done then
      local s=lease.stream
      local finished=s.finished
      s:finished()
      assert(finished~=nil)
    end
  end
  local releases=0
  for _,lease in ipairs(leases) do
    assert(lease.done and lease.count==1,"missing/double released lease")
    releases=releases+lease.count
  end
  busy=false
  if status=="SUCCESS" then
    published.revision=published.revision+1
    published.data="COMMITTED"
  end
  return {status=status,error=why,leases=#leases,
    releases=releases,yields=yields,wasBusyProbe=wasBusyProbe}
end
local tests=0
local function check(name,fn)
  local ok,err=pcall(fn)
  if not ok then io.stderr:write("FAIL LEASE "..name..": "..tostring(err).."\n");os.exit(1) end
  tests=tests+1
  print("PASS LEASE "..name)
end
local function state() return published.revision,published.data end
local function unchanged(revision,data)
  assert(published.revision==revision and published.data==data,
    "failure illegally published revision or cache")
end
check("real_pinned_handle_success_releases_once",function()
  local before=published.revision
  local r=run()
  assert(r.status=="SUCCESS" and r.leases==1 and r.releases==1 and r.yields>=3)
  assert(published.revision==before+1 and published.data=="COMMITTED")
end)
check("malformed_prehandle_pointer_error_releases_once",function()
  local rev,data=state()
  local r=run({ptrs=string.char(0)})
  assert(r.status=="ERROR" and r.leases==1 and r.releases==1)
  unchanged(rev,data)
end)
check("synthetic_reader_load_throw_releases_once",function()
  local rev,data=state()
  local r=run({failLoad=true})
  assert(r.status=="ERROR" and r.leases==1 and r.releases==1)
  assert(r.error:find("SYNTHETIC_LOAD_FAILURE",1,true))
  unchanged(rev,data)
end)
check("posthandle_failure_driver_releases_once",function()
  local rev,data=state()
  local r=run({failAfterHandle=true})
  assert(r.status=="ERROR" and r.leases==1 and r.releases==1)
  unchanged(rev,data)
end)
check("acquire_failure_has_no_owned_stream",function()
  local rev,data=state()
  local r=run({failAcquire=true})
  assert(r.status=="ERROR" and r.leases==0 and r.releases==0)
  unchanged(rev,data)
end)
check("transient_aba_writer_refuses_commit",function()
  local rev,data=state()
  local r=run({aba=true})
  assert(r.status=="RETRY" and r.leases==1 and r.releases==1)
  unchanged(rev,data)
end)
check("nested_busy_refused_without_duplicate_acquire",function()
  local rev=published.revision
  local r=run({probeBusy=true})
  assert(r.status=="SUCCESS" and r.wasBusyProbe and r.leases==1 and r.releases==1)
  assert(published.revision==rev+1)
end)
check("failed_then_repaired_pointer_retry_succeeds",function()
  local rev,data=state()
  local first=run({ptrs=string.char(0)})
  assert(first.status=="ERROR" and first.releases==1)
  unchanged(rev,data)
  local second=run()
  assert(second.status=="SUCCESS" and second.releases==1)
  assert(published.revision==rev+1)
end)
check("no_double_release_after_pool_reuse",function()
  local rev=published.revision
  local one=run()
  local two=run()
  assert(one.status=="SUCCESS" and two.status=="SUCCESS")
  assert(one.releases==1 and two.releases==1 and published.revision==rev+2)
end)
assert(tests==9,"expected 9 driver lease checks")
print("DRIVER LEASE PROPOSAL RESULT: 9/9 PASS")
print("TEST ONLY: pinned source wrapped by a fictional coroutine owner; production unmodified")