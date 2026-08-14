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

--- Truncates text to at most maxChars characters (not bytes), never splitting a
--- multi-byte UTF-8 sequence. Appends ".." only when truncation actually happened.
function AudioProfilesAddon.TruncateText(text, maxChars)
  text = text or ""
  if text == "" then
    return text
  end

  -- Byte offset where each character starts, per the Lua 5.1 UTF-8 byte-class
  -- pattern -- the WoW client has no utf8 library to compute this natively.
  local starts = {}
  local i = 1
  local n = #text
  while i <= n do
    starts[#starts + 1] = i
    local b = text:byte(i)
    if b >= 240 then
      i = i + 4
    elseif b >= 224 then
      i = i + 3
    elseif b >= 194 then
      i = i + 2
    else
      i = i + 1
    end
  end

  local total = #starts
  if total <= maxChars then
    return text
  end

  local keep = math.max(0, maxChars - 2)
  local cut = starts[keep + 1] and (starts[keep + 1] - 1) or n
  return text:sub(1, cut) .. ".."
end
