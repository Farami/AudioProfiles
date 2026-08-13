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

local function PrintContentContext()
  local ctx = NS.GetContentContext()
  NS.Print("Content: " .. ctx.label)
  NS.Print("Tags: " .. table.concat(ctx.tags, ", "))
  if ctx.journalID then
    NS.Print(string.format(
      "Journal: %s  tier: %s  expansion: %s  mapID: %s  type: %s",
      tostring(ctx.journalID),
      tostring(ctx.tier),
      tostring(ctx.expansion),
      tostring(ctx.instanceMapID),
      tostring(ctx.instanceType)
    ))
  end
  local idx, tag = NS.ResolveProfileIndexForContext(ctx)
  if idx then
    NS.Print("Resolved profile: " .. NS.db.profiles[idx].name .. " (via " .. tag .. ")")
  else
    NS.Print("Resolved profile: (none)")
  end
end

local function PrintContentLinks()
  NS.Print("Content bindings:")
  local any = false
  for _, tag in ipairs(NS.CONTENT_BIND_ORDER) do
    local idx = NS.db.contentBindings[tag]
    if idx and NS.db.profiles[idx] then
      any = true
      local label = NS.CONTENT_TAG_LABELS[tag] or tag
      NS.Print(string.format("  %s -> %d. %s", label, idx, NS.db.profiles[idx].name))
    end
  end
  if not any then
    NS.Print("  (none)")
  end
end

local function LinkContentTag(tag, target)
  tag = tag and tag:lower() or ""
  if not NS.CONTENT_TAG_LABELS[tag] then
    NS.Print("Unknown tag: " .. tag)
    return
  end

  if target == "" or target == "none" or target == "0" then
    NS.db.contentBindings[tag] = nil
    NS.Print("Cleared binding for " .. tag)
    NS.RefreshContentUI()
    return
  end

  local idx = tonumber(target)
  if not idx then
    local q = target:lower()
    for i, p in ipairs(NS.db.profiles) do
      if p.name:lower() == q or p.name:lower():find(q, 1, true) == 1 then
        idx = i
        break
      end
    end
  end

  if not idx or not NS.db.profiles[idx] then
    NS.Print("No profile matching: " .. target)
    return
  end

  NS.db.contentBindings[tag] = idx
  NS.Print(string.format("Linked %s -> %d. %s", tag, idx, NS.db.profiles[idx].name))
  NS.RefreshContentUI()
end

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
      NS.Print(string.format("  %d. %s", i, p.name))
    end
    return
  end

  if arg == "context" then
    PrintContentContext()
    return
  end

  if arg == "links" then
    PrintContentLinks()
    return
  end

  if arg == "link" then
    local tag, profile = rest:match("^(%S+)%s*(.*)$")
    tag = tag or ""
    profile = profile and profile:gsub("^%s+", ""):gsub("%s+$", "") or ""
    LinkContentTag(tag, profile)
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

local function OnZoneChange()
  NS.EnsureContentIndex()
  NS.ScheduleContentAutoSwitch()
end

local function OnEnteringWorld()
  NS.ClearContentSuppress()
  NS.EnsureContentIndex()
  NS.ScheduleContentAutoSwitch()
end

local function OnLogin()
  NS.EnsureDB()
  NS.BuildContentIndex()
  NS.PrepareUI()

  C_Timer.After(0.55, function()
    if NS.db.autoSwitchByContent then
      NS.ScheduleContentAutoSwitch()
    elseif NS.db.applyOnLogin and NS.db.lastAppliedName then
      for i, pr in ipairs(NS.db.profiles) do
        if pr.name == NS.db.lastAppliedName then
          NS.ApplyProfileIndex(i, true, false)
          break
        end
      end
    end

    NS.RefreshQuickBar()
    NS.RefreshContentUI()
  end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ev:SetScript("OnEvent", function(_, event, loaded)
  if event == "ADDON_LOADED" and loaded == addonName then
    NS.EnsureDB()
    return
  end

  if event == "PLAYER_LOGIN" then
    OnLogin()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" then
    OnEnteringWorld()
    return
  end

  if event == "ZONE_CHANGED_NEW_AREA" then
    OnZoneChange()
    return
  end
end)
