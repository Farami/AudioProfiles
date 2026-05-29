--[[
  Profile list switching, widgets sync, quick bar buttons.
]]

local NS = AudioProfilesAddon
local uiSilent = false

function NS.IsUISilent()
  return uiSilent
end

function NS.SelectedProfile()
  return NS.db.profiles[NS.db.selectedIndex]
end

function NS.ProfileFromWidgetsInto(p)
  local ue = NS.ui.nameEdit
  local trimmed = ue:GetText():gsub("^%s+", ""):gsub("%s+$", "")
  if trimmed ~= "" then
    p.name = trimmed
  end
  p.master = NS.ui.slMaster:GetValue() / 100
  p.music = NS.ui.slMusic:GetValue() / 100
  p.sfx = NS.ui.slSFX:GetValue() / 100
  p.ambience = NS.ui.slAmb:GetValue() / 100
  p.dialog = NS.ui.slDlg:GetValue() / 100
  p.dsp = NS.ui.cbDSP:GetChecked()
end

function NS.SyncSelectedFromWidgets()
  local p = NS.SelectedProfile()
  if not p then
    return
  end
  NS.ProfileFromWidgetsInto(p)
end

function NS.WidgetsFromProfile(p)
  if not p or not NS.ui.frame then
    return
  end
  local ui = NS.ui
  uiSilent = true
  ui.nameEdit:SetText(p.name)
  ui.slMaster:SetValue(p.master * 100)
  ui.slMusic:SetValue(p.music * 100)
  ui.slSFX:SetValue(p.sfx * 100)
  ui.slAmb:SetValue(p.ambience * 100)
  ui.slDlg:SetValue(p.dialog * 100)
  ui.cbDSP:SetChecked(p.dsp)
  uiSilent = false
  NS.RefreshSliderVisuals()
  NS.RefreshSwitchVisuals()
end

local ApplyIndex

function NS.RefreshList()
  local ui = NS.ui
  local DB = NS.db
  if not ui.frame then
    return
  end
  local child = ui.listScroll.Child
  local rowH = 28
  local n = #DB.profiles

  for i = 1, math.max(n, #ui.listBtns) do
    local btn = ui.listBtns[i]

    if i <= n then
      if not btn then
        local idx = i
        btn = CreateFrame("Button", nil, child, "BackdropTemplate")
        btn:SetSize(math.max(child:GetWidth(), 118), rowH)
        ui.listBtns[i] = btn

        NS.SkinProfileListButton(btn)

        btn:SetScript("OnClick", function()
          NS.SyncSelectedFromWidgets()
          ApplyIndex(idx)
        end)
      end
      btn:SetSize(math.max(child:GetWidth() - 4, 114), rowH)
      btn._apLbl:SetText(DB.profiles[i].name)

      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", 2, -(i - 1) * (rowH + 2))
      NS.SetProfileListButtonSelected(btn, i == DB.selectedIndex)
      btn:Show()
    elseif btn then
      btn:Hide()
    end
  end
  ui.listScroll.Child:SetHeight(math.max(1, n) * (rowH + 2))
end

function NS.RefreshQuickBar()
  local ui = NS.ui
  if not ui.qbFrame then
    return
  end
  local DB = NS.db
  if not DB.showQuickBar then
    ui.qbFrame:Hide()
    return
  end
  ui.qbFrame:Show()
  for _, b in ipairs(ui.qbBtns) do
    b:Hide()
  end
  local SIDE = 6
  local GAP = 4
  local contentW = 0
  for i, pr in ipairs(DB.profiles) do
    local b = ui.qbBtns[i]
    if not b then
      local idx = i
      b = CreateFrame("Button", nil, ui.qbFrame, "BackdropTemplate")
      b:SetHeight(26)

      NS.PrepareQuickBarButton(b)

      b:SetScript("OnClick", function()
        ApplyIndex(idx)
      end)
      ui.qbBtns[i] = b
    end
    local short = pr.name
    if #short > 14 then
      short = short:sub(1, 12) .. ".."
    end
    b:SetText(short)
    b:SetWidth(math.max(70, 8 * #short))
    b:ClearAllPoints()
    if i == 1 then
      b:SetPoint("LEFT", ui.qbFrame, "LEFT", SIDE, 0)
      contentW = b:GetWidth()
    else
      b:SetPoint("LEFT", ui.qbBtns[i - 1], "RIGHT", GAP, 0)
      contentW = contentW + GAP + b:GetWidth()
    end
    b:Show()
  end
  ui.qbFrame:SetWidth(math.max(80, contentW + SIDE * 2))
end

ApplyIndex = function(i, silent)
  NS.PrepareUI()
  local p = NS.db.profiles[i]
  if not p then
    return
  end
  if NS.ApplySnap(p) then
    NS.db.selectedIndex = i
    NS.db.lastAppliedName = p.name
    NS.WidgetsFromProfile(p)
    NS.RefreshList()
    NS.RefreshQuickBar()
    if not silent then
      NS.Print("Applied: " .. p.name)
    end
  end
end

NS.ApplyProfileIndex = ApplyIndex

function NS.ApplyByNameFragment(q)
  q = q:lower():gsub("^%s+", ""):gsub("%s+$", "")
  if q == "" then
    return
  end
  for i, p in ipairs(NS.db.profiles) do
    if p.name:lower():find(q, 1, true) == 1 or p.name:lower() == q then
      ApplyIndex(i)
      return
    end
  end
  local partial
  for i, p in ipairs(NS.db.profiles) do
    if p.name:lower():find(q, 1, true) then
      if partial then
        NS.Print("Multiple matches; type more of the name or use /ap list.")
        return
      end
      partial = i
    end
  end
  if partial then
    ApplyIndex(partial)
    return
  end
  NS.Print("No profile matching: " .. q)
end

function NS.ApplyNextProfile()
  NS.EnsureDB()
  local n = #NS.db.profiles
  if n == 0 then
    return
  end
  local i = (NS.db.selectedIndex % n) + 1
  ApplyIndex(i, true)
  if NS.ui.frame and NS.ui.frame:IsShown() then
    NS.RefreshList()
    NS.WidgetsFromProfile(NS.SelectedProfile())
  end
  NS.RefreshQuickBar()
end

function NS.ApplyPrevProfile()
  NS.EnsureDB()
  local n = #NS.db.profiles
  if n == 0 then
    return
  end
  local i = NS.db.selectedIndex - 1
  if i < 1 then
    i = n
  end
  ApplyIndex(i, true)
  if NS.ui.frame and NS.ui.frame:IsShown() then
    NS.RefreshList()
    NS.WidgetsFromProfile(NS.SelectedProfile())
  end
  NS.RefreshQuickBar()
end
