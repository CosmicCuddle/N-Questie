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
-- Standalone PART35 follow-up: leases for DEAD coroutines can be returned;
-- suspended or poisoned coroutines remain quarantined and block retry.
-- Even this fail-closed toy is NOT a production cancellation or shutdown plan.
local originalReaderGet=owner.GetStream
local epoch=0
local function newDriver()
  local busy=false
  local quarantine={}
  local published={revision=7,data="PREVIOUS"}
  local acquisitions=0
  local function state()
    return {busy=busy,quarantine=#quarantine,revision=published.revision,
      data=published.data,acquisitions=acquisitions}
  end
  local function run(opts)
    opts=opts or {}
    if busy then
      return {status="BUSY",leases=0,releases=0,quarantined=#quarantine}
    end
    busy=true
    local before=epoch
    local originalGet=owner.GetStream
    assert(originalGet==originalReaderGet,
      "reader interception not restored from a prior attempt")
    local leases={}
    owner.GetStream=function(self,mode)
      acquisitions=acquisitions+1
      if opts.failAcquire then error("SYNTHETIC_ACQUIRE_FAILURE",0) end
      local s=originalGet(self,mode)
      local originalFinished,originalLoad=s.finished,s.Load
      local lease={stream=s,done=false,poison=false,releases=0}
      leases[#leases+1]=lease
      s.finished=function(current,...)
        assert(current==s and not lease.done and not lease.poison,
          "invalid or duplicate stream return")
        if opts.failFinish then
          -- Fail before calling the actual pool-return implementation.
          lease.poison=true
          error("SYNTHETIC_FINISH_FAILURE",0)
        end
        current.finished=originalFinished
        current.Load=originalLoad
        local ok,err=pcall(originalFinished,current,...)
        if not ok then
          lease.poison=true
          error("FAILED_REAL_FINISHED: "..tostring(err),0)
        end
        lease.done=true
        lease.releases=lease.releases+1
      end
      if opts.stallDuringLoad then
        s.Load=function()
          while true do coroutine.yield("SUSPENDED_DURING_REAL_HANDLE_LOAD") end
        end
      elseif opts.failLoad then
        s.Load=function() error("SYNTHETIC_LOAD_FAILURE",0) end
      end
      return s
    end
    local thread=coroutine.create(function()
      if opts.stallBeforeAcquire then
        while true do coroutine.yield("SUSPENDED_BEFORE_ACQUIRE") end
      end
      -- Actual pinned compiler, actual pointer decode and source reader.
      local handle=compiler:GetDBHandle("X",opts.ptrs or validPtrs,skip,db.npcKeys,nil)
      assert(handle and handle.pointers and handle.pointers[101]==1,
        "unmasked pointer readback mismatch")
      if opts.stallAfterHandle then
        while true do coroutine.yield("SUSPENDED_AFTER_HANDLE") end
      end
      if epoch~=before then error("SOURCE_EPOCH_CHANGED",0) end
      if opts.failAfterHandle then error("SYNTHETIC_READBACK_FAILURE",0) end
      handle.stream:finished()
      return "SUCCESS"
    end)
    local status,reason,yields=nil,nil,0
    for _=1,(opts.budget or 16) do
      local ok,value=coroutine.resume(thread)
      if not ok then
        reason=tostring(value)
        status=reason:find("SOURCE_EPOCH_CHANGED",1,true) and "RETRY" or "ERROR"
        break
      end
      if coroutine.status(thread)=="dead" then
        status=value
        break
      end
      yields=yields+1
      for _,lease in ipairs(leases) do
        assert(not lease.done, "released reader lease while coroutine suspended")
      end
      if opts.transientABA and yields==1 then
        epoch=epoch+1
        epoch=epoch+1
      end
    end
    local dead=(coroutine.status(thread)=="dead")
    if not status then
      assert(not dead, "exhausted budget after a dead coroutine")
      status="ABORTED_SUSPENDED"
      reason="BOUNDED_RESUME_EXHAUSTED"
    end
    -- Always remove only our test interception, even when suspended.
    -- The quarantine below still owns the suspended coroutine and its streams.
    owner.GetStream=originalGet
    local releases=0
    local poisoned=false
    if dead then
      for _,lease in ipairs(leases) do
        if not lease.done and not lease.poison then
          -- pcall occurs only AFTER resume has finished, never across yields.
          local ok,err=pcall(function()lease.stream:finished()end)
          if not ok then
            lease.poison=true
            reason="FINISH_CLEANUP_FAILED: "..tostring(err)
            status="ERROR"
          end
        end
        releases=releases+lease.releases
        poisoned=poisoned or lease.poison or not lease.done
      end
    else
      for _,lease in ipairs(leases) do
        assert(not lease.done and not lease.poison and lease.releases==0,
          "suspended stream was returned to pool before quarantine")
      end
    end
    if not dead or poisoned then
      quarantine[#quarantine+1]={thread=thread,leases=leases,
        why=reason,wasDead=dead}
      -- Deliberately keep busy: there is no safe in-process termination of
      -- a suspended Lua5.1 coroutine. Any retry needs a controlled reset.
    else
      busy=false
    end
    if status=="SUCCESS" and dead and not poisoned then
      published.revision=published.revision+1
      published.data="VERIFIED"
    end
    return {status=status,reason=reason,leases=#leases,
      releases=releases,quarantined=#quarantine,yields=yields,dead=dead}
  end
  return run,state
end
local count=0
local function check(name,fn)
  local ok,why=pcall(fn)
  if not ok then io.stderr:write("FAIL QUARANTINE "..name..": "..tostring(why).."\n");os.exit(1) end
  count=count+1
  print("PASS QUARANTINE "..name)
end
check("real_pinned_success_commits_only_after_dead_release",function()
  local run,snapshot=newDriver()
  local r=run()
  local s=snapshot()
  assert(r.status=="SUCCESS" and r.dead and r.releases==1 and r.leases==1)
  assert(s.revision==8 and s.data=="VERIFIED" and not s.busy)
end)
check("malformed_pointer_dead_error_releases_and_unlocks",function()
  local run,snapshot=newDriver()
  local r=run({ptrs=string.char(0)})
  local s=snapshot()
  assert(r.status=="ERROR" and r.dead and r.releases==1)
  assert(not s.busy and s.revision==7 and s.quarantine==0)
end)
check("throwing_load_dead_error_releases_and_unlocks",function()
  local run,snapshot=newDriver()
  local r=run({failLoad=true})
  local s=snapshot()
  assert(r.status=="ERROR" and r.reason:find("SYNTHETIC_LOAD_FAILURE",1,true))
  assert(r.dead and r.releases==1 and not s.busy and s.revision==7)
end)
check("terminal_error_to_repaired_success_is_retryable",function()
  local run,snapshot=newDriver()
  assert(run({ptrs=string.char(0)}).status=="ERROR")
  assert(run().status=="SUCCESS")
  local s=snapshot()
  assert(s.revision==8 and not s.busy and s.acquisitions==2)
end)
check("preacquisition_exhaustion_quarantines_coroutine_zero_streams",function()
  local run,snapshot=newDriver()
  local r=run({stallBeforeAcquire=true,budget=5})
  local s=snapshot()
  assert(r.status=="ABORTED_SUSPENDED" and not r.dead)
  assert(r.leases==0 and r.releases==0 and r.yields==5)
  assert(s.busy and s.quarantine==1 and s.acquisitions==0 and s.revision==7)
  assert(owner.GetStream==originalReaderGet)
end)
check("actual_prehandle_load_stall_quarantines_unreturned_reader",function()
  local run,snapshot=newDriver()
  local r=run({stallDuringLoad=true,budget=9})
  local s=snapshot()
  assert(r.status=="ABORTED_SUSPENDED" and not r.dead)
  assert(r.leases==1 and r.releases==0 and r.yields==9)
  assert(s.busy and s.quarantine==1 and s.acquisitions==1 and s.revision==7)
  assert(owner.GetStream==originalReaderGet)
end)
check("actual_posthandle_stall_quarantines_stream_after_decode",function()
  local run,snapshot=newDriver()
  local r=run({stallAfterHandle=true,budget=9})
  local s=snapshot()
  assert(r.status=="ABORTED_SUSPENDED" and not r.dead)
  assert(r.leases==1 and r.releases==0 and r.yields==9)
  assert(s.busy and s.quarantine==1 and s.acquisitions==1 and s.revision==7)
  assert(owner.GetStream==originalReaderGet)
end)
check("quarantined_suspended_owner_rejects_next_compile_without_acquire",function()
  local run,snapshot=newDriver()
  assert(run({stallAfterHandle=true,budget=8}).status=="ABORTED_SUSPENDED")
  local s=snapshot()
  local blocked=run()
  assert(blocked.status=="BUSY" and blocked.leases==0 and blocked.releases==0)
  local after=snapshot()
  assert(after.acquisitions==s.acquisitions and after.revision==7)
  assert(after.busy and after.quarantine==1 and owner.GetStream==originalReaderGet)
end)
check("failed_finished_quarantines_even_dead_coroutine",function()
  local run,snapshot=newDriver()
  local r=run({failFinish=true})
  local s=snapshot()
  assert(r.status=="ERROR" and r.dead)
  assert(r.reason:find("SYNTHETIC_FINISH_FAILURE",1,true))
  assert(r.leases==1 and r.releases==0 and r.quarantined==1)
  assert(s.busy and s.revision==7 and s.quarantine==1)
  assert(owner.GetStream==originalReaderGet and run().status=="BUSY")
end)
check("posthandle_error_does_not_commit_and_cleans_dead_reader",function()
  local run,snapshot=newDriver()
  local r=run({failAfterHandle=true})
  local s=snapshot()
  assert(r.status=="ERROR" and r.dead and r.releases==1)
  assert(not s.busy and s.revision==7 and s.quarantine==0)
end)
check("real_source_epoch_aba_retry_does_not_commit",function()
  local run,snapshot=newDriver()
  local r=run({transientABA=true})
  local s=snapshot()
  assert(r.status=="RETRY" and r.dead and r.releases==1)
  assert(not s.busy and s.revision==7 and s.quarantine==0)
end)
check("clean_successful_pool_reuse_returns_every_lease_once",function()
  local run,snapshot=newDriver()
  local a,b=run(),run()
  local s=snapshot()
  assert(a.status=="SUCCESS" and a.releases==1)
  assert(b.status=="SUCCESS" and b.releases==1)
  assert(s.revision==9 and s.quarantine==0 and not s.busy and s.acquisitions==2)
end)
assert(count==12,"expected 12 checks")
assert(owner.GetStream==originalReaderGet,"pinned GetStream method remains intercepted")
print("QUARANTINE CONTRACT RESULT: 12/12 PASS")
print("TEST ONLY: fail-stop suspended-thread quarantine, original compiler untouched")
