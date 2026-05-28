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

function AudioProfilesAddon.AttachCheckButtonText(cb, text)
  local lbl = cb.Text
  if lbl and lbl.SetText then
    lbl:SetText(text)
    return
  end
  lbl = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
  cb.Text = lbl
  lbl:SetText(text)
end
