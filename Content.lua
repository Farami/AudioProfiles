--[[
  Content context detection, binding resolution, and auto-switch.
]]

local NS = AudioProfilesAddon

local AUTO_SWITCH_DELAYS = { 0.3, 0.8, 1.5, 2.5, 4.0 }

local function ContentLabel(tag)
  return NS.CONTENT_TAG_LABELS[tag] or tag
end

local function JournalFromUiMapChain()
  if not C_Map or not C_Map.GetBestMapForUnit or not EJ_GetInstanceForMap then
    return nil
  end

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

local function ResolveJournalInstanceID(instanceMapID, instanceName)
  NS.EnsureContentIndex()

  if instanceMapID then
    local fromIndex = NS.JournalForInstanceMapID(instanceMapID)
    if fromIndex then
      return fromIndex
    end

    local fromScan = NS.ScanJournalForInstanceMapID(instanceMapID)
    if fromScan then
      return fromScan
    end
  end

  local fromUiMap = JournalFromUiMapChain()
  if fromUiMap then
    return fromUiMap
  end

  if instanceName then
    local fromName = NS.JournalForInstanceName(instanceName)
    if fromName then
      return fromName
    end
  end

  return nil
end

local function AppendDungeonTags(tags, expansion, currentExpansion)
  tags[#tags + 1] = "dungeon"

  if expansion == nil then
    return ContentLabel("dungeon")
  end

  if expansion == currentExpansion then
    tags[#tags + 1] = "dungeon_current"
    return ContentLabel("dungeon_current")
  end

  tags[#tags + 1] = "dungeon_legacy"
  return ContentLabel("dungeon_legacy")
end

local function AppendRaidTags(tags, expansion, currentExpansion)
  tags[#tags + 1] = "raid"

  if expansion == nil then
    return ContentLabel("raid")
  end

  if expansion == currentExpansion then
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
  local expansion = NS.ExpansionForJournalTier(tier)
  local currentExpansion = GetExpansionLevel()
  local label

  if instanceType == "party" or instanceType == "scenario" then
    label = AppendDungeonTags(tags, expansion, currentExpansion)
  elseif instanceType == "raid" then
    label = AppendRaidTags(tags, expansion, currentExpansion)
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
    expansion = expansion,
    instanceMapID = instanceMapID,
    instanceType = instanceType,
  }
end

function NS.ResolveProfileIndexForContext(ctx)
  if not ctx then
    return nil
  end

  local DB = NS.db
  if not DB or not DB.contentBindings then
    return nil
  end

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

function NS.ApplyProfileForContent()
  return NS.TryAutoSwitchContent()
end

function NS.ClearContentSuppress()
  if NS.db then
    NS.db.suppressAutoUntilLeave = false
  end
end

function NS.SetContentSuppress()
  if NS.db then
    NS.db.suppressAutoUntilLeave = true
  end
end
