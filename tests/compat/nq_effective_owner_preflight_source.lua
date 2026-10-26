-- Real N-Questie loader preflight against invented records only.
-- This is a production-path CANDIDATE, not proof of compiler-yield safety.
local path=assert(os.getenv("NQ_LOADER_PATH"),"NQ_LOADER_PATH required")
local Q={name=1,startedBy=2,finishedBy=3,requiredLevel=4,questLevel=5,
  requiredRaces=6,objectives=10,zoneOrSort=17,questFlags=23}
local N={questStarts=10,questEnds=11}
local G={questStarts=2,questEnds=3}
local I={startQuest=5}
local A=920101
local db={
  questKeys=Q,npcKeys=N,objectKeys=G,itemKeys=I,
  questData={}, npcData={
    [101]={[N.questStarts]={910000}},
    [102]={},[103]={},[199]={[N.questStarts]={910001}},
  },
  objectData={[201]={},[202]={},[299]={}},
  itemData={[301]={},[399]={[I.startQuest]=910002}},
  questDataOverrides={},npcDataOverrides={},
  objectDataOverrides={},itemDataOverrides={},
}
QuestieLoader={ImportModule=function(_,name)
  assert(name=="QuestieDB");return db
end}
local callbacks={}
QuestieCompat={Is335=true,RegisterCorrection=function(kind,fn)
  assert(not callbacks[kind],kind)
  callbacks[kind]=fn
end}
NQuestieCustomQuestData={revision=10,quests={
  [A]={
    name="Entirely Invented",requiredLevel=12,questLevel=14,
    zoneOrSort=141,requiredRaces=0,questFlags=0,
    startedByNpcs={101},finishedByNpcs={102},
    startedByGameObjects={201},finishedByGameObjects={202},
    startedByItems={301},killNpcs={103},
  },
}}
assert(loadfile(path))()
assert(type(QuestieCompat.VerifyNQuestieCustomEffectiveSources)=="function")
local count=0
local function check(label,condition)
  assert(condition,"FAIL EFFECTIVE OWNER "..label)
  count=count+1
  print("PASS OWNER "..label)
end
local function refusal(label,expected,change,restore)
  change()
  local ok,why=pcall(QuestieCompat.VerifyNQuestieCustomEffectiveSources)
  restore()
  check(label,not ok and type(why)=="string" and
    why:find("N-Questie effective owner preflight: "..expected,1,true)~=nil)
end
local all={}
for _,kind in ipairs({"questData","npcData","objectData","itemData"}) do
  all[kind]=assert(callbacks[kind](),kind)
end
for _,kind in ipairs({"questData","npcData","objectData","itemData"}) do
  for id,corrections in pairs(all[kind]) do
    db[kind][id]=db[kind][id] or {}
    for key,value in pairs(corrections) do db[kind][id][key]=value end
  end
end
local valid=QuestieCompat.VerifyNQuestieCustomEffectiveSources
local starts=db.questData[A][Q.startedBy]
local npc101=db.npcData[101]
local npc199=db.npcData[199]
local go201=db.objectData[201]
local item301=db.itemData[301]
local item399=db.itemData[399]
check("full corrected source graph accepted",valid()==true)
check("unrelated preexisting owner unaffected",npc101[N.questStarts][1]==910000
  and item399[I.startQuest]==910002)
refusal("NPC forward subset", "FORWARD_MISMATCH",function()
  starts[1]={}
end,function()starts[1]={101}end)
-- Same-cardinality NPC substitution detects compare-loop off-by-one defects.
refusal("NPC forward equal-sized substitution", "FORWARD_MISMATCH",function()
  starts[1]={199}
end,function()starts[1]={101}end)
refusal("GO forward superset", "FORWARD_MISMATCH",function()
  starts[2]={201,299}
end,function()starts[2]={201}end)
refusal("item forward subset", "ITEM_FORWARD_MISMATCH",function()
  starts[3]={}
end,function()starts[3]={301}end)
refusal("faction effective quest override refused", "FORWARD_MISMATCH",function()
  db.questDataOverrides[A]={[Q.startedBy]={{}, {201},{301}}}
end,function()db.questDataOverrides[A]=nil end)
-- Read an effective faction-style finisher override, not only startedBy.
refusal("faction effective finisher override refused", "FORWARD_MISMATCH",function()
  db.questDataOverrides[A]={[Q.finishedBy]={{199},{202}}}
end,function()db.questDataOverrides[A]=nil end)
refusal("missing NPC reverse", "MISSING_REVERSE",function()
  npc101[N.questStarts]={910000}
end,function()npc101[N.questStarts]={910000,A}end)
refusal("foreign NPC reverse", "FOREIGN_REVERSE",function()
  npc199[N.questStarts]={A}
end,function()npc199[N.questStarts]={910001}end)
refusal("missing GO reverse", "MISSING_REVERSE",function()
  go201[G.questStarts]={}
end,function()go201[G.questStarts]={A}end)
refusal("foreign GO reverse", "FOREIGN_REVERSE",function()
  db.objectData[299][G.questEnds]={A}
end,function()db.objectData[299][G.questEnds]=nil end)
refusal("override only foreign NPC owner", "FOREIGN_REVERSE",function()
  db.npcDataOverrides[9199]={[N.questStarts]={A}}
end,function()db.npcDataOverrides[9199]=nil end)
refusal("override missing planned GO backlink", "MISSING_REVERSE",function()
  db.objectDataOverrides[201]={[G.questStarts]={}}
end,function()db.objectDataOverrides[201]=nil end)
refusal("approved-related duplicate refused", "BAD_RELATION",function()
  npc101[N.questStarts]={910000,A,A}
end,function()npc101[N.questStarts]={910000,A}end)
refusal("foreign item scalar owner", "FOREIGN_ITEM",function()
  item399[I.startQuest]=A
end,function()item399[I.startQuest]=910002 end)
refusal("missing planned item scalar", "MISSING_ITEM",function()
  item301[I.startQuest]=nil
end,function()item301[I.startQuest]=A end)
refusal("override item scalar foreign owner", "FOREIGN_ITEM",function()
  db.itemDataOverrides[399]={[I.startQuest]=A}
end,function()db.itemDataOverrides[399]=nil end)
-- An override-only item with no base record must be scanned.
refusal("override-only foreign item owner", "FOREIGN_ITEM",function()
  db.itemDataOverrides[9399]={[I.startQuest]=A}
end,function()db.itemDataOverrides[9399]=nil end)
refusal("malformed source relation type", "BAD_RELATION",function()
  npc199[N.questEnds]="BAD"
end,function()npc199[N.questEnds]=nil end)
refusal("bad override category", "BAD_OVERRIDE_CATEGORY",function()
  db.npcDataOverrides=true
end,function()db.npcDataOverrides={} end)
refusal("bad override entry", "BAD_OVERRIDE_ENTRY",function()
  db.objectDataOverrides[299]=true
end,function()db.objectDataOverrides[299]=nil end)
local prev=npc199[N.questStarts]
npc199[N.questStarts]={910001,910001}
check("unrelated-only duplicate legacy tolerated",valid()==true)
npc199[N.questStarts]={[3]=910001}
check("unrelated-only sparse legacy tolerated",valid()==true)
npc199[N.questStarts]=prev
check("source unaffected after negative tests",valid()==true)
assert(count==25,"expected 25 synthetic source-owner checks, got "..count)
print("EFFECTIVE SOURCE OWNER RESULT: 25/25 PASS")
print("CANDIDATE ONLY: no compiler yield freeze, client/IP or release permission")
