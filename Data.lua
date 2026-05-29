--[[
  SavedVariables: AudioProfilesDB
]]

local NS = AudioProfilesAddon

function NS.MigrateDB(DB)
  local version = DB.version or 1

  if version < 2 then
    DB.autoSwitchByContent = false
    DB.contentBindings = DB.contentBindings or {}
    DB.suppressAutoUntilLeave = false
    DB.lastAutoContextKey = nil
    DB.version = 2
  end
end

function NS.SanitizeContentBindings()
  local DB = NS.db
  if not DB or not DB.contentBindings then
    return
  end

  local n = #DB.profiles
  for tag, idx in pairs(DB.contentBindings) do
    if type(idx) ~= "number" or idx < 1 or idx > n then
      DB.contentBindings[tag] = nil
    end
  end
end

function NS.ReindexContentBindingsAfterDelete(deletedIndex)
  local DB = NS.db
  if not DB or not DB.contentBindings then
    return
  end

  for tag, idx in pairs(DB.contentBindings) do
    if idx == deletedIndex then
      DB.contentBindings[tag] = nil
    elseif idx > deletedIndex then
      DB.contentBindings[tag] = idx - 1
    end
  end
end

function NS.EnsureDB()
  if not AudioProfilesDB or type(AudioProfilesDB) ~= "table" then
    AudioProfilesDB = CopyTable(NS.DB_DEFAULTS)
  end
  NS.db = AudioProfilesDB
  local DB = NS.db
  for k, v in pairs(NS.DB_DEFAULTS) do
    if DB[k] == nil then
      DB[k] = type(v) == "table" and CopyTable(v) or v
    end
  end

  NS.MigrateDB(DB)

  if not DB.profiles or #DB.profiles == 0 then
    DB.profiles = {NS.FreshProfile("Default", NS.SnapFromGame())}
    DB.selectedIndex = 1
  end
  DB.selectedIndex = math.max(1, math.min(DB.selectedIndex or 1, #DB.profiles))

  NS.SanitizeContentBindings()

  for _, pt in ipairs({DB.uiPoint, DB.qbPoint}) do
    if pt and pt[2] and type(pt[2]) ~= "string" then
      pt[2] = "UIParent"
    end
  end
end
