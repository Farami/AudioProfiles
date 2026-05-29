--[[
  Encounter Journal tier index: journalInstanceID -> EJ tier number.
  Built once at login via EJ_GetNumTiers / EJ_SelectTier / EJ_GetInstanceByIndex.
]]

local NS = AudioProfilesAddon

NS.journalInstanceTier = {}
NS.instanceMapToJournal = {}

local function JournalMapIDs(journalInstanceID)
  if not journalInstanceID or not EJ_GetInstanceInfo then
    return nil, nil
  end

  if EJ_SelectInstance then
    EJ_SelectInstance(journalInstanceID)
  end

  local _, _, _, _, _, _, dungeonAreaMapID, _, _, mapID = EJ_GetInstanceInfo(journalInstanceID)
  if mapID and mapID <= 0 then
    mapID = nil
  end

  if dungeonAreaMapID and dungeonAreaMapID <= 0 then
    dungeonAreaMapID = nil
  end

  return mapID, dungeonAreaMapID
end

local function RegisterMapLookup(mapLookup, mapID, journalID)
  if mapID and mapID > 0 and not mapLookup[mapID] then
    mapLookup[mapID] = journalID
  end
end

function NS.BuildContentIndex()
  local tierMap = NS.journalInstanceTier
  local mapLookup = NS.instanceMapToJournal
  wipe(tierMap)
  wipe(mapLookup)

  if not EJ_GetNumTiers or not EJ_SelectTier or not EJ_GetInstanceByIndex then
    return
  end

  local numTiers = EJ_GetNumTiers()
  for tier = 1, numTiers do
    EJ_SelectTier(tier)

    for isRaid = 0, 1 do
      local i = 1
      while true do
        local id = EJ_GetInstanceByIndex(i, isRaid == 1)
        if not id then
          break
        end

        tierMap[id] = tier
        local mapID, dungeonAreaMapID = JournalMapIDs(id)
        RegisterMapLookup(mapLookup, mapID, id)
        RegisterMapLookup(mapLookup, dungeonAreaMapID, id)
        i = i + 1
      end
    end
  end

  NS._contentIndexBuilt = next(tierMap) ~= nil
end

function NS.EnsureContentIndex()
  if not NS._contentIndexBuilt or not next(NS.journalInstanceTier) then
    NS.BuildContentIndex()
  end
end

function NS.RegisterJournalInstance(journalInstanceID)
  if not journalInstanceID or NS.journalInstanceTier[journalInstanceID] then
    return
  end

  NS.EnsureContentIndex()

  if not EJ_GetNumTiers or not EJ_SelectTier or not EJ_GetInstanceByIndex then
    return
  end

  local numTiers = EJ_GetNumTiers()
  for tier = 1, numTiers do
    EJ_SelectTier(tier)

    for isRaid = 0, 1 do
      local i = 1
      while true do
        local id = EJ_GetInstanceByIndex(i, isRaid == 1)
        if not id then
          break
        end

        NS.journalInstanceTier[id] = tier
        local mapID, dungeonAreaMapID = JournalMapIDs(id)
        RegisterMapLookup(NS.instanceMapToJournal, mapID, id)
        RegisterMapLookup(NS.instanceMapToJournal, dungeonAreaMapID, id)

        if id == journalInstanceID then
          return
        end

        i = i + 1
      end
    end
  end
end

function NS.JournalTierForInstance(journalInstanceID)
  if not journalInstanceID then
    return nil
  end

  NS.EnsureContentIndex()
  return NS.journalInstanceTier[journalInstanceID]
end

function NS.JournalForInstanceMapID(instanceMapID)
  if not instanceMapID then
    return nil
  end

  NS.EnsureContentIndex()
  return NS.instanceMapToJournal[instanceMapID]
end

function NS.ExpansionForJournalTier(tier)
  if not tier then
    return nil
  end

  local expansion = NS.EJ_TIER_TO_EXPANSION[tier]
  if expansion ~= nil then
    return expansion
  end

  if tier >= 1 then
    return tier - 1
  end

  return nil
end

function NS.NormalizeInstanceName(name)
  if not name then
    return ""
  end

  return name:lower():gsub("[''`´]", ""):gsub("[^a-z0-9]", "")
end

function NS.JournalForInstanceName(instanceName)
  if not instanceName or not EJ_GetInstanceInfo then
    return nil
  end

  NS.EnsureContentIndex()
  local target = NS.NormalizeInstanceName(instanceName)

  for journalID in pairs(NS.journalInstanceTier) do
    local name = EJ_GetInstanceInfo(journalID)
    if name and NS.NormalizeInstanceName(name) == target then
      return journalID
    end
  end

  return nil
end

function NS.ScanJournalForInstanceMapID(instanceMapID)
  if not instanceMapID or not EJ_GetInstanceInfo then
    return nil
  end

  NS.EnsureContentIndex()

  for journalID in pairs(NS.journalInstanceTier) do
    local mapID, dungeonAreaMapID = JournalMapIDs(journalID)
    if mapID == instanceMapID or dungeonAreaMapID == instanceMapID then
      RegisterMapLookup(NS.instanceMapToJournal, instanceMapID, journalID)
      return journalID
    end
  end

  return nil
end
