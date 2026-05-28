--[[
  Slash commands, keybinding entry points, PLAYER_LOGIN wiring.
]]

local NS = AudioProfilesAddon
local addonName = NS.name

function ToggleAudioProfilesFrame()
  NS.ToggleMainFrame()
end

_G.ToggleAudioProfilesFrame = ToggleAudioProfilesFrame

function AudioProfiles_ApplyNext()
  NS.ApplyNextProfile()
end

_G.AudioProfiles_ApplyNext = AudioProfiles_ApplyNext

function AudioProfiles_ApplyPrev()
  NS.ApplyPrevProfile()
end

_G.AudioProfiles_ApplyPrev = AudioProfiles_ApplyPrev

SLASH_AUDIO_PROFILES1 = "/audioprofiles"
SLASH_AUDIO_PROFILES2 = "/ap"
SlashCmdList["AUDIO_PROFILES"] = function(msg)
  NS.EnsureDB()
  msg = msg or ""
  local arg = msg:match("^%s*(%S+)") or ""
  local rest = msg:match("^%s*%S+%s+(.+)$") or ""
  rest = rest:gsub("^%s+", ""):gsub("%s+$", "")

  if arg == "" or arg == "toggle" or arg == "config" or arg == "ui" then
    NS.ToggleMainFrame()
    return
  end

  if arg == "list" then
    NS.Print("Profiles:")
    for i, p in ipairs(NS.db.profiles) do
      print(string.format("  %d. %s", i, p.name))
    end
    return
  end

  if arg == "next" or arg == "n" then
    NS.ApplyNextProfile()
    return
  end

  if arg == "prev" or arg == "p" or arg == "previous" then
    NS.ApplyPrevProfile()
    return
  end

  if arg == "apply" and rest ~= "" then
    NS.ApplyByNameFragment(rest)
    return
  end

  if tonumber(arg) then
    local i = tonumber(arg)
    if NS.db.profiles[i] then
      NS.ApplyProfileIndex(i)
      if NS.ui.frame and NS.ui.frame:IsShown() then
        NS.RefreshList()
        NS.WidgetsFromProfile(NS.SelectedProfile())
      end
      NS.RefreshQuickBar()
    else
      NS.Print("No profile at index " .. i)
    end
    return
  end

  NS.ApplyByNameFragment(arg .. (rest ~= "" and (" " .. rest) or ""))
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, loaded)
  if event == "ADDON_LOADED" and loaded == addonName then
    NS.EnsureDB()
    return
  end

  if event == "PLAYER_LOGIN" then
    NS.EnsureDB()
    NS.PrepareUI()

    C_Timer.After(0.55, function()
      if NS.db.applyOnLogin and NS.db.lastAppliedName then
        for i, pr in ipairs(NS.db.profiles) do
          if pr.name == NS.db.lastAppliedName then
            NS.ApplyProfileIndex(i, true)
            break
          end
        end
      end

      NS.RefreshQuickBar()
    end)

    return
  end
end)


