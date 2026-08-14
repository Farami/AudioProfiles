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

-- Writing a sound CVar is not free: Sound_EnableDSPEffects rebuilds the DSP chain and
-- stalls the client for seconds in emitter-heavy zones. Skip writes that are no-ops.
local function SetVolume(name, value)
  local cur = tonumber(GetCVar(name))
  if cur and math.abs(cur - value) < 0.0005 then
    return
  end
  SetCVar(name, tostring(value))
end

local function SetFlag(name, enabled)
  local want = enabled and "1" or "0"
  if GetCVar(name) == want then
    return
  end
  SetCVar(name, want)
end

function NS.ApplySnap(s)
  if InCombatLockdown() then
    NS.Print("Cannot change sound settings in combat. Try again after combat.")
    return false
  end
  SetVolume(CV.master, s.master)
  SetVolume(CV.music, s.music)
  SetVolume(CV.sfx, s.sfx)
  SetVolume(CV.ambience, s.ambience)
  SetVolume(CV.dialog, s.dialog)
  SetFlag(CV.dsp, s.dsp)
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
