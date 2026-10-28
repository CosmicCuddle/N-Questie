-- PUBLIC-SAFE TEST ONLY: exact genuine original TrackerLinePool btn.SetItem
-- function fragment extracted unchanged from pinned 335 source; fictional UI/bags.
-- It does NOT execute TrackerLinePool.Initialize() or real WoW APIs.
local root=assert(os.getenv("NQ_G08_TRACKER_SETITEM_ROOT"),"PINNED_SOURCE_ROOT_REQUIRED")
local fp=assert(io.open(root.."/Modules/Tracker/TrackerLinePool.lua","rb"))
local src=assert(fp:read("*a"));fp:close()
local function originalSetItem()
  local first="        btn.SetItem = function(self, quest, buttonType, size)"
  local last="\n        btn.OnEvent = function"
  local a=assert(src:find(first,1,true),"ORIGINAL_SETITEM_START_MISSING")
  assert(not src:find(first,a+#first,true),"ORIGINAL_SETITEM_NOT_UNIQUE")
  local b=assert(src:find(last,a+#first,true),"ORIGINAL_SETITEM_END_MISSING")
  return src:sub(a,b-1)
end
local fragment=originalSetItem()
local n=0
local function check(ok,label) assert(ok,label);n=n+1 end
local function compile(code,env)
  local f
  if _VERSION=="Lua 5.1" then
    f=assert(loadstring(code,"@335/TrackerLinePool.original.SetItem"));setfenv(f,env)
  else
    f=assert(load(code,"@335/TrackerLinePool.original.SetItem","t",env))
  end
  return f()
end
check(src:find('QuestieDB.QueryItemSingle(itemId, "class") == 12',1,true)~=nil,
  "T01_GENUINE_ITEM_CLASS_DIRECT_QUERY")
check(src:find('QuestieDB.QueryItemSingle(questItemId, "class") == 12',1,true)~=nil,
  "T02_GENUINE_REQUIRED_SOURCE_CLASS_QUERY")
check(fragment:find("for bag = -2, 4 do",1,true)~=nil,"T03_ORIGINAL_BAG_LOOP")
check(fragment:find("for inventorySlot = 1, 19 do",1,true)~=nil,"T04_ORIGINAL_EQUIPMENT_FALLBACK")
check(fragment:find('self:SetAttribute("item1", nil)',1,true)~=nil,
  "T05_ORIGINAL_ATTRIBUTE_CLEAR_ON_FAIL")
check(fragment:find("self:Hide()",1,true)~=nil and
  fragment:find("self:Show()",1,true)~=nil,"T06_ORIGINAL_UI_VISIBILITY")
check(fragment:find("return true",1,true)~=nil and fragment:find("return false",1,true)~=nil,
  "T07_ORIGINAL_POSITIVE_AND_NEGATIVE_EXIT")
check(fragment:find('self.count:SetFont(LSM30:Fetch("font"',1,true)~=nil,
  "T08_ORIGINAL_DERIVED_FONT_AND_COUNT")
local function noop()end
local function fixture()
  local current="OLD"
  local bagItem,inventoryItem,bagTexture,inventoryTexture
  local classOverride={}
  local calls={}
  local bagHook
  local db={}
  function db.QueryItemSingle(id,field)
    calls[#calls+1]={id=id,field=field,source=current}
    assert(field=="class","UNEXPECTED_DB_FIELD")
    local expected=(current=="OLD" and (id==41 or id==42) or (id==141 or id==142))
    if classOverride[id]~=nil then return classOverride[id] end
    return expected and 12 or nil
  end
  local compat={}
  function compat.GetContainerNumSlots(bag)
    if bag==0 and bagItem~=nil then return 1 end
    return 0
  end
  function compat.GetContainerItemInfo(bag,slot)
    if bagHook then local f=bagHook;bagHook=nil;f() end
    if bag==0 and slot==1 then
      return bagTexture or "FictionalBagTexture",nil,nil,nil,nil,nil,nil,nil,nil,bagItem
    end
  end
  local font={}
  function font:Fetch(kind) assert(kind=="font");return "FictionalFont" end
  local questie={db={profile={trackerFontQuest="default",trackerFontSizeQuest=12}}}
  local env={
    GetInventoryItemID=function(_,slot)
      if slot==1 then return inventoryItem end
      return nil
    end,
    GetInventoryItemTexture=function(_,slot)
      if slot==1 then return inventoryTexture or "FictionalEquipmentTexture" end
      return nil
    end,
    GetItemCount=function()return 3 end
  }
  setmetatable(env,{__index=_G})
  local factory=compile("return function(btn,cooldown,LSM30,QuestieDB,QuestieCompat,Questie)\n"..
    fragment.."\nreturn btn.SetItem\nend",env)
  local f={calls=calls}
  function f.source(tag) current=tag end
  function f.bag(id,texture) bagItem=id;bagTexture=texture end
  function f.inventory(id,texture) inventoryItem=id;inventoryTexture=texture end
  function f.class(id,value) classOverride[id]=value end
  function f.onBag(cb) bagHook=cb end
  function f.button()
    local b={attrs={},visible=false,scripts={},range={},count={}}
    function b:SetAttribute(k,v)self.attrs[k]=v end
    function b:Show()self.visible=true end
    function b:Hide()self.visible=false end
    function b:SetScript(k,v)self.scripts[k]=v end
    function b:SetNormalTexture(v)self.texture=v end
    function b:SetPushedTexture(v)self.pushed=v end
    function b:SetHighlightTexture(v)self.highlight=v end
    function b:SetSize(w,h)self.width=w;self.height=h end
    function b:RegisterForClicks(v)self.clicks=v end
    setmetatable(b.range,{__index=function()return noop end})
    setmetatable(b.count,{__index=function()return noop end})
    local cooldown={}
    setmetatable(cooldown,{__index=function()return noop end})
    b.SetItem=factory(b,cooldown,font,db,compat,questie)
    return b
  end
  return f
end
local a=fixture();a.bag(41);local btn=a.button()
check(type(btn.SetItem)=="function","T09_GENUINE_ORIGINAL_FUNCTION_COMPILED")
check(btn:SetItem({Id=800,sourceItemId=41},"primary",20)==true,
  "T10_MATCHING_OLD_PRIMARY_BAG_SUCCEEDS")
check(btn.itemId==41 and btn.questID==800,"T11_ORIGINAL_ITEM_ID_QUEST_ID_APPLIED")
check(btn.attrs.item1=="item:41" and btn.visible,"T12_ORIGINAL_SECURE_ITEM_ATTR")
check(btn.texture=="FictionalBagTexture" and btn.width==20,
  "T13_ORIGINAL_BUTTON_TEXTURE_SIZE")
check(btn.charges==3 and btn.rangeTimer==-1,"T14_ORIGINAL_COUNTS_AND_RANGE")
check(#a.calls>=1 and a.calls[1].id==41 and a.calls[1].field=="class",
  "T15_ORIGINAL_CLASS_CALL_ACTUALLY_RUN")
a.source("NEW")
check(btn:SetItem({Id=801,sourceItemId=41},"primary",20)==false,
  "T16_MISMATCH_OLD_BAG_NEW_CLASS_FALSE")
check(btn.attrs.item1==nil and not btn.visible,"T17_ORIGINAL_FAIL_CLEARS_ACTION_AND_HIDES")
check(btn.itemId==41 and btn.questID==800,"T18_ORIGINAL_FAIL_LEAVES_STALE_PRIVATE_FIELDS")
check(a.calls[#a.calls].source=="NEW","T19_ACTUAL_NEW_READER_CALLED")
a.bag(141);local newer=a.button()
check(newer:SetItem({Id=900,sourceItemId=141},"primary",22)==true,
  "T20_MATCHING_NEW_BAG_PRIMARY")
check(newer.attrs.item1=="item:141" and newer.questID==900,
  "T21_MATCHING_NEW_SECURE_ATTR")
a.source("OLD");a.bag(42);local required=a.button()
check(required:SetItem({Id=901,sourceItemId=0,requiredSourceItems={42}},"primary",18)==true,
  "T22_SINGLE_REQUIRED_ITEM_CLASS")
check(required.itemId==42 and required.attrs.item1=="item:42",
  "T23_ORIGINAL_SINGLE_REQUIRED_UI")
a.bag(42);local secondary=a.button()
check(secondary:SetItem({Id=902,sourceItemId=0,requiredSourceItems={41,42}},"secondary",18)==true,
  "T24_MULTIPLE_REQUIRED_SECONDARY_MATCH")
check(secondary.itemId==42,"T25_MULTIPLE_REQUIRED_PICKED_MATCHING_ID")
local wrong=a.button()
check(wrong:SetItem({Id=903,sourceItemId=0,requiredSourceItems={41,42}},"primary",18)==false,
  "T26_MULTIPLE_REQUIRED_REFUSES_PRIMARY")
check(not wrong.visible and wrong.attrs.item1==nil,"T27_WRONG_BUTTON_TYPE_NO_ACTION")
a.class(41,11);a.bag(41);local notQuestItem=a.button()
check(notQuestItem:SetItem({Id=904,sourceItemId=41},"primary",18)==false,
  "T28_NON_CLASS12_REFUSED")
check(not notQuestItem.visible,"T29_NONQUEST_CLASS_CANNOT_DRAW")
a.class(41,12);a.bag(nil);a.inventory(41)
local equipped=a.button()
check(equipped:SetItem({Id=905,sourceItemId=41},"primary",18)==true,
  "T30_ORIGINAL_EQUIPMENT_FALLBACK")
check(equipped.texture=="FictionalEquipmentTexture" and equipped.itemId==41,
  "T31_EQUIPPED_ITEM_TEXTURE_FROM_FALLBACK")
a.bag(41);a.inventory(nil)
-- Reset the prior NON-QUEST class override before testing a source-generation swap.
-- Otherwise classOverride[41] would mask the deliberately mismatched NEW reader.
a.class(41,nil)
a.onBag(function()a.source("NEW")end)
local reentrant=a.button()
check(reentrant:SetItem({Id=906,sourceItemId=41},"primary",18)==false,
  "T32_SYNTHETIC_BAG_API_SWITCH_BEFORE_QUERY")
check(a.calls[#a.calls].source=="NEW" and not reentrant.visible,
  "T33_ORIGINAL_QUERY_USES_LATEST_SOURCE_AFTER_HOOK")
a.bag(141)
check(reentrant:SetItem({Id=907,sourceItemId=141},"primary",20)==true,
  "T34_RECOVERY_WITH_NEW_MATCHED_BAG_AND_QUERY")
check(reentrant.attrs.item1=="item:141" and reentrant.questID==907,
  "T35_ORIGINAL_ACTION_RECOVERS_NEW_SOURCE")
assert(n==35,"TRACKER_SETITEM_ASSERTION_CENSUS_CHANGED:"..n)
print("PUBLIC G08 PART44 ORIGINAL TRACKER SETITEM: 35/35 PASS")
print("PUBLIC G08 REAL SOURCE: original unchanged TrackerLinePool btn.SetItem entire function fragment executes with synthetic bag, inventory, item query and UI sinks; NOT entire TrackerLinePool.Initialize/module.")
print("PUBLIC G08 SYNTHETIC BOUNDARY: item class queries select current facade, deliberate OLD item with NEW query hides button and clears action but leaves old private itemId/questID; matched NEW recovers.")
print("PUBLIC G08 NOT NATIVE: no actual WoW bag/inventory/frame, tracker initialization, native GetDBHandle, QuestieStream, SavedVariables, 3.3.5a/IP, packaging, build, install, merge or release.")
