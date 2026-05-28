--[[
  Read/write WoW audio CVars into profile-shaped tables.
]]

local NS = AudioProfilesAddon
local CV = NS.CVars

local function gv(name)
  local v = GetCVar(name)
  local n = v and tonumber(v)
  return n or 0
end

function NS.SnapFromGame()
  return {
    master = gv(CV.master),
    music = gv(CV.music),
    sfx = gv(CV.sfx),
    ambience = gv(CV.ambience),
    dialog = gv(CV.dialog),
    dsp = GetCVar(CV.dsp) == "1",
  }
end

function NS.ApplySnap(s)
  if InCombatLockdown() then
    NS.Print("Cannot change sound settings in combat. Try again after combat.")
    return false
  end
  SetCVar(CV.master, tostring(s.master))
  SetCVar(CV.music, tostring(s.music))
  SetCVar(CV.sfx, tostring(s.sfx))
  SetCVar(CV.ambience, tostring(s.ambience))
  SetCVar(CV.dialog, tostring(s.dialog))
  SetCVar(CV.dsp, s.dsp and "1" or "0")
  return true
end

function NS.FreshProfile(name, snap)
  return {
    name = name,
    master = snap.master,
    music = snap.music,
    sfx = snap.sfx,
    ambience = snap.ambience,
    dialog = snap.dialog,
    dsp = snap.dsp,
  }
end
