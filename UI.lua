--[[
  Configuration frame — layout inspired by BliZzi Interrupts (modern dark sidebar + content).
]]

local NS = AudioProfilesAddon
local WHITE8 = "Interface\\Buttons\\WHITE8X8"

local ACCENT = { 0, 204 / 255, 1 }
local BG = { 0.06, 0.06, 0.08 }
local SIDEBAR = { 0.09, 0.09, 0.11 }
local WIDGET_BG = { 0.12, 0.12, 0.14 }
local BORDER = { 0.20, 0.20, 0.24 }
local TEXT = { 0.90, 0.90, 0.92 }
local TEXT_DIM = { 0.55, 0.55, 0.60 }

local SIDEBAR_W = 176
local WIN_W = 720
local WIN_H = 628

local FONT = "Fonts\\FRIZQT__.TTF"

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

local function MakeBackdropFrame(f)
  f:SetBackdrop({
    bgFile = WHITE8,
    edgeFile = WHITE8,
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
end

local function MakeBg(f, r, g, b, a)
  MakeBackdropFrame(f)
  f:SetBackdropColor(r, g, b, a or 0.96)
  f:SetBackdropBorderColor(RGB(BORDER))
end

local function SkinFont(fs, sz, outline)
  fs:SetFont(FONT, sz, outline or "")
end

local function MakeSliderRow(parent, relFrame, anchorPoint, dx, dy, title, contentInnerW)
  local holder = CreateFrame("Frame", nil, parent)
  holder:SetSize(contentInnerW, 40)
  holder:SetPoint("TOPLEFT", relFrame, anchorPoint, dx, dy)

  local la = holder:CreateFontString(nil, "OVERLAY")
  SkinFont(la, 11)
  la:SetPoint("TOPLEFT", 0, -2)
  la:SetWidth(math.floor(contentInnerW * 0.55))
  la:SetJustifyH("LEFT")
  la:SetTextColor(RGB(TEXT_DIM))
  la:SetText(title)

  local val = holder:CreateFontString(nil, "OVERLAY")
  SkinFont(val, 11)
  val:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, -2)
  val:SetJustifyH("RIGHT")
  val:SetTextColor(RGB(TEXT))
  val:SetText("100%")

  local sl = CreateFrame("Slider", nil, holder, "MinimalSliderTemplate")
  sl:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 2)
  sl:SetSize(contentInnerW - 12, 16)
  sl:SetMinMaxValues(0, 100)
  sl:SetValueStep(1)
  sl:SetObeyStepOnDrag(true)

  return sl, val, holder
end

local function WireVolumeSlider(s, lbl)
  s:SetScript("OnValueChanged", function(_, v)
    if NS.IsUISilent() then
      return
    end
    lbl:SetText(string.format("%.0f%%", v))
    NS.SyncSelectedFromWidgets()
    NS.ApplySnap(NS.SelectedProfile())
  end)
end

local sidebarBtns = {}
local activePage = nil

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

  local ind = btn:CreateTexture(nil, "ARTWORK")
  ind:SetWidth(3)
  ind:SetPoint("TOPLEFT")
  ind:SetPoint("BOTTOMLEFT")
  ind:SetColorTexture(RGB(ACCENT))
  ind:Hide()

  local lbl = btn:CreateFontString(nil, "OVERLAY")
  SkinFont(lbl, 11)
  lbl:SetPoint("LEFT", ind, "RIGHT", 8, 0)
  lbl:SetPoint("RIGHT", -8, 0)
  lbl:SetJustifyH("LEFT")
  lbl:SetTextColor(RGB(TEXT))

  btn._apInd = ind
  btn._apLbl = lbl

  btn:SetScript("OnEnter", function()
    btn:SetBackdropColor(ACCENT[1] * 0.15, ACCENT[2] * 0.15, ACCENT[3] * 0.15, 0.9)
  end)
  btn:SetScript("OnLeave", function()
    NS.SetProfileListButtonSelected(btn, btn._apSelected)
  end)
end

function NS.SetProfileListButtonSelected(btn, selected)
  btn._apSelected = selected
  if selected then
    btn._apInd:Show()
    btn:SetBackdropColor(ACCENT[1] * 0.12, ACCENT[2] * 0.12, ACCENT[3] * 0.12, 1)
    btn:SetBackdropBorderColor(ACCENT[1] * 0.45, ACCENT[2] * 0.45, ACCENT[3] * 0.45, 0.85)
    btn._apLbl:SetTextColor(RGB(TEXT))
  else
    btn._apInd:Hide()
    btn:SetBackdropColor(RGB(WIDGET_BG))
    btn:SetBackdropBorderColor(RGB(BORDER))
    btn._apLbl:SetTextColor(RGB(TEXT_DIM))
  end
end

--- Refreshes custom switch visuals bound to hidden checkboxes after profile sync.
function NS.RefreshSwitchVisuals()
  local u = NS.ui
  if u._toggleDSP and u._toggleDSP._update then
    u._toggleDSP._update()
  end
  if u._toggleLogin and u._toggleLogin._update then
    u._toggleLogin._update()
  end
  if u._toggleBar and u._toggleBar._update then
    u._toggleBar._update()
  end

end

function NS.PrepareQuickBarButton(btn)
  if btn._qbSkinned then
    return
  end
  btn._qbSkinned = true
  MakeBackdropFrame(btn)
  btn:SetBackdropColor(RGB(WIDGET_BG))
  btn:SetBackdropBorderColor(RGB(BORDER))
  local fs = btn:CreateFontString(nil, "OVERLAY")
  SkinFont(fs, 11)
  fs:SetPoint("CENTER", 0, 1)
  fs:SetTextColor(RGB(TEXT))
  btn:SetFontString(fs)

  btn:SetScript("OnEnter", function()
    btn:SetBackdropBorderColor(RGB(ACCENT))
    btn:SetBackdropColor(ACCENT[1] * 0.2, ACCENT[2] * 0.2, ACCENT[3] * 0.22, 1)
  end)

  btn:SetScript("OnLeave", function()
    btn:SetBackdropBorderColor(RGB(BORDER))
    btn:SetBackdropColor(RGB(WIDGET_BG))
  end)

end

local function CreateAccentButton(parent, w, h, label, accentFill)
  local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
  btn:SetSize(w, h)
  MakeBackdropFrame(btn)

  local r, g, b = accentFill and ACCENT[1] * 0.35 or WIDGET_BG[1],
    accentFill and ACCENT[2] * 0.35 or WIDGET_BG[2],
    accentFill and ACCENT[3] * 0.35 or WIDGET_BG[3]
  btn:SetBackdropColor(r, g, b, 1)
  btn:SetBackdropBorderColor(
    accentFill and ACCENT[1] * 0.55 + BORDER[1] * 0.45 or BORDER[1],
    accentFill and ACCENT[2] * 0.55 + BORDER[2] * 0.45 or BORDER[2],
    accentFill and ACCENT[3] * 0.55 + BORDER[3] * 0.45 or BORDER[3])

  local t = btn:CreateFontString(nil, "OVERLAY")
  SkinFont(t, 11)
  t:SetPoint("CENTER", 0, 0)
  t:SetTextColor(RGB(TEXT))
  btn:SetFontString(t)
  t:SetText(label)

  btn:SetScript("OnEnter", function()
    btn:SetBackdropBorderColor(RGB(ACCENT))
    if accentFill then
      btn:SetBackdropColor(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.45, 1)
    end
  end)

  btn:SetScript("OnLeave", function()
    btn:SetBackdropColor(r, g, b, 1)
    btn:SetBackdropBorderColor(
      accentFill and ACCENT[1] * 0.55 + BORDER[1] * 0.45 or BORDER[1],
      accentFill and ACCENT[2] * 0.55 + BORDER[2] * 0.45 or BORDER[2],
      accentFill and ACCENT[3] * 0.55 + BORDER[3] * 0.45 or BORDER[3])
  end)

  return btn
end

local function CreateSidebarNavBtn(idx, label, displayLabel)
  local sidebar = NS.ui.frame._sidebar
  local btn = CreateFrame("Button", nil, sidebar)
  btn:SetSize(SIDEBAR_W - 2, 34)
  btn:SetPoint("TOPLEFT", 1, -(idx - 1) * 36 - 8)

  local indicator = btn:CreateTexture(nil, "ARTWORK")
  indicator:SetWidth(3)
  indicator:SetPoint("TOPLEFT")
  indicator:SetPoint("BOTTOMLEFT")
  indicator:SetColorTexture(RGB(ACCENT))
  indicator:Hide()

  local bgHl = btn:CreateTexture(nil, "BACKGROUND")
  bgHl:SetAllPoints()
  bgHl:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.09)
  bgHl:Hide()

  local tex = btn:CreateFontString(nil, "OVERLAY")
  SkinFont(tex, 12)
  tex:SetPoint("LEFT", 14, 0)
  tex:SetTextColor(RGB(TEXT_DIM))
  tex:SetText(displayLabel or label)

  btn._indicator = indicator
  btn._bgHl = bgHl
  btn._txt = tex
  btn._navKey = label

  btn:SetScript("OnEnter", function()
    if activePage ~= label then
      bgHl:Show()
      tex:SetTextColor(RGB(TEXT))
    end
  end)
  btn:SetScript("OnLeave", function()
    if activePage ~= label then
      bgHl:Hide()
      tex:SetTextColor(RGB(TEXT_DIM))
    end
  end)

  btn:SetScript("OnClick", function()
    NS.UIShowPage(label)
  end)

  sidebarBtns[label] = btn

  return btn
end

local function SetSidebarNavActive(which)
  for key, btn in pairs(sidebarBtns) do
    local on = key == which
    if on then
      btn._indicator:Show()
      btn._bgHl:Show()
      btn._txt:SetTextColor(RGB(ACCENT))
    else
      btn._indicator:Hide()
      btn._bgHl:Hide()
      btn._txt:SetTextColor(RGB(TEXT_DIM))
    end
  end
end

local function HideCheckbox(cb)
  cb:SetAlpha(0)
  cb:SetSize(1, 1)
end

local function CreateSwitchRow(parent, width, checkbox, indentX, caption)
  HideCheckbox(checkbox)

  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(width, 32)

  local track = CreateFrame("Frame", nil, f, "BackdropTemplate")
  track:SetSize(38, 20)
  track:SetPoint("TOPLEFT", indentX or 0, -6)
  MakeBg(track, 0.17, 0.17, 0.19, 1)

  local thumb = track:CreateTexture(nil, "OVERLAY")
  thumb:SetSize(16, 16)
  thumb:SetColorTexture(RGB(ACCENT))

  local function UpdateVisual()
    local on = checkbox:GetChecked()
    if on then
      thumb:ClearAllPoints()
      thumb:SetPoint("LEFT", track, "LEFT", 20, 0)
      thumb:SetColorTexture(RGB(ACCENT))
      track:SetBackdropColor(ACCENT[1] * 0.28, ACCENT[2] * 0.28, ACCENT[3] * 0.28, 1)
    else
      thumb:ClearAllPoints()
      thumb:SetPoint("LEFT", track, "LEFT", 2, 0)
      thumb:SetColorTexture(0.45, 0.45, 0.48)
      track:SetBackdropColor(0.18, 0.18, 0.20, 1)
    end
  end

  checkbox:SetParent(f)
  checkbox:ClearAllPoints()
  checkbox:SetPoint("BOTTOMRIGHT", track, "TOPLEFT", -4000, 4000)

  track:EnableMouse(true)
  track:SetScript("OnMouseDown", function()
    checkbox:Click()
  end)

  local lbl = f:CreateFontString(nil, "OVERLAY")
  SkinFont(lbl, 12)
  lbl:SetPoint("LEFT", track, "RIGHT", 12, -1)
  lbl:SetPoint("RIGHT", f, "RIGHT", -8, -1)
  lbl:SetJustifyH("LEFT")
  lbl:SetTextColor(RGB(TEXT))
  lbl:SetText(caption)

  f._update = UpdateVisual
  UpdateVisual()

  checkbox:HookScript("OnClick", function()
    UpdateVisual()
  end)

  return f
end

local function LayoutSection(parent, caption, anchorTop, _insetW, sepYOff, leftOff)
  leftOff = leftOff or 0
  local fs = parent:CreateFontString(nil, "OVERLAY")
  SkinFont(fs, 13, "OUTLINE")
  fs:SetPoint("TOPLEFT", leftOff, anchorTop)
  fs:SetJustifyH("LEFT")
  fs:SetTextColor(RGB(TEXT))
  fs:SetText(caption)

  local line = parent:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", leftOff, anchorTop - 22)
  line:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, anchorTop - 22)
  line:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.35)

  return anchorTop - 22 - (sepYOff or 10)
end

function NS.UIShowPage(which)
  local ui = NS.ui
  if not ui.frame then
    return
  end
  activePage = which
  SetSidebarNavActive(which)
  if which == "profiles" then
    ui.optionsPage:Hide()
    ui.profilesPage:Show()
  else
    ui.profilesPage:Hide()
    ui.optionsPage:Show()
  end

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

  MakeBackdropFrame(f)
  f:SetBackdropColor(RGB(BG))
  f:SetBackdropBorderColor(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.5, 0.85)

  local glow = CreateFrame("Frame", nil, f, "BackdropTemplate")
  glow:SetPoint("TOPLEFT", -1, 1)
  glow:SetPoint("BOTTOMRIGHT", 1, -1)
  glow:SetBackdrop({ edgeFile = WHITE8, edgeSize = 2, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
  glow:SetBackdropBorderColor(ACCENT[1] * 0.28, ACCENT[2] * 0.28, ACCENT[3] * 0.28, 0.45)

  ui.frame = f

  local uipt = DB.uiPoint
  if uipt and uipt[1] then
    f:SetPoint(uipt[1], NS.ResolveRelativeFrame(uipt[2]), uipt[3] or uipt[1], uipt[4] or 0, uipt[5] or 0)
  else
    f:SetPoint("CENTER")
  end

  local titleBar = CreateFrame("Frame", nil, f)
  titleBar:SetHeight(38)
  titleBar:SetPoint("TOPLEFT")
  titleBar:SetPoint("TOPRIGHT")

  local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
  titleBg:SetAllPoints()
  titleBg:SetColorTexture(0.08, 0.08, 0.11, 1)

  local titleLine = titleBar:CreateTexture(nil, "ARTWORK")
  titleLine:SetHeight(1)
  titleLine:SetPoint("BOTTOMLEFT")
  titleLine:SetPoint("BOTTOMRIGHT")
  titleLine:SetColorTexture(ACCENT[1] * 0.5, ACCENT[2] * 0.5, ACCENT[3] * 0.45, 0.9)

  local titleStr = titleBar:CreateFontString(nil, "OVERLAY")
  SkinFont(titleStr, 15, "OUTLINE")
  titleStr:SetPoint("LEFT", titleBar, "LEFT", 14, -1)
  titleStr:SetText("|cff00ccffAudio|r|cffff9933 Profiles|r |cff909090— Settings|r")

  local verStr = titleBar:CreateFontString(nil, "OVERLAY")
  SkinFont(verStr, 10)
  verStr:SetPoint("RIGHT", -44, -1)
  verStr:SetTextColor(RGB(TEXT_DIM))
  verStr:SetText("v" .. ver)

  local closeBtn = CreateFrame("Button", nil, titleBar)
  closeBtn:SetSize(28, 28)
  closeBtn:SetPoint("RIGHT", -6, -1)

  local closeX = closeBtn:CreateFontString(nil, "OVERLAY")
  SkinFont(closeX, 17)
  closeX:SetPoint("CENTER")
  closeX:SetText("×")
  closeX:SetTextColor(0.6, 0.6, 0.62)

  closeBtn:SetScript("OnEnter", function()
    closeX:SetTextColor(1, 0.35, 0.35)
  end)

  closeBtn:SetScript("OnLeave", function()
    closeX:SetTextColor(0.6, 0.6, 0.62)
  end)

  closeBtn:SetScript("OnClick", function()
    f:Hide()
  end)

  local sidebar = CreateFrame("Frame", nil, f)
  sidebar:SetWidth(SIDEBAR_W)
  sidebar:SetPoint("TOPLEFT", 0, -38)
  sidebar:SetPoint("BOTTOMLEFT")

  local sbBg = sidebar:CreateTexture(nil, "BACKGROUND")
  sbBg:SetAllPoints()
  sbBg:SetColorTexture(RGB(SIDEBAR))

  local sbLine = sidebar:CreateTexture(nil, "ARTWORK")
  sbLine:SetWidth(1)
  sbLine:SetPoint("TOPRIGHT")
  sbLine:SetPoint("BOTTOMRIGHT")
  sbLine:SetColorTexture(RGB(BORDER))

  f._sidebar = sidebar

  local contentInnerW = WIN_W - SIDEBAR_W - 28

  local contentArea = CreateFrame("Frame", nil, f)
  contentArea:SetPoint("TOPLEFT", SIDEBAR_W + 2, -38 - 12)
  contentArea:SetPoint("BOTTOMRIGHT", -14, 16)

  local profilesPage = CreateFrame("Frame", nil, contentArea)
  profilesPage:SetAllPoints()

  ui.profilesPage = profilesPage

  local optionsPage = CreateFrame("Frame", nil, contentArea)
  optionsPage:SetAllPoints()
  ui.optionsPage = optionsPage

  sidebarBtns = {}

  CreateSidebarNavBtn(1, "profiles", "Profiles")

  CreateSidebarNavBtn(2, "options", "Options")

  local listInsetW = 166
  local scrollInteriorH = math.min(298, WIN_H - 220)
  -- Two-row toolbar so buttons stay inside the narrow list column (three in a row overflowed).
  local btnBarH = 8 + 26 + 4 + 26 + 8
  local listBgH = scrollInteriorH + btnBarH
  local btnRowPad = 8
  local btnInnerW = listInsetW - btnRowPad * 2

  local listBg = CreateFrame("Frame", nil, profilesPage, "BackdropTemplate")
  listBg:SetSize(listInsetW, listBgH)
  listBg:SetPoint("TOPLEFT")

  MakeBg(listBg, 0.08, 0.08, 0.095, 1)

  local scroll = CreateFrame("ScrollFrame", nil, listBg, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 6, -8)
  scroll:SetPoint("BOTTOMRIGHT", listBg, "BOTTOMRIGHT", -22, btnBarH)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(listInsetW - 34, 100)
  scroll:SetScrollChild(child)

  ui.listScroll = scroll
  scroll.Child = child

  ui.listBtns = {}

  local btnDel = CreateAccentButton(listBg, btnInnerW, 26, "Delete")
  btnDel:SetPoint("BOTTOMLEFT", listBg, "BOTTOMLEFT", btnRowPad, btnRowPad)

  local topGap = 4
  local topBtnW = math.floor((btnInnerW - topGap) / 2)
  local topBtnW2 = btnInnerW - topGap - topBtnW

  local btnNew = CreateAccentButton(listBg, topBtnW, 26, "New")
  btnNew:SetPoint("BOTTOMLEFT", btnDel, "TOPLEFT", 0, topGap)

  local btnDup = CreateAccentButton(listBg, topBtnW2, 26, "Copy")
  btnDup:SetPoint("BOTTOMRIGHT", btnDel, "TOPRIGHT", 0, topGap)

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

  local rightColumnX = listInsetW + 18
  local rightW = contentInnerW - rightColumnX

  local yHeader = -4
  yHeader = LayoutSection(profilesPage, "Profile", yHeader, rightW, 8, rightColumnX)

  local profileNameLbl = profilesPage:CreateFontString(nil, "OVERLAY")
  SkinFont(profileNameLbl, 11)
  profileNameLbl:SetPoint("TOPLEFT", rightColumnX, yHeader)
  profileNameLbl:SetTextColor(RGB(TEXT_DIM))
  profileNameLbl:SetText("Display name")

  local nameEdit = CreateFrame("EditBox", nil, profilesPage, "BackdropTemplate")
  nameEdit:SetSize(rightW, 24)
  nameEdit:SetPoint("TOPLEFT", rightColumnX, yHeader - 18)
  MakeBg(nameEdit, RGB(WIDGET_BG))
  nameEdit:SetAutoFocus(false)
  SkinFont(nameEdit, 12)
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

  yHeader = yHeader - 18 - 28

  yHeader = LayoutSection(profilesPage, "Volume mix", yHeader, rightW, 6, rightColumnX)

  local sliderGap = -6
  local slM, laM, rowM = MakeSliderRow(profilesPage, profilesPage, "TOPLEFT", rightColumnX, yHeader - 14, "Master volume",
    rightW)
  ui.slMaster = slM
  ui.laMaster = laM

  local slMu, laMu, rowMu = MakeSliderRow(profilesPage, rowM, "BOTTOMLEFT", 0, sliderGap, "Music", rightW)
  ui.slMusic = slMu
  ui.laMusic = laMu

  local slSx, laSx, rowSx = MakeSliderRow(profilesPage, rowMu, "BOTTOMLEFT", 0, sliderGap, "Sound effects", rightW)
  ui.slSFX = slSx
  ui.laSFX = laSx

  local slAm, laAm, rowAm = MakeSliderRow(profilesPage, rowSx, "BOTTOMLEFT", 0, sliderGap, "Ambience", rightW)
  ui.slAmb = slAm
  ui.laAmb = laAm

  local slDg, laDg, rowDg = MakeSliderRow(profilesPage, rowAm, "BOTTOMLEFT", 0, sliderGap, "Dialog", rightW)
  ui.slDlg = slDg
  ui.laDlg = laDg

  WireVolumeSlider(ui.slMaster, ui.laMaster)
  WireVolumeSlider(ui.slMusic, ui.laMusic)
  WireVolumeSlider(ui.slSFX, ui.laSFX)
  WireVolumeSlider(ui.slAmb, ui.laAmb)
  WireVolumeSlider(ui.slDlg, ui.laDlg)

  ui.cbDSP = CreateFrame("CheckButton", nil, profilesPage, "UICheckButtonTemplate")
  ui.cbDSP:SetScript("OnClick", function()
    if NS.IsUISilent() then
      return
    end
    NS.SyncSelectedFromWidgets()
    NS.ApplySnap(NS.SelectedProfile())
  end)
  ui.cbDSP:Hide()

  local dspToggleRow = CreateSwitchRow(profilesPage, rightW, ui.cbDSP, 0,
    "Gameplay sound effects (DSP)")
  dspToggleRow:SetPoint("TOPLEFT", rowDg, "BOTTOMLEFT", 0, -12)

  ui._toggleDSP = dspToggleRow

  local btnApply = CreateAccentButton(profilesPage, math.floor(rightW / 2) - 5, 32, "Apply to WoW", true)
  btnApply:SetPoint("BOTTOMRIGHT", profilesPage, "BOTTOMRIGHT", 0, 0)

  btnApply:SetScript("OnClick", function()
    NS.SyncSelectedFromWidgets()
    NS.ApplyProfileIndex(DB.selectedIndex)
  end)

  local btnCap = CreateAccentButton(profilesPage, math.floor(rightW / 2) - 5, 32, "Load from WoW")
  btnCap:SetPoint("RIGHT", btnApply, "LEFT", -10, 0)

  btnCap:SetScript("OnClick", function()
    local snap = NS.SnapFromGame()
    local p = NS.SelectedProfile()
    p.master, p.music, p.sfx, p.ambience, p.dialog, p.dsp =
      snap.master, snap.music, snap.sfx, snap.ambience, snap.dialog, snap.dsp
    NS.WidgetsFromProfile(p)
    NS.Print("Copied current WoW volumes into this profile.")
  end)

  local optIntroY = -8
  optIntroY = LayoutSection(optionsPage, "Behaviour", optIntroY, contentInnerW, 14)

  local info = optionsPage:CreateFontString(nil, "OVERLAY")
  SkinFont(info, 11)
  info:SetPoint("TOPLEFT", 4, optIntroY - 4)
  info:SetPoint("TOPRIGHT", -4, optIntroY - 4)
  info:SetJustifyH("LEFT")
  info:SetTextColor(RGB(TEXT_DIM))
  info:SetWordWrap(true)
  info:SetText("These toggles persist in your saved variables; profile volumes are edited on the Profiles tab.")

  ui.cbLogin = CreateFrame("CheckButton", nil, optionsPage, "UICheckButtonTemplate")
  ui.cbLogin:SetScript("OnClick", function()
    DB.applyOnLogin = ui.cbLogin:GetChecked()
  end)
  ui.cbLogin:Hide()

  local loginToggleRow = CreateSwitchRow(optionsPage, contentInnerW - 8, ui.cbLogin, 0,
    "Re-apply last profile after login")

  loginToggleRow:SetPoint("TOPLEFT", 4, optIntroY - 40)

  ui._toggleLogin = loginToggleRow

  ui.cbBar = CreateFrame("CheckButton", nil, optionsPage, "UICheckButtonTemplate")
  ui.cbBar:SetScript("OnClick", function()
    DB.showQuickBar = ui.cbBar:GetChecked()
    NS.RefreshQuickBar()
  end)
  ui.cbBar:Hide()

  local barToggleRow = CreateSwitchRow(optionsPage, contentInnerW - 8, ui.cbBar, 0,
    "Show draggable quick-switch bar")

  barToggleRow:SetPoint("TOPLEFT", loginToggleRow, "BOTTOMLEFT", 0, -4)

  ui._toggleBar = barToggleRow

  optionsPage:Hide()
  profilesPage:Show()
  NS.UIShowPage("profiles")

  tinsert(UISpecialFrames, f:GetName())

  local qb = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  qb:SetFrameStrata("MEDIUM")
  MakeBackdropFrame(qb)
  qb:SetBackdropColor(0.07, 0.07, 0.085, 0.92)
  qb:SetBackdropBorderColor(ACCENT[1] * 0.45, ACCENT[2] * 0.45, ACCENT[3] * 0.42, 0.9)

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
