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

NS.CONTENT_TAG_LABELS = {
  world = "World",
  dungeon_current = "Dungeon (Midnight)",
  dungeon_legacy = "Dungeon (legacy)",
  raid_current = "Raid (Midnight)",
  raid_legacy = "Raid (legacy)",
}

NS.CONTENT_BIND_ORDER = {
  "raid_current",
  "raid_legacy",
  "dungeon_current",
  "dungeon_legacy",
  "world",
}

NS.EJ_TIER_TO_EXPANSION = {
  [1] = LE_EXPANSION_CLASSIC,
  [2] = LE_EXPANSION_BURNING_CRUSADE,
  [3] = LE_EXPANSION_WRATH_OF_THE_LICH_KING,
  [4] = LE_EXPANSION_CATACLYSM,
  [5] = LE_EXPANSION_MISTS_OF_PANDARIA,
  [6] = LE_EXPANSION_WARLORDS_OF_DRAENOR,
  [7] = LE_EXPANSION_LEGION,
  [8] = LE_EXPANSION_BATTLE_FOR_AZEROTH,
  [9] = LE_EXPANSION_SHADOWLANDS,
  [10] = LE_EXPANSION_DRAGONFLIGHT,
  [11] = LE_EXPANSION_THE_WAR_WITHIN,
  [12] = LE_EXPANSION_MIDNIGHT,
}

NS.CVars = {
  master = "Sound_MasterVolume",
  music = "Sound_MusicVolume",
  sfx = "Sound_SFXVolume",
  ambience = "Sound_AmbienceVolume",
  dialog = "Sound_DialogVolume",
  dsp = "Sound_EnableDSPEffects",
}
