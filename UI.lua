--[[
  Configuration window.

  Single-screen "mixing desk" layout: the profile list lives on the left, the
  volume mixer for the selected profile on the right, and behaviour options sit
  in a footer strip. No tab switching — everything is visible at once.
]]

local NS = AudioProfilesAddon
local WHITE8 = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\FRIZQT__.TTF"

-- Warm "audio console" palette: amber primary with a green level fill.
local ACCENT = { 0.95, 0.62, 0.18 }
local LEVEL = { 0.42, 0.78, 0.45 }
local BG = { 0.10, 0.10, 0.115 }
local PANEL = { 0.13, 0.13, 0.155 }
local WIDGET_BG = { 0.17, 0.17, 0.195 }
local BORDER = { 0.24, 0.24, 0.28 }
local TEXT = { 0.92, 0.92, 0.93 }
local TEXT_DIM = { 0.56, 0.56, 0.60 }

local TITLE_H = 38
local PAD = 14
local GAP = 10
local FOOTER_H = 96
local LIST_W = 184
local LIST_PAD = 18
local WIN_W = 588
local WIN_H = 580

local function AddonMetaVersion(folderName)
  if C_AddOns and C_AddOns.GetAddOnMetadata then
    return C_AddOns.GetAddOnMetadata(folderName, "Version")
  end

  if GetAddOnMetadata then
    return GetAddOnMetadata(folderName, "Version")
  end

  return nil
end

local function RGB(t)
  return t[1], t[2], t[3]
end

local function ApplyFont(fs, size, flags)
  fs:SetFont(FONT, size, flags or "")
end

local function ApplyBackdrop(f, bg, border)
  f:SetBackdrop({
    bgFile = WHITE8,
    edgeFile = WHITE8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })

  if bg then
    f:SetBackdropColor(bg[1], bg[2], bg[3], bg[4] or 1)
  end

  if border then
    f:SetBackdropBorderColor(border[1], border[2], border[3], border[4] or 1)
  end
end

local function MakePanel(parent)
  local p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  ApplyBackdrop(p, PANEL, BORDER)

  return p
end

local function MakeHeading(parent, text)
  local fs = parent:CreateFontString(nil, "OVERLAY")
  ApplyFont(fs, 11, "")
  fs:SetTextColor(RGB(TEXT_DIM))
  fs:SetText(text:upper())

  return fs
end

local function HideCheckbox(cb)
  cb:SetAlpha(0)
  cb:SetSize(1, 1)
end

--[[ Volume slider row: caption, live % readout, and a track with a level fill. ]]
local function MakeSliderRow(parent, caption)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetHeight(38)

  local label = holder:CreateFontString(nil, "OVERLAY")
  ApplyFont(label, 12)
  label:SetPoint("TOPLEFT", 0, 0)
  label:SetTextColor(RGB(TEXT))
  label:SetText(caption)

  local value = holder:CreateFontString(nil, "OVERLAY")
  ApplyFont(value, 12)
  value:SetPoint("TOPRIGHT", 0, 0)
  value:SetTextColor(RGB(ACCENT))
  value:SetText("100%")

  local slider = CreateFrame("Slider", nil, holder)
  slider:SetPoint("BOTTOMLEFT", 0, 3)
  slider:SetPoint("BOTTOMRIGHT", 0, 3)
  slider:SetHeight(14)
  slider:SetOrientation("HORIZONTAL")
  slider:SetMinMaxValues(0, 100)
  slider:SetValueStep(1)
  slider:SetObeyStepOnDrag(true)

  local track = slider:CreateTexture(nil, "BACKGROUND")
  track:SetHeight(6)
  track:SetPoint("LEFT", 2, 0)
  track:SetPoint("RIGHT", -2, 0)
  track:SetColorTexture(RGB(WIDGET_BG))

  local fill = slider:CreateTexture(nil, "ARTWORK")
  fill:SetHeight(6)
  fill:SetPoint("LEFT", track, "LEFT", 0, 0)
  fill:SetColorTexture(LEVEL[1], LEVEL[2], LEVEL[3], 0.9)

  local thumb = slider:CreateTexture(nil, "OVERLAY")
  thumb:SetSize(5, 14)
  thumb:SetColorTexture(RGB(TEXT))
  slider:SetThumbTexture(thumb)

  slider._apUpdate = function()
    local v = slider:GetValue() or 0
    value:SetText(("%d%%"):format(math.floor(v + 0.5)))
    fill:SetWidth(math.max(1, (track:GetWidth() or 0) * (v / 100)))
  end

  return slider, holder
end

local function WireVolumeSlider(slider)
  slider:SetScript("OnValueChanged", function()
    slider._apUpdate()
    if NS.IsUISilent() then
      return
    end

    NS.SyncSelectedFromWidgets()
    NS.ApplySnap(NS.SelectedProfile())
  end)
end

--[[ Checkbox-square toggle driven by a hidden native CheckButton. ]]
local function MakeToggleRow(parent, checkbox, caption)
  HideCheckbox(checkbox)

  local f = CreateFrame("Frame", nil, parent)
  f:SetHeight(28)

  local box = CreateFrame("Frame", nil, f, "BackdropTemplate")
  box:SetSize(20, 20)
  box:SetPoint("LEFT", 0, 0)
  ApplyBackdrop(box, WIDGET_BG, BORDER)

  local mark = box:CreateTexture(nil, "ARTWORK")
  mark:SetSize(10, 10)
  mark:SetPoint("CENTER")
  mark:SetColorTexture(RGB(ACCENT))
  mark:Hide()

  local label = f:CreateFontString(nil, "OVERLAY")
  ApplyFont(label, 12)
  label:SetPoint("LEFT", box, "RIGHT", 10, 0)
  label:SetPoint("RIGHT", f, "RIGHT", -4, 0)
  label:SetJustifyH("LEFT")
  label:SetTextColor(RGB(TEXT))
  label:SetText(caption)

  local function UpdateVisual()
    if checkbox:GetChecked() then
      mark:Show()
      box:SetBackdropColor(ACCENT[1] * 0.22, ACCENT[2] * 0.22, ACCENT[3] * 0.22, 1)
      box:SetBackdropBorderColor(RGB(ACCENT))
    else
      mark:Hide()
      box:SetBackdropColor(RGB(WIDGET_BG))
      box:SetBackdropBorderColor(RGB(BORDER))
    end
  end

  checkbox:SetParent(f)

  box:EnableMouse(true)
  box:SetScript("OnMouseUp", function()
    checkbox:Click()
  end)

  box:SetScript("OnEnter", function()
    if not checkbox:GetChecked() then
      box:SetBackdropBorderColor(RGB(TEXT_DIM))
    end
  end)

  box:SetScript("OnLeave", UpdateVisual)

  f._update = UpdateVisual
  UpdateVisual()

  checkbox:HookScript("OnClick", UpdateVisual)

  return f
end

local function CreateButton(parent, w, h, label, primary)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(w, h)
  ApplyBackdrop(btn, WIDGET_BG, BORDER)

  if primary then
    btn:SetBackdropColor(ACCENT[1] * 0.30, ACCENT[2] * 0.22, ACCENT[3] * 0.08, 1)
    btn:SetBackdropBorderColor(ACCENT[1] * 0.7, ACCENT[2] * 0.7, ACCENT[3] * 0.7, 0.8)
  end

  local t = btn:CreateFontString(nil, "OVERLAY")
  ApplyFont(t, 12)
  t:SetPoint("CENTER")
  t:SetTextColor(primary and ACCENT[1] or TEXT[1], primary and ACCENT[2] or TEXT[2], primary and ACCENT[3] or TEXT[3])
  t:SetText(label)
  btn:SetFontString(t)

  btn:SetScript("OnEnter", function()
    btn:SetBackdropBorderColor(RGB(ACCENT))
    if primary then
      btn:SetBackdropColor(ACCENT[1] * 0.45, ACCENT[2] * 0.32, ACCENT[3] * 0.12, 1)
    else
      btn:SetBackdropColor(WIDGET_BG[1] + 0.05, WIDGET_BG[2] + 0.05, WIDGET_BG[3] + 0.05, 1)
    end
  end)

  btn:SetScript("OnLeave", function()
    if primary then
      btn:SetBackdropColor(ACCENT[1] * 0.30, ACCENT[2] * 0.22, ACCENT[3] * 0.08, 1)
      btn:SetBackdropBorderColor(ACCENT[1] * 0.7, ACCENT[2] * 0.7, ACCENT[3] * 0.7, 0.8)
    else
      btn:SetBackdropColor(RGB(WIDGET_BG))
      btn:SetBackdropBorderColor(RGB(BORDER))
    end
  end)

  return btn
end

function NS.SkinProfileListButton(btn)
  if btn._apStyled then
    return
  end

  btn._apStyled = true
  btn:SetBackdrop({
    bgFile = WHITE8,
    edgeFile = WHITE8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })

  local dot = btn:CreateTexture(nil, "ARTWORK")
  dot:SetSize(5, 5)
  dot:SetPoint("LEFT", 10, 0)
  dot:SetColorTexture(RGB(ACCENT))
  dot:Hide()

  local lbl = btn:CreateFontString(nil, "OVERLAY")
  ApplyFont(lbl, 12)
  lbl:SetPoint("LEFT", 22, 0)
  lbl:SetPoint("RIGHT", -8, 0)
  lbl:SetJustifyH("LEFT")
  lbl:SetWordWrap(false)

  btn._apDot = dot
  btn._apLbl = lbl

  btn:SetScript("OnEnter", function()
    if not btn._apSelected then
      btn:SetBackdropColor(1, 1, 1, 0.05)
      btn._apLbl:SetTextColor(RGB(TEXT))
    end
  end)

  btn:SetScript("OnLeave", function()
    NS.SetProfileListButtonSelected(btn, btn._apSelected)
  end)
end

function NS.SetProfileListButtonSelected(btn, selected)
  btn._apSelected = selected
  if selected then
    btn._apDot:Show()
    btn:SetBackdropColor(ACCENT[1] * 0.20, ACCENT[2] * 0.15, ACCENT[3] * 0.05, 0.9)
    btn:SetBackdropBorderColor(ACCENT[1] * 0.55, ACCENT[2] * 0.45, ACCENT[3] * 0.2, 0.7)
    btn._apLbl:SetTextColor(RGB(TEXT))
  else
    btn._apDot:Hide()
    btn:SetBackdropColor(0, 0, 0, 0)
    btn:SetBackdropBorderColor(0, 0, 0, 0)
    btn._apLbl:SetTextColor(RGB(TEXT_DIM))
  end
end

--- Recomputes slider readouts and level fills from current values.
function NS.RefreshSliderVisuals()
  local ui = NS.ui
  for _, slider in ipairs({ ui.slMaster, ui.slMusic, ui.slSFX, ui.slAmb, ui.slDlg }) do
    if slider and slider._apUpdate then
      slider._apUpdate()
    end
  end
end

--- Refreshes custom toggle visuals bound to hidden checkboxes after profile sync.
function NS.RefreshSwitchVisuals()
  local u = NS.ui
  for _, row in ipairs({ u._toggleDSP, u._toggleLogin, u._toggleBar }) do
    if row and row._update then
      row._update()
    end
  end
end

function NS.PrepareQuickBarButton(btn)
  if btn._qbSkinned then
    return
  end

  btn._qbSkinned = true
  ApplyBackdrop(btn, WIDGET_BG, BORDER)

  local fs = btn:CreateFontString(nil, "OVERLAY")
  ApplyFont(fs, 11)
  fs:SetPoint("CENTER", 0, 1)
  fs:SetTextColor(RGB(TEXT))
  btn:SetFontString(fs)

  btn:SetScript("OnEnter", function()
    btn:SetBackdropBorderColor(RGB(ACCENT))
    btn:SetBackdropColor(ACCENT[1] * 0.25, ACCENT[2] * 0.18, ACCENT[3] * 0.08, 1)
  end)

  btn:SetScript("OnLeave", function()
    btn:SetBackdropBorderColor(RGB(BORDER))
    btn:SetBackdropColor(RGB(WIDGET_BG))
  end)
end

function NS.UpdateOptionsCheckboxes()
  local ui = NS.ui
  if ui.cbLogin then
    ui.cbLogin:SetChecked(NS.db.applyOnLogin)
  end

  if ui.cbBar then
    ui.cbBar:SetChecked(NS.db.showQuickBar)
  end

  NS.RefreshSwitchVisuals()
end

function NS.PrepareUI()
  NS.EnsureDB()
  if NS.ui.frame then
    return
  end

  NS.BuildUI()
  NS.RefreshList()
  NS.WidgetsFromProfile(NS.SelectedProfile())
  NS.UpdateOptionsCheckboxes()
  NS.RefreshQuickBar()
end

local function BuildTitleBar(f, ver)
  local titleBar = CreateFrame("Frame", nil, f)
  titleBar:SetHeight(TITLE_H)
  titleBar:SetPoint("TOPLEFT")
  titleBar:SetPoint("TOPRIGHT")

  local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
  titleBg:SetAllPoints()
  titleBg:SetColorTexture(RGB(PANEL))

  local titleLine = titleBar:CreateTexture(nil, "ARTWORK")
  titleLine:SetHeight(1)
  titleLine:SetPoint("BOTTOMLEFT")
  titleLine:SetPoint("BOTTOMRIGHT")
  titleLine:SetColorTexture(RGB(BORDER))

  local mark = titleBar:CreateTexture(nil, "ARTWORK")
  mark:SetSize(4, 16)
  mark:SetPoint("LEFT", 14, -1)
  mark:SetColorTexture(RGB(ACCENT))

  local titleStr = titleBar:CreateFontString(nil, "OVERLAY")
  ApplyFont(titleStr, 15, "")
  titleStr:SetPoint("LEFT", mark, "RIGHT", 10, 0)
  titleStr:SetTextColor(RGB(TEXT))
  titleStr:SetText("Audio Profiles")

  local verStr = titleBar:CreateFontString(nil, "OVERLAY")
  ApplyFont(verStr, 10)
  verStr:SetPoint("RIGHT", -42, 0)
  verStr:SetTextColor(RGB(TEXT_DIM))
  verStr:SetText("v" .. ver)

  local closeBtn = CreateFrame("Button", nil, titleBar)
  closeBtn:SetSize(28, 28)
  closeBtn:SetPoint("RIGHT", -6, 0)

  local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
  ApplyFont(closeX, 18)
  closeX:SetPoint("CENTER")
  closeX:SetText("\195\151")
  closeX:SetTextColor(0.6, 0.6, 0.62)

  closeBtn:SetScript("OnEnter", function()
    closeX:SetTextColor(1, 0.4, 0.35)
  end)

  closeBtn:SetScript("OnLeave", function()
    closeX:SetTextColor(0.6, 0.6, 0.62)
  end)

  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)
end

local function BuildListPanel(panel, DB)
  local ui = NS.ui

  local heading = MakeHeading(panel, "Profiles")
  heading:SetPoint("TOPLEFT", LIST_PAD, -10)

  local btnRowH = 26
  local barH = 10 + btnRowH + 6 + btnRowH + 10

  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", LIST_PAD, -28)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -LIST_PAD, barH)

  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(LIST_W - 2 * LIST_PAD, 100)
  scroll:SetScrollChild(child)

  ui.listScroll = scroll
  scroll.Child = child
  ui.listBtns = {}

  local innerW = LIST_W - 2 * LIST_PAD
  local btnDel = CreateButton(panel, innerW, btnRowH, "Delete")
  btnDel:SetPoint("BOTTOMLEFT", LIST_PAD, 10)

  local halfGap = 6
  local halfW = math.floor((innerW - halfGap) / 2)

  local btnNew = CreateButton(panel, halfW, btnRowH, "New")
  btnNew:SetPoint("BOTTOMLEFT", btnDel, "TOPLEFT", 0, halfGap)

  local btnDup = CreateButton(panel, innerW - halfGap - halfW, btnRowH, "Copy")
  btnDup:SetPoint("BOTTOMRIGHT", btnDel, "TOPRIGHT", 0, halfGap)

  btnNew:SetScript("OnClick", function()
    NS.SyncSelectedFromWidgets()
    local k = #DB.profiles + 1
    DB.profiles[k] = NS.FreshProfile("Profile " .. k, NS.SnapFromGame())
    DB.selectedIndex = k
    NS.RefreshList()
    NS.WidgetsFromProfile(NS.SelectedProfile())
    NS.RefreshQuickBar()
  end)

  btnDup:SetScript("OnClick", function()
    NS.SyncSelectedFromWidgets()
    local p = NS.SelectedProfile()
    if not p then
      return
    end

    local snap = {
      master = p.master,
      music = p.music,
      sfx = p.sfx,
      ambience = p.ambience,
      dialog = p.dialog,
      dsp = p.dsp,
    }
    local k = #DB.profiles + 1
    DB.profiles[k] = NS.FreshProfile(p.name .. " copy", snap)
    DB.selectedIndex = k
    NS.RefreshList()
    NS.WidgetsFromProfile(NS.SelectedProfile())
    NS.RefreshQuickBar()
  end)

  btnDel:SetScript("OnClick", function()
    if #DB.profiles <= 1 then
      NS.Print("You need at least one profile.")
      return
    end

    table.remove(DB.profiles, DB.selectedIndex)
    DB.selectedIndex = math.min(DB.selectedIndex, #DB.profiles)
    NS.RefreshList()
    NS.ApplyProfileIndex(DB.selectedIndex, true)
    NS.RefreshQuickBar()
  end)
end

local function BuildMixerPanel(panel, DB)
  local ui = NS.ui
  local innerW = (WIN_W - 2 * PAD - LIST_W - GAP) - 28

  local heading = MakeHeading(panel, "Mixer")
  heading:SetPoint("TOPLEFT", 14, -10)

  local nameLbl = panel:CreateFontString(nil, "OVERLAY")
  ApplyFont(nameLbl, 11)
  nameLbl:SetPoint("TOPLEFT", 14, -30)
  nameLbl:SetTextColor(RGB(TEXT_DIM))
  nameLbl:SetText("Profile name")

  local nameEdit = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
  nameEdit:SetSize(innerW, 24)
  nameEdit:SetPoint("TOPLEFT", 14, -46)
  ApplyBackdrop(nameEdit, WIDGET_BG, BORDER)
  nameEdit:SetAutoFocus(false)
  ApplyFont(nameEdit, 12)
  nameEdit:SetTextColor(RGB(TEXT))
  nameEdit:SetTextInsets(8, 8, 0, 0)

  nameEdit:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
  end)

  nameEdit:SetScript("OnEditFocusLost", function()
    NS.SyncSelectedFromWidgets()
    NS.RefreshList()
    NS.RefreshQuickBar()
  end)

  ui.nameEdit = nameEdit

  local rows = {
    { key = "slMaster", caption = "Master" },
    { key = "slMusic", caption = "Music" },
    { key = "slSFX", caption = "Sound effects" },
    { key = "slAmb", caption = "Ambience" },
    { key = "slDlg", caption = "Dialog" },
  }

  local anchor = nameEdit
  local anchorPoint = "BOTTOMLEFT"
  local anchorY = -16
  for _, row in ipairs(rows) do
    local slider, holder = MakeSliderRow(panel, row.caption)
    holder:SetWidth(innerW)
    holder:SetPoint("TOPLEFT", anchor, anchorPoint, 0, anchorY)
    WireVolumeSlider(slider)
    ui[row.key] = slider

    anchor = holder
    anchorPoint = "BOTTOMLEFT"
    anchorY = -8
  end

  ui.cbDSP = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
  ui.cbDSP:Hide()
  ui.cbDSP:SetScript("OnClick", function()
    if NS.IsUISilent() then
      return
    end

    NS.SyncSelectedFromWidgets()
    NS.ApplySnap(NS.SelectedProfile())
  end)

  local dspRow = MakeToggleRow(panel, ui.cbDSP, "Gameplay sound effects (DSP)")
  dspRow:SetWidth(innerW)
  dspRow:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
  ui._toggleDSP = dspRow

  local btnW = math.floor((innerW - 10) / 2)

  local btnApply = CreateButton(panel, btnW, 30, "Apply to WoW", true)
  btnApply:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, 12)
  btnApply:SetScript("OnClick", function()
    NS.SyncSelectedFromWidgets()
    NS.ApplyProfileIndex(DB.selectedIndex)
  end)

  local btnCap = CreateButton(panel, btnW, 30, "Load from WoW")
  btnCap:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 12)
  btnCap:SetScript("OnClick", function()
    local snap = NS.SnapFromGame()
    local p = NS.SelectedProfile()
    p.master, p.music, p.sfx, p.ambience, p.dialog, p.dsp =
      snap.master, snap.music, snap.sfx, snap.ambience, snap.dialog, snap.dsp
    NS.WidgetsFromProfile(p)
    NS.Print("Copied current WoW volumes into this profile.")
  end)
end

local function BuildFooter(footer, DB)
  local ui = NS.ui
  local innerW = (WIN_W - 2 * PAD) - 28

  local heading = MakeHeading(footer, "Options")
  heading:SetPoint("TOPLEFT", 12, -10)

  ui.cbLogin = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
  ui.cbLogin:Hide()
  ui.cbLogin:SetScript("OnClick", function()
    DB.applyOnLogin = ui.cbLogin:GetChecked()
  end)

  local loginRow = MakeToggleRow(footer, ui.cbLogin, "Re-apply last profile after login")
  loginRow:SetWidth(innerW)
  loginRow:SetPoint("TOPLEFT", 14, -30)
  ui._toggleLogin = loginRow

  ui.cbBar = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
  ui.cbBar:Hide()
  ui.cbBar:SetScript("OnClick", function()
    DB.showQuickBar = ui.cbBar:GetChecked()
    NS.RefreshQuickBar()
  end)

  local barRow = MakeToggleRow(footer, ui.cbBar, "Show draggable quick-switch bar")
  barRow:SetWidth(innerW)
  barRow:SetPoint("TOPLEFT", loginRow, "BOTTOMLEFT", 0, -4)
  ui._toggleBar = barRow
end

local function BuildQuickBar(DB)
  local ui = NS.ui

  local qb = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  qb:SetFrameStrata("MEDIUM")
  ApplyBackdrop(qb, { BG[1], BG[2], BG[3], 0.92 }, { ACCENT[1] * 0.5, ACCENT[2] * 0.4, ACCENT[3] * 0.18, 0.9 })
  qb:SetSize(420, 36)
  qb:SetClampedToScreen(true)
  qb:EnableMouse(true)
  qb:SetMovable(true)
  qb:RegisterForDrag("LeftButton")
  qb:SetScript("OnDragStart", qb.StartMoving)
  qb:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt, _, rp, x, y = self:GetPoint(1)
    DB.qbPoint = { pt, "UIParent", rp, x, y }
  end)

  local qpt = DB.qbPoint
  if qpt and qpt[1] then
    qb:SetPoint(qpt[1], NS.ResolveRelativeFrame(qpt[2]), qpt[3] or qpt[1], qpt[4] or 0, qpt[5] or 0)
  else
    qb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 120)
  end

  ui.qbFrame = qb
  ui.qbBtns = {}

  qb:Hide()
end

function NS.BuildUI()
  local ui = NS.ui
  if ui.frame then
    return
  end

  NS.EnsureDB()
  local DB = NS.db
  local ver = AddonMetaVersion(NS.name) or "?"

  local f = CreateFrame("Frame", "AudioProfilesConfigFrame", UIParent, "BackdropTemplate")
  f:SetSize(WIN_W, WIN_H)
  f:SetFrameStrata("DIALOG")
  f:SetFrameLevel(100)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local pt, _, rp, x, y = self:GetPoint(1)
    DB.uiPoint = { pt, "UIParent", rp, x, y }
  end)

  ApplyBackdrop(f, BG, { ACCENT[1] * 0.45, ACCENT[2] * 0.35, ACCENT[3] * 0.15, 0.7 })
  ui.frame = f

  local uipt = DB.uiPoint
  if uipt and uipt[1] then
    f:SetPoint(uipt[1], NS.ResolveRelativeFrame(uipt[2]), uipt[3] or uipt[1], uipt[4] or 0, uipt[5] or 0)
  else
    f:SetPoint("CENTER")
  end

  BuildTitleBar(f, ver)

  local footer = MakePanel(f)
  footer:SetHeight(FOOTER_H)
  footer:SetPoint("BOTTOMLEFT", PAD, PAD)
  footer:SetPoint("BOTTOMRIGHT", -PAD, PAD)

  local listPanel = MakePanel(f)
  listPanel:SetWidth(LIST_W)
  listPanel:SetPoint("TOPLEFT", PAD, -(TITLE_H + PAD))
  listPanel:SetPoint("BOTTOMLEFT", footer, "TOPLEFT", 0, GAP)

  local mixerPanel = MakePanel(f)
  mixerPanel:SetPoint("TOPLEFT", listPanel, "TOPRIGHT", GAP, 0)
  mixerPanel:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT", 0, GAP)

  BuildListPanel(listPanel, DB)
  BuildMixerPanel(mixerPanel, DB)
  BuildFooter(footer, DB)

  tinsert(UISpecialFrames, f:GetName())

  BuildQuickBar(DB)

  f:Hide()
end

function NS.ToggleMainFrame()
  NS.EnsureDB()
  NS.PrepareUI()
  if NS.ui.frame:IsShown() then
    NS.ui.frame:Hide()
  else
    NS.UpdateOptionsCheckboxes()
    NS.RefreshList()
    NS.WidgetsFromProfile(NS.SelectedProfile())
    NS.RefreshQuickBar()
    NS.ui.frame:Show()
  end
end
