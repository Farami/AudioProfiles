--[[
  SavedVariables: AudioProfilesDB
]]

local NS = AudioProfilesAddon

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
  if not DB.profiles or #DB.profiles == 0 then
    DB.profiles = {NS.FreshProfile("Default", NS.SnapFromGame())}
    DB.selectedIndex = 1
  end
  DB.selectedIndex = math.max(1, math.min(DB.selectedIndex or 1, #DB.profiles))

  for _, pt in ipairs({DB.uiPoint, DB.qbPoint}) do
    if pt and pt[2] and type(pt[2]) ~= "string" then
      pt[2] = "UIParent"
    end
  end
end
