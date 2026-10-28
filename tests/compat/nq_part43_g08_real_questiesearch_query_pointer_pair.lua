-- N-Questie Part43 G08: execute unchanged ORIGINAL protected 335 QuestieSearch.
-- Fictional, public-safe query datasets only; NO original compiler/stream/client.
local root=assert(os.getenv("NQ_G08_SEARCH_ORIGINAL_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local function read(path)
    local f=assert(io.open(root.."/"..path,"rb"),"SOURCE_MISSING:"..path)
    local s=assert(f:read("*a"));f:close()
    return s
end
local original=read("Modules/Journey/QuestieSearch.lua")
local searchResults=read("Modules/Journey/QuestieSearchResults.lua")
local availableQuests=read("Modules/Quest/AvailableQuests.lua")
local checks=0
local function check(ok,name)assert(ok,name);checks=checks+1 end
local function contains(s,needle)
    return s:find(needle,1,true)~=nil
end
check(contains(original,'function QuestieSearch:Search(rawQuery, searchType, queryType)'),
    "C01_ORIGINAL_SEARCH_FUNCTION_ANCHORED")
check(contains(original,"databaseQueryHandle = QuestieDB.QueryNPCSingle") and
    contains(original,"databaseKeys = QuestieDB.NPCPointers"),
    "C02_ORIGINAL_NPC_QUERY_POINTER_SEPARATE_READS")
check(contains(original,"databaseQueryHandle = QuestieDB.QueryQuestSingle") and
    contains(original,"databaseKeys = QuestieDB.QuestPointers"),
    "C03_ORIGINAL_QUEST_QUERY_POINTER_SEPARATE_READS")
check(contains(original,"databaseQueryHandle = QuestieDB.QueryObjectSingle") and
    contains(original,"databaseKeys = QuestieDB.ObjectPointers"),
    "C04_ORIGINAL_OBJECT_QUERY_POINTER_SEPARATE_READS")
check(contains(original,"databaseQueryHandle = QuestieDB.QueryItemSingle") and
    contains(original,"databaseKeys = QuestieDB.ItemPointers"),
    "C05_ORIGINAL_ITEM_QUERY_POINTER_SEPARATE_READS")
check(contains(searchResults,"query = QuestieDB.QueryNPCSingle") and
    contains(searchResults,"AddLinkedParagraph(details, \"npc\", startedBy[1]"),
    "C06_REAL_SEARCH_RESULTS_CAPTURES_AND_PASSES_QUERIES")
check(contains(availableQuests,
    "local questData = QuestieDB.QuestPointers or QuestieDB.questData"),
    "C07_REAL_AVAILABLE_QUESTS_POINTER_FALLBACK_ANCHORED")

local types={"npc","object","item","quest"}
local capitalize={npc="NPC",object="Object",item="Item",quest="Quest"}
local ids={
    npc={old={101,111},new={102,112}},
    object={old={201,211},new={202,212}},
    item={old={301,311},new={302,312}},
    quest={old={401,411},new={402,412}}
}
local db={}
local pairsByType={}
for _,kind in ipairs(types) do
    pairsByType[kind]={}
    for _,version in ipairs({"old","new"}) do
        local prefix=string.upper(version)
        local records={}
        local pointers={}
        for _,id in ipairs(ids[kind][version]) do
            records[id]={name=prefix.." token "..kind.." "..tostring(id)}
            pointers[id]=true
        end
        local q=function(id,key)
            return records[id] and records[id][key] or nil
        end
        pairsByType[kind][version]={query=q,pointers=pointers,records=records}
    end
end
local function setPart(kind,queryVersion,pointerVersion)
    local upper=capitalize[kind]
    db["Query"..upper.."Single"]=pairsByType[kind][queryVersion].query
    db[upper.."Pointers"]=pairsByType[kind][pointerVersion].pointers
end
local function setAll(version)
    for _,kind in ipairs(types) do setPart(kind,version,version)end
end
setAll("old")
local module
local loader={}
function loader:CreateModule(name)
    assert(name=="QuestieSearch","UNEXPECTED_CREATE_MODULE")
    module={}
    return module
end
function loader:ImportModule(name)
    assert(name=="QuestieDB","UNEXPECTED_IMPORT_MODULE")
    return db
end
local env={QuestieLoader=loader}
setmetatable(env,{__index=_G})
local exec
if _VERSION=="Lua 5.1" then
    exec=assert(loadstring(original,"=original_335_questiesearch"))
    setfenv(exec,env)
else
    exec=assert(load(original,"=original_335_questiesearch","t",env))
end
exec()
local function count(t)
    local n=0
    for _ in pairs(t or {}) do n=n+1 end
    return n
end
check(type(module.Search)=="function","C08_FULL_ORIGINAL_335_MODULE_EXECUTES")
check(#module.types==4 and module.types[1]=="npc" and
    module.types[4]=="quest","C09_ORIGINAL_SEARCH_FOUR_DATABASE_TYPES")
check(count(module:Search("old","npc"))==2,"C10_OLD_NPC_SEARCH_TWO_IDS")
check(count(module:Search("old","object"))==2,"C11_OLD_OBJECT_SEARCH_TWO_IDS")
check(count(module:Search("old","item"))==2,"C12_OLD_ITEM_SEARCH_TWO_IDS")
check(count(module:Search("old","quest"))==2,"C13_OLD_QUEST_SEARCH_TWO_IDS")
local four=module:ByName("old")
check(count(four.npc)==2,"C14_BYNAME_NPC_TWO")
check(count(four.object)==2,"C15_BYNAME_OBJECT_TWO")
check(count(four.item)==2,"C16_BYNAME_ITEM_TWO")
check(count(four.quest)==2,"C17_BYNAME_QUEST_TWO")
check(four.query=="old","C18_BYNAME_SEARCH_METADATA")
local exact=module:Search('"OLD token npc 101"',"npc")
check(count(exact)==1 and exact[101]==true,
    "C19_ORIGINAL_STRICT_QUOTED_EXACT_NAME")
check(count(module:Search('"OLD token npc"',"npc"))==0,
    "C20_STRICT_EXACT_NOT_SUBSTRING")
check(count(module:Search("ToKeN","npc"))==2,
    "C21_SEARCH_NAME_CASE_INSENSITIVE")
check(count(module:Search("101","npc","int"))==1,
    "C22_ORIGINAL_NUMERIC_ID_SEARCH")
check(module:Search("token","unsupported_type")==nil,
    "C23_UNKNOWN_TYPE_RETURNS_NIL")

-- The original source does two *independent* reads of query closure and
-- pointer map. A fabricated preexisting mixed facade can silently lose IDs.
local function fresh(query,kind,mode)
    module:ByName("__FICTIONAL_NONMATCH_SENTINEL__")
    return module:Search(query,kind,mode)
end
setPart("npc","old","new")
local ok,result=pcall(function()return fresh("new","npc")end)
check(ok,"C24_MIXED_NPC_PAIR_COMPLETES_WITHOUT_THROW")
check(count(result)==0,"C25_MIXED_OLD_QUERY_NEW_PTRS_SILENT_FALSE_NEGATIVE")
check(db.NPCPointers[102]==true and
    pairsByType.npc.old.query(102,"name")==nil,
    "C26_MIXED_NPC_SOURCE_FIELDS_ARE_INCOMPATIBLE")
setPart("npc","new","old")
check(count(fresh("old","npc"))==0,
    "C27_MIXED_NEW_QUERY_OLD_PTRS_SILENT_FALSE_NEGATIVE")
setPart("npc","new","new")
check(count(fresh("new","npc"))==2,
    "C28_MATCHING_NEW_NPC_PAIR_RECOVERS_RESULTS")
setPart("object","old","new")
check(count(fresh("new","object"))==0,
    "C29_MIXED_OBJECT_QUERY_PTRS_SILENT_FALSE_NEGATIVE")
setPart("object","new","new")
check(count(fresh("new","object"))==2,
    "C30_MATCHING_NEW_OBJECT_PAIR_RECOVERS_RESULTS")
setPart("item","old","new")
check(count(fresh("new","item"))==0,
    "C31_MIXED_ITEM_QUERY_PTRS_SILENT_FALSE_NEGATIVE")
setPart("item","new","new")
check(count(fresh("new","item"))==2,
    "C32_MATCHING_NEW_ITEM_PAIR_RECOVERS_RESULTS")
setPart("quest","old","new")
check(count(fresh("new","quest"))==0,
    "C33_MIXED_QUEST_QUERY_PTRS_SILENT_FALSE_NEGATIVE")
setPart("quest","new","new")
check(count(fresh("new","quest"))==2,
    "C34_MATCHING_NEW_QUEST_PAIR_RECOVERS_RESULTS")
local allNew=module:ByName("new")
check(count(allNew.npc)==2 and count(allNew.object)==2,
    "C35_ALL_NEW_GEN_NPC_OBJECT_QUERIES")
check(count(allNew.quest)==2 and count(allNew.item)==2,
    "C36_ALL_NEW_GEN_QUEST_ITEM_QUERIES")
check(allNew.npc[102]==true and allNew.npc[101]==nil,
    "C37_NEW_BYNAME_RESETS_LAST_RESULT")
local oldQueryAlias=pairsByType.npc.old.query
local oldPtrAlias=pairsByType.npc.old.pointers
check(oldQueryAlias(101,"name")=="OLD token npc 101",
    "C38_EARLIER_QUERY_ALIAS_STAYS_OLD")
check(oldPtrAlias[101]==true and oldPtrAlias[102]==nil,
    "C39_EARLIER_POINTER_ALIAS_STAYS_OLD")
db.NPCPointers=nil
local successNilPtr=pcall(function()module:Search("new","npc")end)
check(not successNilPtr,"C40_MISSING_POINTER_MAP_FAILS_IN_REAL_SEARCH")
db.NPCPointers=pairsByType.npc.new.pointers
db.QueryNPCSingle=nil
local successNilQuery=pcall(function()module:Search("new","npc")end)
check(not successNilQuery,"C41_MISSING_QUERY_CLOSURE_FAILS_IN_REAL_SEARCH")
setPart("npc","old","old")
module:ByName("__FICTIONAL_NONMATCH_SENTINEL__")
-- During one synchronous original Search, a synthetic query callback swaps
-- the facade globally after the first read. The function's already-captured
-- local query and pointer map remain on old generation throughout that call.
local oldOne=pairsByType.npc.old.query
local oldPtrs=pairsByType.npc.old.pointers
local mutated=0
db.QueryNPCSingle=function(id,key)
    mutated=mutated+1
    if mutated==1 then
        setPart("npc","new","new")
    end
    return oldOne(id,key)
end
db.NPCPointers=oldPtrs
local stable=module:Search("old","npc")
check(mutated==2,"C42_ORIGINAL_SEARCH_INVOKES_CAPTURED_LOCAL_TWICE")
check(count(stable)==2 and stable[101]==true and stable[111]==true,
    "C43_LOCAL_QUERY_PTRS_REMAIN_PAIRED_DURING_CALLBACK_SWAPPING")
check(db.NPCPointers==pairsByType.npc.new.pointers,
    "C44_FACADE_SWAPPED_WHILE_ORIGINAL_SEARCH_RAN")
check(count(fresh("new","npc"))==2,
    "C45_NEXT_SEARCH_USES_NEW_MATCHING_PAIR")
check(module.LastResult.query=="new",
    "C46_ORIGINAL_SEARCH_METADATA_LATEST")
check(oldQueryAlias(101,"name")=="OLD token npc 101" and
    oldPtrAlias[101]==true,
    "C47_OLD_EXPORTED_ALIASES_NOT_REBOUND_AFTER_SWAP")
-- Even a fully matched OLD-to-NEW facade transition can retain OLD IDs
-- if callers invoke :Search directly without :ByName's reset procedure.
setPart("npc","old","old")
module:ByName("__FICTIONAL_NONMATCH_SENTINEL__")
check(count(module:Search("old","npc"))==2,
    "C48_FRESH_OLD_SEARCH_CACHE_CONTAINS_ONLY_OLD_IDS")
setPart("npc","new","new")
local retained=module:Search("new","npc")
check(count(retained)==4 and retained[101]==true and retained[111]==true,
    "C49_DIRECT_SEARCH_CARRIES_OLD_IDS_IN_NEW_GENERATION")
check(retained[102]==true and retained[112]==true,
    "C50_DIRECT_SEARCH_ALSO_ADDS_NEW_GENERATION_IDS")
local reset=module:ByName("new")
check(count(reset.npc)==2 and reset.npc[101]==nil and reset.npc[102]==true,
    "C51_BYNAME_RESETS_OLD_ID_CACHE_AFTER_GENERATION_CHANGE")
check(not contains(original,"QueryGeneration") and
    not contains(original,"AcquireGeneration"),
    "C52_ORIGINAL_SEARCH_HAS_NO_EXPLICIT_GENERATION_LEASE_API")
assert(checks==52,"ORIGINAL_CONSUMER_ASSERTION_CENSUS_CHANGED")
print("PUBLIC G08 PART43 REAL 335 QUESTIESEARCH QUERY POINTER PAIR: 52/52 PASS")
print("PUBLIC G08 ORIGINAL SOURCE WITNESS: separate query and pointer field reads; constructed mixed facade silently loses matching search IDs; stable matching local pair remains coherent through one synchronous search.")
print("PUBLIC G08 NOT ACCEPTED: data/query functions are invented; no real GetDBHandle, real external writer interleaving, stream pool, saved variables, native 3.3.5a/IP, build/ZIP/install/merge/release.")
