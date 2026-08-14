--[[
  Offline content-tagging tests.

  Stubs enough of the WoW API to load the real Const/ContentIndex/Content files and
  assert how instances are tagged. No game client needed.

    scripts/test.sh          (or: lua5.1 tests/content_spec.lua)

  Two regressions are pinned here deliberately:
    * a season-pool dungeon from an older expansion must carry BOTH dungeon_season
      and dungeon_legacy, with season winning when bound;
    * the journal's appended "Current Season" tier re-lists instances from their real
      expansion tier and must never overwrite it -- that clobber made every
      current-expansion dungeon and raid classify as legacy.
]]

-- Resolve the addon directory from this file's own path, so the suite runs from
-- anywhere without a hardcoded checkout location.
local ADDON = (debug.getinfo(1, "S").source:match("@(.*)tests[/\\][^/\\]+$")) or "./"

-- ---------------------------------------------------------------- WoW stubs
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
GetTime = function() return 1000 end
GetExpansionLevel = function() return 11 end
EXPANSION_NAME11 = "Midnight"

-- Tier layout mirrors the live client: 12 real expansion tiers plus an appended
-- "Current Season" pseudo-tier at 13 that RE-LISTS instances from their real tier.
local TIER_NAMES = {
  "Classic", "Burning Crusade", "Wrath of the Lich King", "Cataclysm",
  "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth",
  "Shadowlands", "Dragonflight", "The War Within", "Midnight", "Current Season",
}

EJ_GetNumTiers = function() return #TIER_NAMES end
EJ_GetTierInfo = function(i) return TIER_NAMES[i] end

-- `tiers` lists every tier the instance appears in, real expansion tier first.
local JOURNAL = {
  [1001] = { name = "Windrunner Spire",   tiers = { 12, 13 }, mapID = 2805 },
  [1002] = { name = "Maisara Caverns",    tiers = { 12 },     mapID = 2874 },
  [1003] = { name = "Nexus-Point Xenas",  tiers = { 12 },     mapID = 2915 },
  [1004] = { name = "Priory of the Sacred Flame", tiers = { 11 }, mapID = 2649 },
  [1005] = { name = "Halls of Reflection", tiers = { 3 },      mapID = 668 },
  [1006] = { name = "Pit of Saron",        tiers = { 3, 13 },  mapID = 658 },
  [2001] = { name = "Some Raid",           tiers = { 12 },     mapID = 9001, raid = true },
}

local ORDER = { 1001, 1002, 1003, 1004, 1005, 1006, 2001 }

local selectedTier = 1
local ejSelectCount, ejInfoCount = 0, 0
EJ_SelectTier = function(t) selectedTier = t end
EJ_SelectInstance = function() ejSelectCount = ejSelectCount + 1 end

local function InTier(e, tier)
  for _, t in ipairs(e.tiers) do
    if t == tier then return true end
  end
  return false
end

EJ_GetInstanceByIndex = function(i, isRaid)
  local n = 0
  for _, id in ipairs(ORDER) do
    local e = JOURNAL[id]
    if InTier(e, selectedTier) and (not not e.raid) == (not not isRaid) then
      n = n + 1
      if n == i then return id end
    end
  end
  return nil
end

EJ_GetInstanceInfo = function(id)
  ejInfoCount = ejInfoCount + 1
  local e = JOURNAL[id]
  if not e then return nil end
  -- name, _, _, _, _, _, dungeonAreaMapID, _, _, mapID
  return e.name, nil, nil, nil, nil, nil, 0, nil, nil, e.mapID
end

EJ_GetInstanceForMap = function() return nil end
C_Map = { GetBestMapForUnit = function() return nil end, GetMapInfo = function() return nil end }

-- The season pool: two Midnight dungeons + one legacy (Pit of Saron).
-- challengeMapID -> instance mapID, mirroring GetMapUIInfo's 6th return.
local POOL = {
  [557] = { name = "Windrunner Spire",  mapID = 2805 },
  [560] = { name = "Maisara Caverns",   mapID = 2874 },
  [556] = { name = "Pit of Saron",      mapID = 658 },
}
local POOL_ORDER = { 557, 560, 556 }

local poolAvailable = true
C_ChallengeMode = {
  GetMapTable = function()
    if not poolAvailable then return {} end
    local t = {}
    for i, id in ipairs(POOL_ORDER) do t[i] = id end
    return t
  end,
  GetMapUIInfo = function(cid)
    local e = POOL[cid]
    if not e then return end -- MayReturnNothing
    return e.name, cid, 1800, nil, 0, e.mapID
  end,
}

local requestCount = 0
C_MythicPlus = {
  RequestMapInfo = function() requestCount = requestCount + 1 end,
  GetCurrentSeason = function() return 2 end,
}

-- Instance the player is standing in.
local CUR = { name = "", mapID = nil, type = "party" }
IsInInstance = function() return CUR.mapID ~= nil, CUR.type end
GetInstanceInfo = function()
  return CUR.name, nil, nil, nil, nil, nil, nil, CUR.mapID
end

-- ---------------------------------------------------------------- load addon
AudioProfilesAddon = {}
local NS = AudioProfilesAddon
for _, f in ipairs({ "Const.lua", "ContentIndex.lua", "Content.lua" }) do
  local chunk, err = loadfile(ADDON .. f)
  if not chunk then error("load " .. f .. ": " .. tostring(err)) end
  chunk()
end

-- ---------------------------------------------------------------- assertions
local failures = 0
local function check(label, got, want)
  local ok = got == want
  if not ok then failures = failures + 1 end
  print(string.format("%-6s %-46s got %-34s want %s",
    ok and "ok" or "FAIL", label, "'" .. tostring(got) .. "'", "'" .. tostring(want) .. "'"))
end

local function contextFor(name, mapID, itype)
  CUR.name, CUR.mapID, CUR.type = name, mapID, itype or "party"
  return NS.GetContentContext()
end

print("--- labels (expansion name derived, not hardcoded) ---")
check("dungeon_current label", NS.CONTENT_TAG_LABELS.dungeon_current, "Dungeon (Midnight)")
check("dungeon_season label", NS.CONTENT_TAG_LABELS.dungeon_season, "Dungeon (season)")
check("raid_current label", NS.CONTENT_TAG_LABELS.raid_current, "Raid (Midnight)")

print("\n--- tier resolution (regression: 'Current Season' must not clobber) ---")
NS.EnsureContentIndex()
check("current expansion tier found by name", NS.CurrentExpansionTier(), 12)
check("Windrunner Spire keeps real tier, not 13", NS.journalInstanceTier[1001], 12)
check("Pit of Saron keeps real tier, not 13", NS.journalInstanceTier[1006], 3)
check("tier 12 is current", NS.IsCurrentExpansionTier(12), true)
check("tier 13 is not current", NS.IsCurrentExpansionTier(13), false)

print("\n--- tagging ---")
local c

c = contextFor("Pit of Saron", 658)
check("season legacy dungeon: tags", table.concat(c.tags, ","), "dungeon_season,dungeon_legacy")
check("season legacy dungeon: label", c.label, "Dungeon (season)")

c = contextFor("Halls of Reflection", 668)
check("non-pool legacy dungeon: tags", table.concat(c.tags, ","), "dungeon_legacy")

c = contextFor("Nexus-Point Xenas", 2915)
check("current dungeon outside pool: tags", table.concat(c.tags, ","), "dungeon_current")

c = contextFor("Windrunner Spire", 2805)
check("current dungeon in pool: tags", table.concat(c.tags, ","), "dungeon_season,dungeon_current")
check("current dungeon in pool: label", c.label, "Dungeon (season)")

c = contextFor("Some Raid", 9001, "raid")
check("raid unaffected: tags", table.concat(c.tags, ","), "raid_current")

CUR.mapID = nil
c = NS.GetContentContext()
check("world: tags", table.concat(c.tags, ","), "world")

print("\n--- precedence via bind order ---")
NS.db = { profiles = { { name = "A" }, { name = "B" }, { name = "C" } }, contentBindings = {} }

NS.db.contentBindings = { dungeon_legacy = 2 }
c = contextFor("Pit of Saron", 658)
local idx, tag = NS.ResolveProfileIndexForContext(c)
check("legacy bound only -> falls through", tag, "dungeon_legacy")

NS.db.contentBindings = { dungeon_legacy = 2, dungeon_season = 3 }
c = contextFor("Pit of Saron", 658)
idx, tag = NS.ResolveProfileIndexForContext(c)
check("season bound -> season wins", tag, "dungeon_season")
check("season bound -> index", idx, 3)

NS.db.contentBindings = { dungeon_season = 3 }
c = contextFor("Halls of Reflection", 668)
idx, tag = NS.ResolveProfileIndexForContext(c)
check("non-pool dungeon ignores season bind", idx, nil)

print("\n--- cold start: pool empty then arrives ---")
poolAvailable = false
NS.InvalidateSeasonIndex()
c = contextFor("Pit of Saron", 658)
check("pool unavailable -> legacy only", table.concat(c.tags, ","), "dungeon_legacy")
check("pool unavailable -> not marked built", NS._seasonIndexBuilt, false)
check("pool unavailable -> requested map info", requestCount > 0, true)

poolAvailable = true
c = contextFor("Pit of Saron", 658)
check("pool arrives -> retry picks it up", table.concat(c.tags, ","), "dungeon_season,dungeon_legacy")

print("\n--- GetMapUIInfo returning nothing is survivable ---")
C_ChallengeMode.GetMapUIInfo = function() return end
NS.InvalidateSeasonIndex()
local ok, err = pcall(contextFor, "Pit of Saron", 658)
check("all-nil returns do not error", ok, true)
if not ok then print("   error: " .. tostring(err)) end

print("\n--- unlisted instance (delve): resolution never stalls the client ---")
-- Regression: GetContentContext runs on every profile apply. EJ_SelectInstance
-- triggers encounter-data loads and froze the game for seconds on the first
-- resolve in a delve; resolution must never call it, cold or cached, and repeat
-- resolves must be free entirely.
local s0, i0 = ejSelectCount, ejInfoCount
c = contextFor("Earthcrawl Mines", 3100, "scenario")
check("unlisted instance -> no tags", table.concat(c.tags, ","), "")
check("cold resolve: no EJ_SelectInstance calls", ejSelectCount - s0, 0)

s0, i0 = ejSelectCount, ejInfoCount
c = contextFor("Earthcrawl Mines", 3100, "scenario")
check("repeat resolve: no EJ_SelectInstance calls", ejSelectCount - s0, 0)
check("repeat resolve: no EJ_GetInstanceInfo calls", ejInfoCount - i0, 0)

print("\n--- index rebuild wipes the resolve cache ---")
-- The miss above was cached; a rebuild must forget it so journal data that
-- arrives later in the session can still be found.
JOURNAL[3001] = { name = "Earthcrawl Mines", tiers = { 12 }, mapID = 3100 }
ORDER[#ORDER + 1] = 3001
NS.BuildContentIndex()
c = contextFor("Earthcrawl Mines", 3100, "scenario")
check("rebuild finds the late-listed instance", table.concat(c.tags, ","), "dungeon_current")

print("\n--- loading-screen cache wipe (no rebuild) finds a journal entry that arrived late ---")
-- Simulates what a loading screen now does: Main.lua's OnEnteringWorld calls
-- InvalidateContentResolveCache() before EnsureContentIndex/ScheduleContentAutoSwitch, so
-- BuildContentIndex is NOT re-run here -- only the resolve cache is wiped. The instance is
-- added to the journal stub but never indexed via BuildContentIndex; resolution instead
-- falls through to the live UI-map chain (EJ_GetInstanceForMap), which registers it
-- incrementally via RegisterJournalInstance -- the same live-EJ-read path a real zone-in
-- takes when EJ data for the instance loaded after login.
JOURNAL[1007] = { name = "Ashfall Crypts", tiers = { 12 }, mapID = 3500 }
ORDER[#ORDER + 1] = 1007

c = contextFor("Ashfall Crypts", 3500)
check("not yet registered -> miss cached", table.concat(c.tags, ","), "")

C_Map.GetBestMapForUnit = function() return 9999 end
EJ_GetInstanceForMap = function(uiMapID) return uiMapID == 9999 and 1007 or nil end

c = contextFor("Ashfall Crypts", 3500)
check("stale cached miss survives without invalidation", table.concat(c.tags, ","), "")

NS.InvalidateContentResolveCache()
c = contextFor("Ashfall Crypts", 3500)
check("cache wipe alone (no BuildContentIndex) finds the late-registered instance",
  table.concat(c.tags, ","), "dungeon_current")

C_Map.GetBestMapForUnit = function() return nil end
EJ_GetInstanceForMap = function() return nil end

print("")
if failures == 0 then
  print("ALL CHECKS PASSED")
else
  print(failures .. " CHECK(S) FAILED")
  os.exit(1)
end
