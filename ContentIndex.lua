--[[
  Encounter Journal tier index, instance map lookups, and Mythic+ season pool.
]]

local NS = AudioProfilesAddon

NS.journalInstanceTier = {}
NS.instanceMapToJournal = {}

-- Current Mythic+ dungeon pool, read live from the client so it never needs
-- updating when the seasonal rotation changes.
NS.seasonInstanceMaps = {}
NS.seasonJournalIDs = {}
NS.seasonNames = {}

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

local SEASON_REQUEST_COOLDOWN = 5
local seasonRequestedAt = 0

local function RequestSeasonMapInfo()
  if not (C_MythicPlus and C_MythicPlus.RequestMapInfo) then
    return
  end

  local now = GetTime()
  if now - seasonRequestedAt < SEASON_REQUEST_COOLDOWN then
    return
  end

  seasonRequestedAt = now
  pcall(C_MythicPlus.RequestMapInfo)
end

local function SeasonChallengeMaps()
  if not (C_ChallengeMode and C_ChallengeMode.GetMapTable and C_ChallengeMode.GetMapUIInfo) then
    return nil
  end

  local ok, maps = pcall(C_ChallengeMode.GetMapTable)
  if not ok or type(maps) ~= "table" or #maps == 0 then
    return nil
  end

  return maps
end

-- Two challenge maps can share one instance (megadungeon halves); a set absorbs that.
local function RegisterSeasonMapID(instanceMapID)
  if type(instanceMapID) ~= "number" or instanceMapID <= 0 then
    return
  end

  NS.seasonInstanceMaps[instanceMapID] = true

  -- Cheap table hit only. ScanJournalForInstanceMapID walks every instance with an
  -- EJ_SelectInstance per step, which would hitch on zone-in for no real gain.
  local journalID = NS.instanceMapToJournal[instanceMapID]
  if journalID then
    NS.seasonJournalIDs[journalID] = true
  end
end

function NS.BuildContentIndex()
  local tierMap = NS.journalInstanceTier
  local mapLookup = NS.instanceMapToJournal
  wipe(tierMap)
  wipe(mapLookup)
  NS._currentExpansionTier = nil

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

        -- First tier wins: the journal re-lists instances under appended
        -- pseudo-tiers ("Current Season"), which must not replace the real one.
        if not tierMap[id] then
          tierMap[id] = tier
        end

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

        if not NS.journalInstanceTier[id] then
          NS.journalInstanceTier[id] = tier
        end

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

-- Found by name rather than by index. The journal's tier list is not a plain
-- expansion list -- it carries appended entries such as "Current Season" -- so any
-- index-based mapping silently rots the moment Blizzard inserts one. Searching
-- forward takes the real expansion tier over a later re-listing of it.
function NS.CurrentExpansionTier()
  if NS._currentExpansionTier then
    return NS._currentExpansionTier
  end

  local target = _G["EXPANSION_NAME" .. GetExpansionLevel()]
  if not target or target == "" then
    return nil
  end

  for tier = 1, EJ_GetNumTiers() do
    if EJ_GetTierInfo(tier) == target then
      NS._currentExpansionTier = tier
      return tier
    end
  end

  return nil
end

function NS.IsCurrentExpansionTier(tier)
  if not tier then
    return false
  end

  local current = NS.CurrentExpansionTier()
  return current ~= nil and tier == current
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

-- C_ChallengeMode.GetMapUIInfo may return nothing at all, so every field is optional.
-- Its 6th return is an instance map ID, the same space as GetInstanceInfo()'s 8th.
function NS.BuildSeasonIndex()
  wipe(NS.seasonInstanceMaps)
  wipe(NS.seasonJournalIDs)
  wipe(NS.seasonNames)
  NS._seasonIndexBuilt = false

  local maps = SeasonChallengeMaps()
  if not maps then
    RequestSeasonMapInfo()
    return
  end

  NS.EnsureContentIndex()

  for _, challengeMapID in ipairs(maps) do
    local ok, name, _, _, _, _, instanceMapID = pcall(C_ChallengeMode.GetMapUIInfo, challengeMapID)

    if ok then
      RegisterSeasonMapID(instanceMapID)

      if name and name ~= "" then
        local key = NS.NormalizeInstanceName(name)
        if key ~= "" then
          NS.seasonNames[key] = true
        end
      end
    end
  end

  NS._seasonIndexBuilt = next(NS.seasonInstanceMaps) ~= nil or next(NS.seasonNames) ~= nil

  -- Map data is server-fed and can be empty early in the session. Leaving the built
  -- flag false lets the auto-switch retry ladder pick it up once the request lands.
  if not NS._seasonIndexBuilt then
    RequestSeasonMapInfo()
  end
end

function NS.EnsureSeasonIndex()
  if not NS._seasonIndexBuilt then
    NS.BuildSeasonIndex()
  end
end

function NS.InvalidateSeasonIndex()
  NS._seasonIndexBuilt = false
end

function NS.IsSeasonDungeon(instanceMapID, journalID, instanceName)
  NS.EnsureSeasonIndex()

  if not NS._seasonIndexBuilt then
    return false
  end

  if instanceMapID and NS.seasonInstanceMaps[instanceMapID] then
    return true
  end

  if journalID and NS.seasonJournalIDs[journalID] then
    return true
  end

  if instanceName then
    local key = NS.NormalizeInstanceName(instanceName)
    if key ~= "" and NS.seasonNames[key] then
      return true
    end
  end

  return false
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
