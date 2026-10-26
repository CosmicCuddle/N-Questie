-- Part34 standalone effective post-correction fixture. Lua 5.1 syntax.
-- Every quest, NPC, GO and item ID below is invented; never real server data.
-- TEST ONLY: neither a production owner verifier nor a compiler-yield freeze.
local path = assert(os.getenv("NQ_LOADER_PATH"), "NQ_LOADER_PATH required")
local Q={name=1,startedBy=2,finishedBy=3,requiredLevel=4,questLevel=5,
  requiredRaces=6,requiredClasses=7,objectives=10,preQuestGroup=12,
  preQuestSingle=13,exclusiveTo=16,zoneOrSort=17,
  nextQuestInChain=22,questFlags=23,specialFlags=24}
local N={questStarts=10,questEnds=11}
local G={questStarts=2,questEnds=3}
local I={startQuest=5}
local K={npc={tableKey="npcData",start=N.questStarts,finish=N.questEnds},
  go={tableKey="objectData",start=G.questStarts,finish=G.questEnds}}
local A,B,C,D=940001,940002,940003,940004
local NA,NB,NX=7715,7716,7711
local GA,GB,GX=8816,8817,8811
local IA,IB,IX=6611,6612,6614

local function record(changes)
  local q={name="Entirely fictional",requiredLevel=20,questLevel=25,
    zoneOrSort=130,requiredRaces=0,questFlags=0,
    startedByNpcs={NA},finishedByNpcs={NB},killNpcs={7712}}
  for key,value in pairs(changes or {}) do q[key]=value end
  return q
end
local function newDatabase()
  return {
    questKeys=Q,npcKeys=N,objectKeys=G,itemKeys=I,
    questData={[990900]={[Q.name]="Unrelated fictional quest"}},
    npcData={
      [NA]={[1]="Starter",[N.questStarts]={990900}},
      [NB]={[1]="Finisher"},
      [NX]={[1]="Unrelated owner",[N.questStarts]={990900}},
      [7712]={[1]="Fictional objective NPC"},
    },
    objectData={
      [GA]={[1]="GO starter"},
      [GB]={[1]="GO finisher"},
      [GX]={[1]="Unrelated GO",[G.questStarts]={990900}},
    },
    itemData={
      [IA]={[1]="Fictional starter item"},
      [IB]={[1]="Other fictional starter item"},
      [IX]={[1]="Unrelated item"},
    },
    questOverrides={},npcOverrides={},goOverrides={},itemOverrides={},
  }
end
local function newCustom()
  return {revision=12,quests={
    [A]=record({}),
    [B]=record({startedByNpcs={},finishedByNpcs={},
      startedByGameObjects={GA},finishedByGameObjects={GB}}),
    [C]=record({startedByNpcs={},startedByItems={IA},
      finishedByNpcs={NB}}),
    [D]=record({startedByNpcs={NA},startedByItems={IB},
      finishedByNpcs={NB}}),
  }}
end
local function clone(value)
  if type(value)~="table" then return value end
  local output={}
  for key,item in pairs(value) do output[clone(key)]=clone(item) end
  return output
end
local function build(order)
  local db=newDatabase()
  local callbacks={}
  QuestieLoader={ImportModule=function(_,name)
    assert(name=="QuestieDB")
    return db
  end}
  QuestieCompat={Is335=true,RegisterCorrection=function(kind,fn)
    assert(not callbacks[kind], "duplicate correction kind")
    callbacks[kind]=fn
  end}
  NQuestieCustomQuestData=newCustom()
  assert(loadfile(path))()
  for _,kind in ipairs({"questData","npcData","objectData","itemData"}) do
    assert(type(callbacks[kind])=="function","missing correction callback "..kind)
  end
  -- Apply all four *actual loader* callback result tables. Deliberately
  -- exercise every category order: Questie iterates correction categories
  -- with pairs(), not a guaranteed global sequence.
  for _,kind in ipairs(order) do
    local updates=callbacks[kind]()
    assert(type(updates)=="table")
    for id,fields in pairs(updates) do
      db[kind][id]=db[kind][id] or {}
      for key,value in pairs(fields) do db[kind][id][key]=clone(value) end
    end
  end
  for questId in pairs(NQuestieCustomQuestData.quests) do
    assert(type(db.questData[questId])=="table","accepted quest not applied: "..questId)
  end
  assert(QuestieCompat.VerifyNQuestieCustomItemSources()==true,
    "pinned item-source postflight should accept the fully-applied fixture")
  return {db=db,custom=NQuestieCustomQuestData,compat=QuestieCompat}
end

local function refusal(reason) error("EFFECTIVE FIXTURE "..reason,0) end
local function ids(value)
  if value==nil then return {} end
  if type(value)~="table" then refusal("BAD_RELATION") end
  local seen,n,high={},0,0
  for pos,id in pairs(value) do
    if type(pos)~="number" or pos~=math.floor(pos) or pos<1 or pos>255
      or type(id)~="number" or id~=math.floor(id) or id<1 or id>16777215
      or seen[id] then
      refusal("BAD_RELATION")
    end
    seen[id]=true
    n=n+1
    if pos>high then high=pos end
  end
  if n~=high then refusal("BAD_RELATION") end
  return seen
end
local function same(a,b)
  for id in pairs(a) do if not b[id] then return false end end
  for id in pairs(b) do if not a[id] then return false end end
  return true
end
local function effective(raw,overrides,id,key)
  local patch=overrides and overrides[id]
  if patch and patch[key]~=nil then return patch[key] end
  return raw and raw[key]
end
local function relationSlot(row,key,slot)
  local slots=row and row[key]
  return slots and slots[slot] or nil
end
local function tuple(kind,owner,quest,role)
  return kind..":"..owner..":"..quest..":"..role
end
local function closed(state)
  local db,plan=state.db,state.custom.quests
  local fwd,rev,approvedItem={}
  -- forward fields MUST match the complete approved synthetic plan, not
  -- just contain its values (both forward superset and subset rejected).
  for questId,q in pairs(plan) do
    local row=db.questData[questId]
    if not row then refusal("MISSING_QUEST") end
    for _,kind in ipairs({"npc","go"}) do
      local sourceStart=kind=="npc" and "startedByNpcs" or "startedByGameObjects"
      local sourceEnd=kind=="npc" and "finishedByNpcs" or "finishedByGameObjects"
      local slot=kind=="npc" and 1 or 2
      for _,relation in ipairs({
        {"start",Q.startedBy,sourceStart},
        {"finish",Q.finishedBy,sourceEnd}
      }) do
        local role,key,planKey=relation[1],relation[2],relation[3]
        local expected,actual=ids(q[planKey]),ids(relationSlot(row,key,slot))
        if not same(expected,actual) then refusal("FORWARD_MISMATCH") end
        for ownerId in pairs(expected) do
          fwd[tuple(kind,ownerId,questId,role)]=true
        end
      end
    end
    local expectedItems=ids(q.startedByItems)
    local actualItems=ids(relationSlot(row,Q.startedBy,3))
    if not same(expectedItems,actualItems) then refusal("ITEM_FORWARD_MISMATCH") end
    for itemId in pairs(expectedItems) do
      if approvedItem[itemId] and approvedItem[itemId]~=questId then
        refusal("ITEM_CONTESTED")
      end
      approvedItem[itemId]=questId
    end
  end
  -- Reverse scan covers *all* raw and override-only NPC/GO owner IDs.
  for _,kind in ipairs({"npc","go"}) do
    local spec=K[kind]
    local owners=db[spec.tableKey]
    local overrides=db[kind.."Overrides"]
    local universe={}
    for id in pairs(owners) do universe[id]=true end
    for id in pairs(overrides) do universe[id]=true end
    for ownerId in pairs(universe) do
      for _,role in ipairs({"start","finish"}) do
        local field=spec[role]
        local links=ids(effective(owners[ownerId],overrides,ownerId,field))
        for questId in pairs(links) do
          if plan[questId] then
            rev[tuple(kind,ownerId,questId,role)]=true
          end
        end
      end
    end
  end
  for key in pairs(fwd) do if not rev[key] then refusal("MISSING_REVERSE") end end
  for key in pairs(rev) do if not fwd[key] then refusal("FOREIGN_REVERSE") end end
  -- An item starter is a scalar. Include override-only item IDs in the scan,
  -- rather than confusing an objective item with a direct item source.
  local itemUniverse={}
  for id in pairs(db.itemData) do itemUniverse[id]=true end
  for id in pairs(db.itemOverrides) do itemUniverse[id]=true end
  for id in pairs(itemUniverse) do
    local owner=effective(db.itemData[id],db.itemOverrides,id,I.startQuest)
    if plan[owner] and approvedItem[id]~=owner then
      refusal("FOREIGN_ITEM")
    end
  end
  for itemId,questId in pairs(approvedItem) do
    if effective(db.itemData[itemId],db.itemOverrides,itemId,I.startQuest)~=questId then
      refusal("MISSING_ITEM")
    end
  end
  return true
end

local checks=0
local order={"questData","npcData","objectData","itemData"}
local function check(label,condition)
  checks=checks+1
  if not condition then error("FAIL FULL "..label,0) end
  print("PASS FULL "..label)
end
local function permutation(prefix,unused)
  if #unused==0 then
    local state=build(prefix)
    local ok,result=pcall(closed,state)
    check("complete correction order "..table.concat(prefix,">"),
      ok and result==true)
    return
  end
  for index,kind in ipairs(unused) do
    local nextOrder={}
    for _,x in ipairs(prefix) do nextOrder[#nextOrder+1]=x end
    nextOrder[#nextOrder+1]=kind
    local rest={}
    for i,x in ipairs(unused) do if i~=index then rest[#rest+1]=x end end
    permutation(nextOrder,rest)
  end
end
permutation({},order)

local function mutation(label,modify,expected)
  local state=build(order)
  modify(state.db)
  local ok,message=pcall(closed,state)
  check(label,not ok and type(message)=="string" and
    message:find("EFFECTIVE FIXTURE "..expected,1,true)~=nil)
end
mutation("foreign NPC reverse owner refused",function(db)
  db.npcData[NX][N.questStarts]={A}
end,"FOREIGN_REVERSE")
mutation("missing NPC reverse owner refused",function(db)
  db.npcData[NA][N.questStarts]={990900}
end,"MISSING_REVERSE")
mutation("GO start/finish swap refused",function(db)
  db.objectData[GB][G.questStarts]={B}
end,"FOREIGN_REVERSE")
mutation("changed quest NPC starter refused",function(db)
  db.questData[A][Q.startedBy][1]={NB}
end,"FORWARD_MISMATCH")
mutation("changed quest item starter refused",function(db)
  db.questData[C][Q.startedBy][3]={IB}
end,"ITEM_FORWARD_MISMATCH")
mutation("foreign item scalar back-reference refused",function(db)
  db.itemData[IX][I.startQuest]=C
end,"FOREIGN_ITEM")
mutation("quest faction override drift refused",function(db)
  db.questOverrides[D]={[Q.startedBy]={{NB},nil,{IB}}}
end,"FORWARD_MISMATCH")
mutation("override-only NPC reverse owner refused",function(db)
  db.npcOverrides[7799]={[N.questStarts]={A}}
end,"FOREIGN_REVERSE")
mutation("override-only GO reverse owner refused",function(db)
  db.goOverrides[8899]={[G.questEnds]={B}}
end,"FOREIGN_REVERSE")
mutation("override-only item scalar owner refused",function(db)
  db.itemOverrides[6699]={[I.startQuest]=C}
end,"FOREIGN_ITEM")
local clean=build(order)
clean.db.npcOverrides[NX]={[1]="Unrelated cosmetic name"}
check("unrelated owner overrides remain allowed",closed(clean)==true)

if checks~=35 then error("FULL FIXTURE expected 35 checks, got "..checks,0) end
print("FULL EFFECTIVE CORRECTIONS RESULT: 35/35 PASS")
print("TEST ONLY: complete fictional correction fixture; not a production write-freeze or client integration")
