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
-- WoW exposes bit operations globally; emulate the small positive-number
-- subset needed by the real QuestieStream in standalone Lua 5.1.
local function positiveBand(a, b)
    local answer, place = 0, 1
    while a > 0 and b > 0 do
        if a % 2 == 1 and b % 2 == 1 then answer = answer + place end
        a, b, place = math.floor(a / 2), math.floor(b / 2), place * 2
    end
    return answer
end
bit = {
    band = positiveBand,
    lshift = function(v, n) return v * 2 ^ n end,
    rshift = function(v, n) return math.floor(v / (2 ^ n)) end,
}
tremove = table.remove -- exported as a WoW Lua utility in the production client
assert(loadfile("Modules/QuestieStream.lua"))()
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
-- The second pass uses the real production QuestieStreamLib raw_assert
-- implementation, not our byteStream adapter. No SavedVariables or client.
local realStreams = modules.QuestieStreamLib
assert(realStreams and realStreams.GetStream)
local function actualStreamRoundtrip(kind, payload)
    local writer=realStreams:GetStream("raw_assert")
    compiler.writers[kind](writer, payload)
    local bytes=writer:Save()
    local reader=realStreams:GetStream("raw_assert")
    reader:Load(bytes)
    local decoded=compiler.readers[kind](reader)
    assert(reader._pointer==#bytes+1,
        "production stream did not consume entire "..kind.." payload")
    return decoded, bytes
end
local goActual=actualStreamRoundtrip("objectives",go[Q.objectives])
check("actual QuestieStream GO objective slot",
    goActual[1]==nil and goActual[2] and
    goActual[2][1][1]==8811 and goActual[3]==nil)
local itemActual=actualStreamRoundtrip("objectives",item[Q.objectives])
check("actual QuestieStream item objective slot",
    itemActual[1]==nil and itemActual[2]==nil and
    itemActual[3] and itemActual[3][1][1]==6611)
local sourceActual=actualStreamRoundtrip("questgivers",item[Q.startedBy])
check("actual QuestieStream GO starter slot",
    sourceActual[1]==nil and sourceActual[2] and sourceActual[2][1]==8812)
local starterActual=actualStreamRoundtrip("questgivers",go[Q.startedBy])
check("actual QuestieStream NPC starter slot",
    starterActual[1] and starterActual[1][1]==7711 and starterActual[2]==nil)
local finishActual=actualStreamRoundtrip("questgivers",item[Q.finishedBy])
check("actual QuestieStream NPC finisher",
    finishActual[1] and finishActual[1][1]==7712)
local levelActual, levelBytes=actualStreamRoundtrip("s16",item[Q.questLevel])
check("actual QuestieStream scaling level -1",levelActual==-1)
check("real stream emits big-endian signed-level bytes",
    #levelBytes==2 and string.byte(levelBytes,1)==127 and
    string.byte(levelBytes,2)==254)
check("actual QuestieStream still supplies no fabricated text",
    itemActual[3][1][2]==nil and goActual[2][1][2]==nil)
print("ALL "..checks.." SYNTHETIC COMPILER+STREAM CHECKS PASS; whole-DB compile/client NOT TESTED.")
