--[[
  Audio Profiles — addon namespace bootstrap.
]]

local addonName = ...
AudioProfilesAddon = {
  name = addonName,
  ui = {},
}

function AudioProfilesAddon.Print(msg)
  print("|cff00ccffAudio Profiles|r " .. msg)
end

function AudioProfilesAddon.ResolveRelativeFrame(name)
  if name == "UIParent" or name == nil or name == "" then
    return UIParent
  end
  local g = _G[name]
  if g and g.GetObjectType then
    return g
  end
  return UIParent
end
