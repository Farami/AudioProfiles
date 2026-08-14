--[[
  Bindings catalog strings, SavedVariables skeleton, CVars map.
]]

BINDING_HEADER_AUDIO_PROFILES = "Audio Profiles"
BINDING_NAME_AUDIO_PROFILES_TOGGLE = "Toggle configuration window"
BINDING_NAME_AUDIO_PROFILES_NEXT = "Apply next profile"
BINDING_NAME_AUDIO_PROFILES_PREV = "Apply previous profile"

local NS = AudioProfilesAddon

NS.DB_DEFAULTS = {
  version = 2,
  profiles = {},
  selectedIndex = 1,
  applyOnLogin = false,
  lastAppliedName = nil,
  showQuickBar = false,
  autoSwitchByContent = false,
  contentBindings = {},
  suppressAutoUntilLeave = false,
  lastAutoContextKey = nil,
  uiPoint = {"CENTER", "UIParent", "CENTER", 0, 0},
  qbPoint = {"BOTTOM", "UIParent", "BOTTOM", 0, 120},
}

-- Named from the same GetExpansionLevel() that Content.lua compares against, so the
-- label and the current/legacy split can never disagree.
local function CurrentExpansionName()
  local level = GetExpansionLevel and GetExpansionLevel()
  local name = level and _G["EXPANSION_NAME" .. level]
  if name and name ~= "" then
    return name
  end

  return "current"
end

local EXPANSION = CurrentExpansionName()

NS.CONTENT_TAG_LABELS = {
  world = "World",
  dungeon_season = "Dungeon (season)",
  dungeon_current = "Dungeon (" .. EXPANSION .. ")",
  dungeon_legacy = "Dungeon (legacy)",
  raid_current = "Raid (" .. EXPANSION .. ")",
  raid_legacy = "Raid (legacy)",
}

-- Most specific first: the first tag with a binding wins.
NS.CONTENT_BIND_ORDER = {
  "raid_current",
  "raid_legacy",
  "dungeon_season",
  "dungeon_current",
  "dungeon_legacy",
  "world",
}

NS.CVars = {
  master = "Sound_MasterVolume",
  music = "Sound_MusicVolume",
  sfx = "Sound_SFXVolume",
  ambience = "Sound_AmbienceVolume",
  dialog = "Sound_DialogVolume",
  dsp = "Sound_EnableDSPEffects",
}
