--[[
  Bindings catalog strings, SavedVariables skeleton, CVars map.
]]

BINDING_HEADER_AUDIO_PROFILES = "Audio Profiles"
BINDING_NAME_AUDIO_PROFILES_TOGGLE = "Toggle configuration window"
BINDING_NAME_AUDIO_PROFILES_NEXT = "Apply next profile"
BINDING_NAME_AUDIO_PROFILES_PREV = "Apply previous profile"

local NS = AudioProfilesAddon

NS.DB_DEFAULTS = {
  version = 1,
  profiles = {},
  selectedIndex = 1,
  applyOnLogin = false,
  lastAppliedName = nil,
  showQuickBar = false,
  uiPoint = {"CENTER", "UIParent", "CENTER", 0, 0},
  qbPoint = {"BOTTOM", "UIParent", "BOTTOM", 0, 120},
}

NS.CVars = {
  master = "Sound_MasterVolume",
  music = "Sound_MusicVolume",
  sfx = "Sound_SFXVolume",
  ambience = "Sound_AmbienceVolume",
  dialog = "Sound_DialogVolume",
  dsp = "Sound_EnableDSPEffects",
}
