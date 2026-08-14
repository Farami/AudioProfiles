--[[
  Content context detection, binding resolution, and auto-switch.
]]

local NS = AudioProfilesAddon

local AUTO_SWITCH_DELAYS = { 0.3, 0.8, 1.5, 2.5, 4.0 }

local function ContentLabel(tag)
  return NS.CONTENT_TAG_LABELS[tag] or tag
end

local function JournalFromUiMapChain()
  local uiMapID = C_Map.GetBestMapForUnit("player")
  local seen = {}

  while uiMapID and uiMapID > 0 and not seen[uiMapID] do
    seen[uiMapID] = true
    local journalID = EJ_GetInstanceForMap(uiMapID)
    if journalID and journalID > 0 then
      NS.RegisterJournalInstance(journalID)
      return journalID
    end

    local info = C_Map.GetMapInfo(uiMapID)
    uiMapID = info and info.parentMapID or 0
  end

  return nil
end

local function ResolveJournalInstanceIDUncached(instanceMapID, instanceName)
  NS.EnsureContentIndex()

  if instanceMapID then
    local fromIndex = NS.JournalForInstanceMapID(instanceMapID)
    if fromIndex then
      return fromIndex
    end
  end

  local fromUiMap = JournalFromUiMapChain()
  if fromUiMap then
    NS.RegisterJournalInstance(fromUiMap)
    if NS.journalInstanceTier[fromUiMap] then
      return fromUiMap
    end
  end

  if instanceName then
    local fromName = NS.JournalForInstanceName(instanceName)
    if fromName then
      return fromName
    end
  end

  return fromUiMap
end

-- Instances the journal does not list at all (delves, brawls) make every fallback
-- above run to exhaustion -- a map-chain walk plus an EJ_GetInstanceInfo per known
-- journal instance. GetContentContext runs on every profile apply, so misses are
-- cached as false rather than re-resolved per click. Two things wipe the cache:
-- BuildContentIndex (an index rebuild invalidates map/tier lookups it feeds) and
-- Main.lua's PLAYER_ENTERING_WORLD handler (every loading screen gets one fresh
-- attempt, so a miss cached against a login-time journal index that loaded
-- incomplete doesn't survive to relog).
local resolveCache = {}

function NS.InvalidateContentResolveCache()
  wipe(resolveCache)
end

local function ResolveJournalInstanceID(instanceMapID, instanceName)
  local key = instanceMapID or instanceName
  if key == nil then
    return ResolveJournalInstanceIDUncached(instanceMapID, instanceName)
  end

  local cached = resolveCache[key]
  if cached ~= nil then
    return cached or nil
  end

  local journalID = ResolveJournalInstanceIDUncached(instanceMapID, instanceName)
  resolveCache[key] = journalID or false
  return journalID
end

-- A season-pool dungeon from an older expansion carries both dungeon_season and
-- dungeon_legacy; bind order decides which one wins. Tags are appended most-specific
-- first so the label always names the highest-precedence tag.
local function AppendDungeonTags(tags, tier, isSeason)
  local first = #tags + 1

  if isSeason then
    tags[#tags + 1] = "dungeon_season"
  end

  if tier ~= nil then
    if NS.IsCurrentExpansionTier(tier) then
      tags[#tags + 1] = "dungeon_current"
    else
      tags[#tags + 1] = "dungeon_legacy"
    end
  end

  local primary = tags[first]
  if not primary then
    return "Dungeon"
  end

  return ContentLabel(primary)
end

local function AppendRaidTags(tags, tier)
  if tier == nil then
    return "Raid"
  end

  if NS.IsCurrentExpansionTier(tier) then
    tags[#tags + 1] = "raid_current"
    return ContentLabel("raid_current")
  end

  tags[#tags + 1] = "raid_legacy"
  return ContentLabel("raid_legacy")
end

function NS.GetContentContext()
  local inInstance, instanceType = IsInInstance()
  local tags = {}

  if not inInstance then
    tags[#tags + 1] = "world"
    return { tags = tags, label = ContentLabel("world"), contextKey = "world" }
  end

  local name, _, _, _, _, _, _, instanceMapID = GetInstanceInfo()
  local journalID = ResolveJournalInstanceID(instanceMapID, name)
  local tier = NS.JournalTierForInstance(journalID)
  local label
  local isSeason = false

  if instanceType == "party" or instanceType == "scenario" then
    isSeason = NS.IsSeasonDungeon(instanceMapID, journalID, name)
    label = AppendDungeonTags(tags, tier, isSeason)
  elseif instanceType == "raid" then
    label = AppendRaidTags(tags, tier)
  else
    label = name or "Instance"
  end

  local contextKey = table.concat(tags, ",")
  return {
    tags = tags,
    label = label,
    contextKey = contextKey,
    journalID = journalID,
    tier = tier,
    currentTier = NS.CurrentExpansionTier(),
    instanceMapID = instanceMapID,
    instanceType = instanceType,
    isSeason = isSeason,
  }
end

function NS.ResolveProfileIndexForContext(ctx)
  local DB = NS.db
  local tagSet = {}
  for _, tag in ipairs(ctx.tags) do
    tagSet[tag] = true
  end

  for _, tag in ipairs(NS.CONTENT_BIND_ORDER) do
    if tagSet[tag] then
      local idx = DB.contentBindings[tag]
      if idx and DB.profiles[idx] then
        return idx, tag
      end
    end
  end

  return nil
end

function NS.TryAutoSwitchContent()
  NS.EnsureDB()
  NS.EnsureContentIndex()
  local DB = NS.db

  if not DB.autoSwitchByContent then
    return false
  end

  if DB.suppressAutoUntilLeave then
    return false
  end

  local ctx = NS.GetContentContext()
  local idx = NS.ResolveProfileIndexForContext(ctx)
  if not idx then
    DB.lastAutoContextKey = ctx.contextKey
    return false
  end

  if idx == DB.selectedIndex then
    DB.lastAutoContextKey = ctx.contextKey
    return false
  end

  DB.lastAutoContextKey = ctx.contextKey
  if NS.ApplyProfileIndex(idx, true, false) then
    NS.Print("Auto-applied: " .. DB.profiles[idx].name .. " (" .. ctx.label .. ")")
    return true
  end

  return false
end

function NS.ScheduleContentAutoSwitch()
  NS.EnsureDB()
  if not NS.db.autoSwitchByContent then
    return
  end

  NS.EnsureContentIndex()

  for _, delay in ipairs(AUTO_SWITCH_DELAYS) do
    C_Timer.After(delay, function()
      if NS.TryAutoSwitchContent() then
        NS.RefreshContentUI()
      elseif delay == AUTO_SWITCH_DELAYS[#AUTO_SWITCH_DELAYS] then
        NS.RefreshContentUI()
      end
    end)
  end
end

function NS.ClearContentSuppress()
  NS.db.suppressAutoUntilLeave = false
end

function NS.SetContentSuppress()
  NS.db.suppressAutoUntilLeave = true
end
