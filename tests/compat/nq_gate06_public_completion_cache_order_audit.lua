-- N-Questie Part40 Gate06 public source-backed completion-cache event audit.
-- READ ONLY: loads only selected exact public Compat.lua functions. All quest
-- IDs in this test are invented. Never print IDs, relationships or source data.
-- No private IP/server records, no real client or SavedVariables mutation.
local sourcePath="Compat/Compat.lua"
local file=assert(io.open(sourcePath,"rb"),"G06_PUBLIC_COMPAT_SOURCE_MISSING")
local publicSource=assert(file:read("*a"))
file:close()
local function extract(beginText,endText)
    local first=assert(publicSource:find(beginText,1,true),
        "G06_PUBLIC_COMPAT_SOURCE_BOUNDARY_CHANGED")
    assert(not publicSource:find(beginText,first+1,true),
        "G06_PUBLIC_COMPAT_SOURCE_DUPLICATE")
    local last=assert(publicSource:find(endText,first+#beginText,true),
        "G06_PUBLIC_COMPAT_SOURCE_BOUNDARY_CHANGED")
    return publicSource:sub(first,last-1)
end
-- These are ACTUAL public functions, compiled intact in a headless stub.
-- CalculateNextResetTime / API ordering / native events are intentionally
-- stubbed, not presented as genuine 3.3.5a runtime behaviour.
local chunks={
    extract("function QuestieCompat.ResetDailyQuests(reset)",
        "\nlocal weeklyResetTimer"),
    extract("function QuestieCompat.SetQuestComplete(questId)",
        "\n-- https://wowpedia.fandom.com/wiki/API_IsQuestFlaggedCompleted"),
    extract("function QuestieCompat.Merge(target, source, override)",
        "\nfunction QuestieCompat:ADDON_LOADED"),
}
QuestieCompat={}
local constructor=assert((loadstring or load)(table.concat(chunks,"\n"),
    "=public_g06_compat_source"))
constructor()

local A,B,R,D,W=991001,991002,991003,991004,991005
local function copy(x)
    local y={}
    if x then for k,v in pairs(x) do y[k]=v end end
    return y
end
local function makeFixture(options)
    options=options or {}
    local now=options.now or 50
    local server=copy(options.server)
    local api=options.api or "CLEAR_ADD"
    local queries,delivered,resets,redraws=0,0,0,0
    Questie={
        IsWotlk=options.wotlk or false,
        started=options.started or false,
        db={
            char={
                complete=options.missingCache and nil or copy(options.cache),
                daily=copy(options.daily),weekly=copy(options.weekly),
            },
            profile={resetDailyQuests=options.resetDaily or false,
                dailyResetTime=options.resetTime or 100,
                weeklyResetTime=9999, weeklyResetDay=3}
        }
    }
    if options.missingCache then Questie.db.char.complete=nil end
    QuestieDB={
        IsRepeatable=function(id) return options.repeatable and
            options.repeatable[id] or false end,
        IsDailyQuest=function(id) return options.dailyIds and
            options.dailyIds[id] or false end,
        IsWeeklyQuest=function(id) return options.weeklyIds and
            options.weeklyIds[id] or false end,
    }
    QuestiePlayer={GetPlayerLevel=function() return options.level or 1 end}
    AvailableQuests={CalculateAndDrawAll=function() redraws=redraws+1 end}
    QuestieCompat.GetServerTime=function() return now end
    -- Public CalculateNextResetTime uses an existing reset deadline; it
    -- computes a new one only when that stored deadline has been cleared.
    QuestieCompat.CalculateNextResetTime=function()
        if Questie.db.profile.dailyResetTime==nil then
            resets=resets+1
            Questie.db.profile.dailyResetTime=now+86400
        end
    end
    QuestieCompat.ResetWeeklyQuests=function() return true end
    QuestieCompat.C_Timer={
        NewTicker=function() error("G06_UNEXPECTED_WEEKLY_TIMER") end}
    CalendarGetDate=function() return 3 end
    QueryQuestsCompleted=function() queries=queries+1 end
    GetQuestsCompleted=function(target)
        delivered=delivered+1
        if api=="CLEAR_ADD" then
            for id in pairs(target) do target[id]=nil end
        elseif api~="ADD_ONLY" then
            error("G06_UNRECOGNIZED_HYPOTHETICAL_API")
        end
        for id,value in pairs(server) do target[id]=value end
    end
    return {
        refresh=function() return QuestieCompat.GetQuestsCompleted() end,
        deliver=function() QuestieCompat:QUEST_QUERY_COMPLETE("QUEST_QUERY_COMPLETE") end,
        setServer=function(data) server=copy(data) end,
        setTime=function(t) now=t end,
        counts=function() return queries,delivered,resets,redraws end,
        cache=function() return Questie.db.char.complete end,
    }
end

-- Each case is completely isolated; no real quest IDs or server data.
-- Historical patch-3.3 GetQuestsCompleted(table) documentation says any
-- unrelated existing keys in the supplied table are left unchanged. ADD_ONLY
-- models that documented behavior; CLEAR_ADD is a counterfactual control.
-- Actual owner 3.3.5a/AzerothCore client and event ordering remain UNTESTED.
-- Count only assertions actually reached and passed inside each fictional case.
-- The expected per-case vector is independent of the printed headline; a
-- no-op control or removed execution loop must fail in Lua, not just CI.
local nativeAssert=assert
local successfulAssertions=0
local function countedAssert(condition,reason)
    nativeAssert(condition,reason)
    successfulAssertions=successfulAssertions+1
    return condition
end
local controls={
    function()
        local f=makeFixture({missingCache=true})
        local got=f.refresh()
        countedAssert(type(got)=="table" and got==f.cache(),
            "G06_MISSING_CACHE_CREATION_CONTROL")
        local queries=f.counts()
        countedAssert(queries==1,"G06_INITIAL_QUERY_CONTROL")
    end,
    function()
        local f=makeFixture({cache={[A]=true},server={[B]=true}})
        local cache=f.refresh()
        countedAssert(cache[A]==true and cache[B]==nil,
            "G06_DELAYED_QUERY_NOT_CHARACTERIZED")
        f.deliver()
        countedAssert(cache[A]==nil and cache[B]==true,
            "G06_CLEAR_ADD_EVENT_CONTROL")
    end,
    function()
        local f=makeFixture({cache={[A]=true},server={[B]=true},
            api="ADD_ONLY"})
        f.refresh();f.deliver()
        countedAssert(f.cache()[A]==true and f.cache()[B]==true,
            "G06_HYPOTHETICAL_ADD_ONLY_UNSAFE_CONTROL")
    end,
    function()
        local f=makeFixture({server={[R]=true,[B]=true},
            repeatable={[R]=true}})
        f.refresh();f.deliver()
        countedAssert(f.cache()[R]==nil and f.cache()[B]==true,
            "G06_REPEATABLE_FILTER_CONTROL")
    end,
    function()
        local f=makeFixture({server={[A]=true}})
        f.refresh();f.deliver()
        f.setServer({[B]=true});f.deliver()
        countedAssert(f.cache()[A]==nil and f.cache()[B]==true,
            "G06_SEQUENTIAL_REPLACE_CONTROL")
    end,
    function()
        local f=makeFixture({server={[A]=true}})
        f.refresh();f.deliver()
        f.setServer({[B]=true});f.deliver()
        f.setServer({[A]=true});f.deliver()
        countedAssert(f.cache()[A]==true and f.cache()[B]==nil,
            "G06_UNCORRELATED_OLD_REPLY_WITNESS")
        local queries,deliveries=f.counts()
        countedAssert(queries==1 and deliveries==3,
            "G06_UNCORRELATED_EVENT_COUNT_CONTROL")
    end,
    function()
        makeFixture()
        QuestieCompat.SetQuestComplete(A)
        countedAssert(Questie.db.char.complete[A]==true,
            "G06_NONREPEATABLE_COMPLETION_CONTROL")
    end,
    function()
        makeFixture({repeatable={[R]=true}})
        QuestieCompat.SetQuestComplete(R)
        countedAssert(Questie.db.char.complete[R]==nil,
            "G06_REPEATABLE_LOCAL_COMPLETION_CONTROL")
    end,
    function()
        makeFixture({repeatable={[D]=true},dailyIds={[D]=true}})
        QuestieCompat.SetQuestComplete(D)
        countedAssert(Questie.db.char.complete[D]==nil
            and Questie.db.char.daily[D]==nil,
            "G06_DAILY_WITH_RESET_DISABLED_CONTROL")
    end,
    function()
        makeFixture({repeatable={[D]=true},dailyIds={[D]=true},
            resetDaily=true})
        QuestieCompat.SetQuestComplete(D)
        countedAssert(Questie.db.char.complete[D]==true
            and Questie.db.char.daily[D]==true,
            "G06_DAILY_CACHE_ADD_CONTROL")
    end,
    function()
        makeFixture({repeatable={[W]=true},weeklyIds={[W]=true},
            resetDaily=true})
        QuestieCompat.SetQuestComplete(W)
        countedAssert(Questie.db.char.complete[W]==true
            and Questie.db.char.weekly[W]==true,
            "G06_WEEKLY_CACHE_ADD_CONTROL")
    end,
    function()
        local f=makeFixture({cache={[D]=true},daily={[D]=true},
            repeatable={[D]=true},dailyIds={[D]=true},
            resetDaily=true,resetTime=100,now=101,started=true})
        f.refresh();f.deliver()
        local _,_,resets,redraws=f.counts()
        countedAssert(f.cache()[D]==nil and Questie.db.char.daily[D]==nil
            and resets==1 and redraws==1,
            "G06_RESET_DAILY_CLEAR_CONTROL")
    end,
    function()
        local f=makeFixture({daily={[D]=true},
            repeatable={[D]=true},dailyIds={[D]=true},
            resetDaily=true,resetTime=100,now=50})
        f.refresh();f.deliver()
        local _,_,resets=f.counts()
        countedAssert(f.cache()[D]==true and resets==0,
            "G06_DAILY_NOT_YET_RESET_MERGE_CONTROL")
    end,
    function()
        local f=makeFixture({weekly={[W]=true},
            repeatable={[W]=true},weeklyIds={[W]=true},
            resetDaily=true,wotlk=true,level=79})
        f.refresh();f.deliver()
        countedAssert(f.cache()[W]==true,
            "G06_WRATH_WEEKLY_MERGE_CONTROL")
    end,
    -- M4c: non-repeatable daily clearing belongs to ResetDailyQuests itself,
    -- not the event repeatable filter.
    function()
        local f=makeFixture({cache={[D]=true},daily={[D]=true},
            dailyIds={[D]=true},api="ADD_ONLY",resetDaily=true,
            now=101,resetTime=100})
        f.refresh(); f.deliver()
        local _,_,resets=f.counts()
        countedAssert(f.cache()[D]==nil and Questie.db.char.daily[D]==nil
            and resets==1,"G06_RESET_OWNS_COMPLETE_CLEAR_CONTROL")
    end,
    -- M4d: source uses >, not >=; at the exact deadline don't reset.
    function()
        local f=makeFixture({cache={[D]=true},daily={[D]=true},
            dailyIds={[D]=true},api="ADD_ONLY",resetDaily=true,
            now=100,resetTime=100})
        f.refresh(); f.deliver()
        local _,_,resets=f.counts()
        countedAssert(f.cache()[D]==true and Questie.db.char.daily[D]==true
            and resets==0,"G06_EXACT_RESET_BOUNDARY_CONTROL")
    end,
    -- M9: no daily/weekly overlay with reset option disabled.
    function()
        local f=makeFixture({daily={[D]=true},weekly={[W]=true},
            resetDaily=false,wotlk=true,level=79,api="CLEAR_ADD"})
        f.refresh(); f.deliver()
        local _,_,resets=f.counts()
        countedAssert(f.cache()[D]==nil and f.cache()[W]==nil
            and resets==0,"G06_DISABLED_RESET_OPTION_GATE_CONTROL")
    end,
}
local expectedAssertions={2,2,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1}
nativeAssert(#controls==17 and #expectedAssertions==17,
    "G06_CONTROL_INVENTORY_CHANGED")
local executed=0
for i,control in ipairs(controls) do
    local before=successfulAssertions
    control()
    nativeAssert(successfulAssertions-before==expectedAssertions[i],
        "G06_CONTROL_ASSERTION_BODY_NOT_EXECUTED")
    executed=executed+1
end
nativeAssert(executed==17 and successfulAssertions==20,
    "G06_CONTROL_EXECUTION_TALLY_CHANGED")
print("PUBLIC G06 SOURCE BACKED COMPLETION CONTROLS: "..executed.."/17 PASS assertions="..successfulAssertions)
print("PUBLIC G06 SOURCE RISK: documented GetQuestsCompleted(table) additive writes may retain stale completion keys.")
print("PUBLIC G06 NOT ACCEPTED: native 3.3.5a API execution, uncorrelated event timing, daily/weekly timers, UI markers or private IP phase.")
