-- Part 34: test-only bidirectional NPC / game-object owner research (Lua 5.1).
-- Every ID below is invented. NOT the production verifier; NO private data.
-- No coroutine-yield writer freeze, game-client performance, or item ownership.
local unpack = unpack or table.unpack
local QA,QB=990101,990102
local NA,NB,NC=991101,991102,991103
local GA,GB,GC=992101,992102,992103
local keys={quest={start=2,finish=3},npc={start=10,finish=11},go={start=2,finish=3}}
local function refuse(reason) error("OWNER CONTRACT "..reason,0) end
local function integer(v,maximum)
  return type(v)=="number" and v==math.floor(v) and v>=1 and v<=maximum
end
local function asSet(t,max,label)
  if t==nil then return {} end
  if type(t)~="table" then refuse("BAD_LIST "..label) end
  local seen,n,highest={},0,0
  for i,id in pairs(t) do
    if not integer(i,max) or not integer(id,16777215) then refuse("BAD_LIST "..label) end
    if seen[id] then refuse("DUPLICATE "..label) end
    seen[id]=true; n=n+1; if i>highest then highest=i end
  end
  if n~=highest then refuse("SPARSE "..label) end
  return seen
end
local function same(a,b)
  for id in pairs(a) do if not b[id] then return false end end
  for id in pairs(b) do if not a[id] then return false end end
  return true
end
local function field(rec,overrides,id,key)
  local patch=overrides and overrides[id]
  if patch and patch[key]~=nil then return patch[key] end
  return rec and rec[key]
end
local function tuple(kind,owner,q,role)
  return kind..":"..tostring(owner)..":"..tostring(q)..":"..role
end
local function nested(t,root,slot,label)
  if t~=nil and type(t)~="table" then refuse("BAD_LIST "..label) end
  return asSet(t and t[slot],255,label)
end
local function verify(plan,db)
  if type(plan)~="table" or type(db)~="table" then refuse("INVALID_INPUT") end
  local fwd,rev={},{}
  local kinds={{"npc",1,"npcStart","npcEnd"},{"go",2,"goStart","goEnd"}}
  for q,p in pairs(plan) do
    if not integer(q,16777215) or type(p)~="table" then refuse("BAD_QUEST_ID") end
    local raw=db.quests and db.quests[q]
    if type(raw)~="table" then refuse("MISSING_QUEST "..q) end
    local starts=field(raw,db.questOverrides,q,keys.quest.start)
    local ends=field(raw,db.questOverrides,q,keys.quest.finish)
    for _,kind in ipairs(kinds) do
      local name,slot,starter,finisher=unpack(kind)
      for _,relation in ipairs({{"start",starter,starts},{"end",finisher,ends}}) do
        local role,planKey,view=unpack(relation)
        local label=tostring(q)..":"..planKey
        local expected=asSet(p[planKey],255,label)
        local actual=nested(view,nil,slot,label)
        if not same(expected,actual) then refuse("FORWARD_MISMATCH "..label) end
        for id in pairs(expected) do fwd[tuple(name,id,q,role)]=true end
      end
    end
  end
  -- Read ALL owners, not just the owners listed in approved quest plans.
  for _,kind in ipairs(kinds) do
    local name=kind[1]
    local owners=db[name]
    if type(owners)~="table" then refuse("MISSING_CATEGORY "..name) end
    local patch=db[name.."Overrides"]
    -- Questie query overrides can supply a field for an ID absent from
    -- the compiled pointer map. The effective owner universe is the UNION
    -- of raw and override-only owner keys, not just raw owner records.
    local allOwners={}
    for id in pairs(owners) do allOwners[id]=true end
    for id in pairs(patch or {}) do allOwners[id]=true end
    for id in pairs(allOwners) do
      local record=owners[id]
      if type(record)=="table" or type(patch and patch[id])=="table" then
        for _,role in ipairs({"start","end"}) do
          local fieldKey=keys[name][role=="start" and "start" or "finish"]
          local raw=field(record,patch,id,fieldKey)
          if raw~=nil then
            local links=asSet(raw,255,name..":"..role)
            for quest in pairs(links) do
              if plan[quest] then
                if not integer(id,16777215) then refuse("BAD_OWNER_ID") end
                rev[tuple(name,id,quest,role)]=true
              end
            end
          end
        end
      end
    end
  end
  for k in pairs(fwd) do if not rev[k] then refuse("MISSING_REVERSE "..k) end end
  for k in pairs(rev) do if not fwd[k] then refuse("FOREIGN_REVERSE "..k) end end
  return true
end
local function deepCopy(t)
  if type(t)~="table" then return t end
  local c={}
  for k,v in pairs(t) do c[deepCopy(k)]=deepCopy(v) end
  return c
end
local original={
 plan={
   [QA]={npcStart={NA},npcEnd={NB},goStart={GA},goEnd={GB}},
   [QB]={npcStart={},npcEnd={NB},goStart={},goEnd={}}
 },
 db={
   quests={
     [QA]={[2]={{NA},{GA}},[3]={{NB},{GB}}},
     [QB]={[2]={{},{},{993101}},[3]={{NB}}}
   },
   npc={
     [NA]={[10]={QA}},[NB]={[11]={QA,QB}},
     [NC]={[10]={990999}}
   },
   go={
     [GA]={[2]={QA}},[GB]={[3]={QA}},[GC]={}
   },
   questOverrides={},npcOverrides={},goOverrides={}
 }
}
local tests,passed=0,0
local function probe(name,modify,shouldPass,expected)
  tests=tests+1
  local s=deepCopy(original)
  if modify then modify(s) end
  local ok,result=pcall(verify,s.plan,s.db)
  local correct=(shouldPass and ok and result==true) or
    (not shouldPass and not ok and type(result)=="string" and
     result:find("OWNER CONTRACT "..expected,1,true)~=nil)
  if not correct then
    io.stderr:write("FAIL OWNER "..name.." unexpected="..tostring(result).."\n")
    os.exit(1)
  end
  passed=passed+1; print("PASS OWNER "..name)
end
probe("clean item-only nested source",nil,true)
probe("order agnostic NPC source",function(s)
  s.plan[QA].npcStart={NC,NA}
  s.db.quests[QA][2][1]={NA,NC}
  s.db.npc[NC][10]={990999,QA}
end,true)
probe("foreign NPC start",function(s) s.db.npc[NC][10]={QA} end,false,"FOREIGN_REVERSE")
probe("foreign NPC end",function(s) s.db.npc[NC][11]={QA} end,false,"FOREIGN_REVERSE")
probe("foreign GO start",function(s) s.db.go[GC][2]={QA} end,false,"FOREIGN_REVERSE")
probe("foreign GO end",function(s) s.db.go[GC][3]={QA} end,false,"FOREIGN_REVERSE")
probe("missing NPC start",function(s) s.db.npc[NA][10]=nil end,false,"MISSING_REVERSE")
probe("missing NPC end",function(s) s.db.npc[NB][11]={QB} end,false,"MISSING_REVERSE")
probe("missing GO start",function(s) s.db.go[GA][2]=nil end,false,"MISSING_REVERSE")
probe("missing GO end",function(s) s.db.go[GB][3]=nil end,false,"MISSING_REVERSE")
probe("reverse role swap",function(s) s.db.go[GA][2]=nil;s.db.go[GA][3]={QA} end,false,"MISSING_REVERSE")
probe("quest forward drift",function(s) s.db.quests[QA][2][1]={NC} end,false,"FORWARD_MISMATCH")
probe("quest faction override drift",function(s) s.db.questOverrides[QA]={[2]={{NC},{GA}}} end,false,"FORWARD_MISMATCH")
probe("NPC override removes owner",function(s) s.db.npcOverrides[NA]={[10]={990999}} end,false,"MISSING_REVERSE")
probe("NPC override foreign owner",function(s) s.db.npcOverrides[NC]={[10]={QA}} end,false,"FOREIGN_REVERSE")
probe("GO override removes owner",function(s) s.db.goOverrides[GB]={[3]={990999}} end,false,"MISSING_REVERSE")
probe("GO override foreign owner",function(s) s.db.goOverrides[GC]={[2]={QA}} end,false,"FOREIGN_REVERSE")
probe("unrelated name override",function(s) s.db.npcOverrides[NA]={[1]="Changed name"} end,true)
probe("unrelated original GO quest",function(s) s.db.go[GC][2]={990999} end,true)
probe("duplicate NPC reverse",function(s) s.db.npc[NA][10]={QA,QA} end,false,"DUPLICATE")
probe("sparse NPC reverse",function(s) s.db.npc[NA][10]={[1]=QA,[3]=990999} end,false,"SPARSE")
probe("over 255 reverse entries",function(s)
  local ids={QA};for i=2,256 do ids[i]=700000+i end;s.db.npc[NA][10]=ids
end,false,"BAD_LIST")
probe("invalid approved quest ID",function(s) s.plan[0]=s.plan[QA] end,false,"BAD_QUEST_ID")
probe("missing approved quest",function(s) s.db.quests[QA]=nil end,false,"MISSING_QUEST")
probe("sparse forward NPC list",function(s) s.db.quests[QA][2][1]={[2]=NA} end,false,"SPARSE")
probe("unrelated existing NPC owner",function(s) s.db.npc[NC][11]={990999} end,true)
probe("missing GO owner record",function(s) s.db.go[GA]=nil end,false,"MISSING_REVERSE")
probe("override-only NPC foreign owner",function(s)
  s.db.npcOverrides[991104]={[10]={QA}}
end,false,"FOREIGN_REVERSE")
probe("override-only unrelated NPC owner",function(s)
  s.db.npcOverrides[991104]={[10]={990999}}
end,true)
if tests~=29 or passed~=29 then error("wrong synthetic test count") end
print("OWNER REVERSE PROPOSAL RESULT: 29/29 PASS")
print("TEST ONLY: excludes compiler-yield freeze, live client and item source proof")
