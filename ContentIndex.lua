--[[
  Encounter Journal tier index and instance map lookups.
]]

local NS = AudioProfilesAddon

NS.journalInstanceTier = {}
NS.instanceMapToJournal = {}

local function JournalMapIDs(journalInstanceID)
  if not journalInstanceID then
    return nil, nil
  end

  EJ_SelectInstance(journalInstanceID)

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

local function TierFromSiblingJournal(journalInstanceID)
  local mapID, dungeonAreaMapID = JournalMapIDs(journalInstanceID)
  local name = EJ_GetInstanceInfo(journalInstanceID)
  local targetName = NS.NormalizeInstanceName(name)

  for otherID, tier in pairs(NS.journalInstanceTier) do
    if otherID ~= journalInstanceID then
      if targetName ~= "" then
        local otherName = EJ_GetInstanceInfo(otherID)
        if otherName and NS.NormalizeInstanceName(otherName) == targetName then
          return tier
        end
      end

      if mapID or dungeonAreaMapID then
        local oMap, oDungeon = JournalMapIDs(otherID)
        if (mapID and (mapID == oMap or mapID == oDungeon))
            or (dungeonAreaMapID and (dungeonAreaMapID == oMap or dungeonAreaMapID == oDungeon)) then
          return tier
        end
      end
    end
  end

  return nil
end

local function CacheJournalTier(journalInstanceID, tier)
  if journalInstanceID and tier then
    NS.journalInstanceTier[journalInstanceID] = tier
  end

  return tier
end

function NS.BuildContentIndex()
  local tierMap = NS.journalInstanceTier
  local mapLookup = NS.instanceMapToJournal
  wipe(tierMap)
  wipe(mapLookup)

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

  CacheJournalTier(journalInstanceID, TierFromSiblingJournal(journalInstanceID))
end

function NS.JournalTierForInstance(journalInstanceID)
  if not journalInstanceID then
    return nil
  end

  NS.EnsureContentIndex()

  local tier = NS.journalInstanceTier[journalInstanceID]
  if tier then
    return tier
  end

  NS.RegisterJournalInstance(journalInstanceID)
  tier = NS.journalInstanceTier[journalInstanceID]
  if tier then
    return tier
  end

  return CacheJournalTier(journalInstanceID, TierFromSiblingJournal(journalInstanceID))
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

  return name:lower():gsub("[''`´]", ""):gsub("[^a-z0-9]", ""):gsub("^legacy", "")
end

function NS.JournalForInstanceName(instanceName)
  if not instanceName then
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
  if not instanceMapID then
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
