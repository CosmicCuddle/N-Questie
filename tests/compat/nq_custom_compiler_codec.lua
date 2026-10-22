-- Offline synthetic probe using the repository's actual DBCompiler codec functions.
-- This is NOT a production stream/whole-DB compiler or WoW-client test.
-- Every fixture ID here is invented; no owner-private records are loaded.
local callbacks, modules = {}, {}
local Q = {
    name=1, startedBy=2, finishedBy=3, requiredLevel=4, questLevel=5,
    requiredRaces=6, objectives=10, zoneOrSort=17, questFlags=23,
}
local N = {questStarts=10, questEnds=11}
local G = {questStarts=2, questEnds=3}
local db = {
    questKeys=Q, npcKeys=N, objectKeys=G, questData={},
    npcData={
        [7711]={[1]="Synthetic NPC starter"},
        [7712]={[1]="Synthetic NPC finisher"},
    },
    objectData={
        [8811]={[1]="Synthetic object objective"},
        [8812]={[1]="Synthetic object starter"},
    },
    itemData={
        [6611]={[1]="Synthetic crafted item"},
    },
}
modules.QuestieDB = db
modules.QuestieStreamLib = {GetStream=function(_, kind)
    assert(kind=="raw")
    return {}
end}
modules.QuestieLib = {}
modules.l10n = function(x) return x end
QuestieLoader = {
    CreateModule=function(_, name)
        local mod = {}
        modules[name] = mod
        return mod
    end,
    ImportModule=function(_, name)
        assert(modules[name], "Missing isolated module: "..name)
        return modules[name]
    end,
}
QuestieCompat = {
    Is335=true, WOW_PROJECT_ID=2,
    RegisterCorrection=function(kind, fn) callbacks[kind]=fn end,
}
-- The compiler only caches bit.lshift at file load for this isolated probe.
bit = {lshift=function(v, n) return v * 2 ^ n end}
NQuestieCustomQuestData = {revision=8, quests={
    [920101]={
        name="Synthetic GO objective", requiredLevel=10, questLevel=15,
        zoneOrSort=130, requiredRaces=0, questFlags=0,
        startedByNpcs={7711}, finishedByNpcs={7712},
        objectObjectives={8811},
    },
    [920102]={
        name="Synthetic item objective", requiredLevel=10, questLevel=-1,
        zoneOrSort=130, requiredRaces=0, questFlags=0,
        startedByGameObjects={8812}, finishedByNpcs={7712},
        itemObjectives={6611},
    },
}}
assert(loadfile("Compat/NQuestieCustomQuestLoader.lua"))()
assert(type(callbacks.questData)=="function")
local quests = callbacks.questData()
assert(quests[920101] and quests[920102], "synthetic loader fixtures rejected")
assert(loadfile("Database/compiler.lua"))()
local compiler = modules.DBCompiler
assert(compiler and compiler.writers and compiler.readers,
    "actual compiler codec functions not loaded")

-- Minimal in-memory byte stream: exercised writer/reader code is production,
-- but this stream adapter is deliberately synthetic, not QuestieStreamLib.
local function byteStream()
    local s = {bytes={}, position=1}
    function s:WriteByte(n)
        assert(type(n)=="number" and n==math.floor(n) and n>=0 and n<=255)
        self.bytes[#self.bytes+1]=n
    end
    function s:ReadByte()
        local n = self.bytes[self.position]
        assert(n~=nil, "unexpected end of synthetic byte stream")
        self.position=self.position+1
        return n
    end
    function s:WriteShort(n)
        assert(n==math.floor(n) and n>=0 and n<=65535)
        self:WriteByte(n%256)
        self:WriteByte(math.floor(n/256))
    end
    function s:ReadShort()
        local a, b = self:ReadByte(), self:ReadByte()
        return a+256*b
    end
    function s:WriteInt24(n)
        assert(n==math.floor(n) and n>=0 and n<=16777215)
        self:WriteByte(n%256)
        self:WriteByte(math.floor(n/256)%256)
        self:WriteByte(math.floor(n/65536))
    end
    function s:ReadInt24()
        local a, b, c=self:ReadByte(),self:ReadByte(),self:ReadByte()
        return a+256*b+65536*c
    end
    function s:WriteTinyString(str)
        assert(type(str)=="string" and #str<=255)
        self:WriteByte(#str)
        for i=1,#str do self:WriteByte(string.byte(str,i)) end
    end
    function s:ReadTinyStringNil()
        local len = self:ReadByte()
        if len==0 then return nil end
        local t={}
        for i=1,len do t[i]=string.char(self:ReadByte()) end
        return table.concat(t)
    end
    return s
end
local checks = 0
local function check(label, condition)
    checks=checks+1
    assert(condition,"FAIL: "..label)
    print("PASS codec "..checks.." "..label)
end
local function roundtrip(kind, payload)
    local stream=byteStream()
    compiler.writers[kind](stream,payload)
    local size=#stream.bytes
    local decoded=compiler.readers[kind](stream)
    assert(stream.position==size+1, "decoder did not consume complete "..kind)
    return decoded,size
end
local go=quests[920101]
local item=quests[920102]
local objGo,sizeGo=roundtrip("objectives",go[Q.objectives])
check("GO objective survives actual compiler writer/reader",
    objGo[1]==nil and objGo[2] and objGo[2][1][1]==8811 and objGo[3]==nil)
check("GO objective bytes are emitted",sizeGo>0)
local objItem,sizeItem=roundtrip("objectives",item[Q.objectives])
check("item objective survives actual compiler writer/reader",
    objItem[1]==nil and objItem[2]==nil and objItem[3] and
    objItem[3][1][1]==6611)
check("item objective bytes are emitted",sizeItem>0)
local fromGo=roundtrip("questgivers",item[Q.startedBy])
check("GO starter retains second questgiver slot",
    fromGo[1]==nil and fromGo[2] and fromGo[2][1]==8812 and fromGo[3]==nil)
local fromNpc=roundtrip("questgivers",go[Q.startedBy])
check("NPC starter retains first questgiver slot",
    fromNpc[1] and fromNpc[1][1]==7711 and fromNpc[2]==nil)
local toNpc=roundtrip("questgivers",item[Q.finishedBy])
check("NPC finisher retained after questgiver codec",
    toNpc[1] and toNpc[1][1]==7712 and toNpc[2]==nil)
local scaling=roundtrip("s16",item[Q.questLevel])
check("scaling questLevel -1 survives s16 codec",scaling==-1)
local fixed=roundtrip("s16",go[Q.questLevel])
check("fixed questLevel survives s16 codec",fixed==15)
check("objective descriptions/counts not fabricated",
    objItem[3][1][2]==nil and objGo[2][1][2]==nil)
check("item fixture has no invented acquisition locations",
    db.itemData[6611][2]==nil)
print("ALL "..checks.." SYNTHETIC COMPILER CODEC CHECKS PASS; real stream/full compile/client NOT TESTED.")
