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
local CONTENT_COL_GAP = 32
local CONTENT_LABEL_W = 122
local CONTENT_ROW_H = 30
local FOOTER_PAD = 12
local FOOTER_TOGGLE_H = 28
local FOOTER_TOGGLE_GAP = 4
local FOOTER_SECTION_GAP = 10
local FOOTER_HEADING_H = 14
local FOOTER_CONTENT_ROWS = 3
local FOOTER_CONTENT_BLOCK_H = FOOTER_PAD + FOOTER_CONTENT_ROWS * (CONTENT_ROW_H + 4)
local FOOTER_CONTENT_SECTION_H = FOOTER_CONTENT_BLOCK_H + 6 + FOOTER_TOGGLE_H + 8 + FOOTER_HEADING_H
local FOOTER_OPTIONS_SECTION_H = FOOTER_TOGGLE_H + FOOTER_TOGGLE_GAP + FOOTER_TOGGLE_H + 8 + FOOTER_HEADING_H
local FOOTER_H = FOOTER_CONTENT_SECTION_H + FOOTER_SECTION_GAP + FOOTER_OPTIONS_SECTION_H + FOOTER_PAD
local LIST_W = 184
local LIST_PAD = 18
local LIST_SCROLLBAR_W = 14
local LIST_SCROLLBAR_GAP = 8
local WIN_W = 640
local WIN_H = 760
local MIXER_BTN_H = 30
local MIXER_BTN_PAD = 12
local MIXER_NAME_BLOCK_H = 84
local MIXER_BTN_BLOCK_H = MIXER_BTN_PAD + MIXER_BTN_H + 14
local MIXER_SLIDER_GAP = 8
local MIXER_SLIDER_MIN_H = 32

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

local function TruncateText(text, maxLen)
  if not text or #text <= maxLen then
    return text or ""
  end

  return text:sub(1, maxLen - 2) .. ".."
end

local function HidePickerMenu(picker)
  if picker._menu then
    picker._menu:Hide()
  end
end

local function SetPickerLabel(picker, text)
  picker._apText:SetText(TruncateText(text, picker._apMaxChars or 18))
  picker._apValue = text
end

local function PositionPickerMenu(picker)
  local menu = picker._menu
  if not menu then
    return
  end

  menu:ClearAllPoints()
  menu:SetWidth(picker:GetWidth())
  menu:SetPoint("TOPLEFT", picker, "BOTTOMLEFT", 0, -2)
end

local function BuildPickerMenu(picker, tag, DB)
  local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  menu:SetSize(picker:GetWidth(), 10)
  menu:SetFrameStrata("FULLSCREEN_DIALOG")
  menu:SetFrameLevel(500)
  menu:Hide()
  ApplyBackdrop(menu, PANEL, BORDER)
  menu:EnableMouse(true)

  local scroll = CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", -24, 4)

  local child = CreateFrame("Frame", nil, scroll)
  child:SetWidth(picker:GetWidth() - 28)
  scroll:SetScrollChild(child)

  menu._apScroll = scroll
  menu._apChild = child
  menu._apButtons = {}

  local function RebuildMenu()
    for _, btn in ipairs(menu._apButtons) do
      btn:Hide()
    end

    local options = { { text = "(none)", index = nil } }
    for i, p in ipairs(DB.profiles) do
      options[#options + 1] = { text = p.name, index = i }
    end

    local rowH = 24
    local maxVisible = 8
    local visibleRows = math.min(#options, maxVisible)
    menu:SetHeight(visibleRows * (rowH + 2) + 8)
    child:SetHeight(#options * (rowH + 2))

    for i, opt in ipairs(options) do
      local btn = menu._apButtons[i]
      if not btn then
        btn = CreateFrame("Button", nil, child, "BackdropTemplate")
        ApplyBackdrop(btn, WIDGET_BG, BORDER)
        btn:SetHeight(rowH)

        local label = btn:CreateFontString(nil, "OVERLAY")
        ApplyFont(label, 11)
        label:SetPoint("LEFT", 8, 0)
        label:SetPoint("RIGHT", -8, 0)
        label:SetJustifyH("LEFT")
        label:SetWordWrap(false)
        btn._apLabel = label

        btn:SetScript("OnEnter", function(self)
          self:SetBackdropBorderColor(RGB(ACCENT))
          self:SetBackdropColor(ACCENT[1] * 0.18, ACCENT[2] * 0.14, ACCENT[3] * 0.06, 1)
        end)

        btn:SetScript("OnLeave", function(self)
          self:SetBackdropBorderColor(RGB(BORDER))
          self:SetBackdropColor(RGB(WIDGET_BG))
        end)

        menu._apButtons[i] = btn
      end

      btn:SetSize(child:GetWidth(), rowH)
      btn:ClearAllPoints()
      btn:SetPoint("TOPLEFT", 0, -(i - 1) * (rowH + 2))
      btn._apLabel:SetText(opt.text)
      btn:SetScript("OnClick", function()
        if opt.index then
          DB.contentBindings[tag] = opt.index
          SetPickerLabel(picker, opt.text)
        else
          DB.contentBindings[tag] = nil
          SetPickerLabel(picker, "(none)")
        end
        menu:Hide()
      end)
      btn:Show()
    end
  end

  menu.Rebuild = RebuildMenu
  picker._menu = menu

  menu:SetScript("OnHide", function()
    picker._apOpen = false
    picker:SetBackdropBorderColor(RGB(BORDER))
  end)
end

local function MakeModernPicker(parent, tag, width, DB)
  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(CONTENT_ROW_H)

  local label = row:CreateFontString(nil, "OVERLAY")
  ApplyFont(label, 11)
  label:SetPoint("LEFT", 0, 0)
  label:SetWidth(CONTENT_LABEL_W)
  label:SetJustifyH("LEFT")
  label:SetWordWrap(false)
  label:SetTextColor(RGB(TEXT_DIM))
  label:SetText(NS.CONTENT_TAG_LABELS[tag] or tag)

  local picker = CreateFrame("Button", nil, row, "BackdropTemplate")
  picker:SetSize(width, 24)
  picker:SetPoint("LEFT", label, "RIGHT", 8, 0)
  ApplyBackdrop(picker, WIDGET_BG, BORDER)
  picker._apTag = tag
  picker._apMaxChars = math.max(10, math.floor(width / 7))

  local text = picker:CreateFontString(nil, "OVERLAY")
  ApplyFont(text, 11)
  text:SetPoint("LEFT", 10, 0)
  text:SetPoint("RIGHT", -18, 0)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(false)
  text:SetTextColor(RGB(TEXT))
  picker._apText = text

  local arrow = picker:CreateFontString(nil, "OVERLAY")
  ApplyFont(arrow, 10)
  arrow:SetPoint("RIGHT", -8, 0)
  arrow:SetTextColor(RGB(TEXT_DIM))
  arrow:SetText("v")

  BuildPickerMenu(picker, tag, DB)

  picker:SetScript("OnClick", function(self)
    if NS.ui.contentPickers then
      for _, other in pairs(NS.ui.contentPickers) do
        if other ~= self then
          HidePickerMenu(other)
        end
      end
    end

    if self._apOpen then
      HidePickerMenu(self)
      return
    end

    self._menu.Rebuild()
    PositionPickerMenu(self)
    self._apOpen = true
    self:SetBackdropBorderColor(RGB(ACCENT))
    self._menu:Show()
  end)

  picker:SetScript("OnEnter", function(self)
    if not self._apOpen then
      self:SetBackdropBorderColor(RGB(TEXT_DIM))
    end
  end)

  picker:SetScript("OnLeave", function(self)
    if not self._apOpen then
      self:SetBackdropBorderColor(RGB(BORDER))
    end
  end)

  local idx = DB.contentBindings[tag]
  local initial = "(none)"
  if idx and DB.profiles[idx] then
    initial = DB.profiles[idx].name
  end
  SetPickerLabel(picker, initial)

  picker.SetValue = function(_, value)
    SetPickerLabel(picker, value)
  end

  return row, picker
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
  for _, row in ipairs({ u._toggleLogin, u._toggleBar, u._toggleContent }) do
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

  if ui.cbContent then
    ui.cbContent:SetChecked(NS.db.autoSwitchByContent)
  end

  NS.RefreshSwitchVisuals()
end

function NS.UpdateListScroll()
  local scroll = NS.ui.listScroll
  if not scroll then
    return
  end

  local child = scroll.Child
  if child then
    child:SetWidth(math.max(118, scroll:GetWidth() or 0))
  end

  scroll:UpdateScrollChildRect()
  local needsScroll = (scroll:GetVerticalScrollRange() or 0) > 0
  local scrollBar = scroll.ScrollBar

  if scrollBar then
    if needsScroll then
      scrollBar:Show()
    else
      scrollBar:Hide()
      scroll:SetVerticalScroll(0)
    end
  end
end

function NS.RefreshContentUI()
  local ui = NS.ui
  if not ui.frame then
    return
  end

  if ui.contentStatus then
    local ctx = NS.GetContentContext()
    ui.contentStatus:SetText("Now: " .. ctx.label)
  end

  if ui.contentPickers then
    local DB = NS.db
    for tag, picker in pairs(ui.contentPickers) do
      local idx = DB.contentBindings[tag]
      local label = "(none)"
      if idx and DB.profiles[idx] then
        label = DB.profiles[idx].name
      end
      picker:SetValue(label)
    end
  end

  NS.RefreshSwitchVisuals()
end

function NS.PrepareUI()
  NS.EnsureDB()
  if NS.ui.frame then
    NS.RefreshContentUI()
    return
  end

  NS.BuildUI()
  NS.RefreshList()
  NS.WidgetsFromProfile(NS.SelectedProfile())
  NS.UpdateOptionsCheckboxes()
  NS.RefreshQuickBar()
  NS.RefreshContentUI()
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

  local creditStr = titleBar:CreateFontString(nil, "OVERLAY")
  ApplyFont(creditStr, 9)
  creditStr:SetPoint("LEFT", titleStr, "RIGHT", 8, -1)
  creditStr:SetTextColor(TEXT_DIM[1], TEXT_DIM[2], TEXT_DIM[3], 0.55)
  creditStr:SetText("by Farami")

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
  local scrollRight = LIST_PAD + LIST_SCROLLBAR_W + LIST_SCROLLBAR_GAP

  local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", LIST_PAD, -28)
  scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -scrollRight, barH)

  local child = CreateFrame("Frame", nil, scroll)
  local scrollContentW = LIST_W - LIST_PAD - scrollRight
  child:SetSize(scrollContentW, 100)
  scroll:SetScrollChild(child)

  if scroll.ScrollBar then
    scroll.ScrollBar:Hide()
    scroll.ScrollBar:SetWidth(LIST_SCROLLBAR_W)
  end

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

    local deletedIndex = DB.selectedIndex
    table.remove(DB.profiles, deletedIndex)
    NS.ReindexContentBindingsAfterDelete(deletedIndex)
    DB.selectedIndex = math.min(DB.selectedIndex, #DB.profiles)
    NS.RefreshList()
    NS.ApplyProfileIndex(DB.selectedIndex, true, true)
    NS.RefreshQuickBar()
    NS.RefreshContentUI()
  end)
end

local function BuildMixerPanel(panel, DB)
  local ui = NS.ui
  local innerW = (WIN_W - 2 * PAD - LIST_W - GAP) - 28
  local mixerH = WIN_H - TITLE_H - PAD - FOOTER_H - PAD - GAP - GAP

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

  local btnW = math.floor((innerW - 10) / 2)

  local btnApply = CreateButton(panel, btnW, MIXER_BTN_H, "Apply to WoW", true)
  btnApply:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -14, MIXER_BTN_PAD)
  btnApply:SetScript("OnClick", function()
    NS.SyncSelectedFromWidgets()
    NS.ApplyProfileIndex(DB.selectedIndex)
  end)

  local btnCap = CreateButton(panel, btnW, MIXER_BTN_H, "Load from WoW")
  btnCap:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, MIXER_BTN_PAD)
  btnCap:SetScript("OnClick", function()
    local snap = NS.SnapFromGame()
    local p = NS.SelectedProfile()
    p.master, p.music, p.sfx, p.ambience, p.dialog, p.dsp =
      snap.master, snap.music, snap.sfx, snap.ambience, snap.dialog, snap.dsp
    NS.WidgetsFromProfile(p)
    NS.Print("Copied current WoW volumes into this profile.")
  end)

  local rows = {
    { key = "slMaster", caption = "Master" },
    { key = "slMusic", caption = "Music" },
    { key = "slSFX", caption = "Sound effects" },
    { key = "slAmb", caption = "Ambience" },
    { key = "slDlg", caption = "Dialog" },
  }

  local sliderAreaH = mixerH - MIXER_NAME_BLOCK_H - MIXER_BTN_BLOCK_H
  local rowH = math.max(MIXER_SLIDER_MIN_H, math.floor((sliderAreaH - MIXER_SLIDER_GAP * (#rows - 1)) / #rows))
  local rowStep = rowH + MIXER_SLIDER_GAP

  for i, row in ipairs(rows) do
    local slider, holder = MakeSliderRow(panel, row.caption)
    holder:SetHeight(rowH)
    holder:SetWidth(innerW)
    holder:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, MIXER_BTN_BLOCK_H + (i - 1) * rowStep)
    WireVolumeSlider(slider)
    ui[row.key] = slider
  end
end

local function BuildContentPanel(footer, DB)
  local ui = NS.ui
  local innerW = (WIN_W - 2 * PAD) - 28
  local colW = math.floor((innerW - CONTENT_COL_GAP) / 2)
  local pickerW = colW - CONTENT_LABEL_W - 8
  local leftX = 14
  local rightX = leftX + colW + CONTENT_COL_GAP
  local rowStep = CONTENT_ROW_H + 4

  ui.contentPickers = {}
  local contentRows = {
    { tags = { "dungeon_legacy", "raid_legacy" } },
    { tags = { "dungeon_current", "raid_current" } },
    { tags = { "world" } },
  }

  for rowIndex, rowSpec in ipairs(contentRows) do
    local bottomY = FOOTER_PAD + (rowIndex - 1) * rowStep

    for colIndex, tag in ipairs(rowSpec.tags) do
      local rowX = (colIndex == 1) and leftX or rightX
      local row, picker = MakeModernPicker(footer, tag, pickerW, DB)
      row:SetSize(colW, CONTENT_ROW_H)
      row:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", rowX, bottomY)
      ui.contentPickers[tag] = picker
    end
  end

  ui.cbContent = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
  ui.cbContent:Hide()
  ui.cbContent:SetScript("OnClick", function()
    DB.autoSwitchByContent = ui.cbContent:GetChecked()
  end)

  local contentRow = MakeToggleRow(footer, ui.cbContent, "Auto-switch by content")
  contentRow:SetWidth(innerW)
  contentRow:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", 14, FOOTER_CONTENT_BLOCK_H + 6)
  ui._toggleContent = contentRow

  local heading = MakeHeading(footer, "Content links")
  heading:SetPoint("BOTTOMLEFT", contentRow, "TOPLEFT", -2, 8)
end

local function BuildFooter(footer, DB)
  local ui = NS.ui
  local innerW = (WIN_W - 2 * PAD) - 28

  BuildContentPanel(footer, DB)

  ui.cbBar = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
  ui.cbBar:Hide()
  ui.cbBar:SetScript("OnClick", function()
    DB.showQuickBar = ui.cbBar:GetChecked()
    NS.RefreshQuickBar()
  end)

  local barRow = MakeToggleRow(footer, ui.cbBar, "Show draggable quick-switch bar")
  barRow:SetWidth(innerW)
  barRow:SetPoint("BOTTOMLEFT", footer, "BOTTOMLEFT", 14, FOOTER_CONTENT_SECTION_H + FOOTER_SECTION_GAP)
  ui._toggleBar = barRow

  ui.cbLogin = CreateFrame("CheckButton", nil, footer, "UICheckButtonTemplate")
  ui.cbLogin:Hide()
  ui.cbLogin:SetScript("OnClick", function()
    DB.applyOnLogin = ui.cbLogin:GetChecked()
  end)

  local loginRow = MakeToggleRow(footer, ui.cbLogin, "Re-apply last profile after login")
  loginRow:SetWidth(innerW)
  loginRow:SetPoint("BOTTOMLEFT", barRow, "TOPLEFT", 0, -FOOTER_TOGGLE_GAP)
  ui._toggleLogin = loginRow

  local optionsHeading = MakeHeading(footer, "Options")
  optionsHeading:SetPoint("BOTTOMLEFT", loginRow, "TOPLEFT", -2, 8)

  ui.contentStatus = footer:CreateFontString(nil, "OVERLAY")
  ApplyFont(ui.contentStatus, 11)
  ui.contentStatus:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -14, 0)
  ui.contentStatus:SetPoint("TOP", optionsHeading, "TOP", 0, 0)
  ui.contentStatus:SetTextColor(RGB(ACCENT))
  ui.contentStatus:SetJustifyH("RIGHT")
  ui.contentStatus:SetText("Now: World")
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

  f:HookScript("OnHide", function()
    if ui.contentPickers then
      for _, picker in pairs(ui.contentPickers) do
        HidePickerMenu(picker)
      end
    end
  end)

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
    NS.RefreshContentUI()
    NS.ui.frame:Show()
  end
end
