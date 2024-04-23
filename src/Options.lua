--[[
UIChanges

Copyright (C) 2019 - 2024 Melik Noyan Baykal

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

local LibDD = LibStub:GetLibrary('LibUIDropDownMenu-4.0')

local _, addonTable = ...

local L = addonTable.L
local C = addonTable.C

local gameFontColor = {} -- Yellow. Module checkboxes will override checkbox text color.
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local disabledFontColor = {} -- Gray. This is used for disabled options
disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4] = _G['GameFontDisable']:GetTextColor()

local whiteFontColor = {1, 1, 1, gameFontColor[4]}

local BUTTON_WIDTH = 135

local settingsTable -- We'll be able to reference entries by their keys through the settingsTable
local scrollChild -- All frames that need to scroll have to be parented to this frame
local lastFrameTop -- A rolling reference to the frame that upcoming frames should be vertically anchored to

local setFrameState = function(frame, isSet)
  frame:SetEnabled(isSet)

  local r, g, b, a

  if isSet then
    r, g, b, a = whiteFontColor[1], whiteFontColor[2], whiteFontColor[3], whiteFontColor[4]
  else
    r, g, b, a = disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4]
  end

  frame.Text:SetTextColor(r, g, b, a)
end

-- To handle non-boolean subsetting values
local isValueTruthy = function(value)
  if type(value) == 'number' then
    return value == 1 -- The first value of enums should correspond to off or the default value
  end

  return value
end

-- This supports module & subsetting entries.
local subframesSetEnable = function(entry, value)
  local isSet = isValueTruthy(value)

  if entry.subsettings and entry.subsettings.entries then -- Subsetttings
    local dependees = {}

    for _, subEntry in ipairs(entry.subsettings.entries) do
      local subKey = subEntry['entryKey']
      local frame = settingsTable[subKey]['frame']

      setFrameState(frame, isSet)

      -- If a module is active but this subsetting is disabled, it's dependents should be disabled
      local isSubsettingEnabled = isValueTruthy(UIChanges_Profile[subKey])

      if isSet and not isSubsettingEnabled and subEntry['dependents'] then
        dependees[#dependees + 1] = subEntry
      end
    end

    -- A second pass is needed for dependent subsettings whose dependees are not enabled
    for _, subEntry in ipairs(dependees) do
      for _, dependentKey in ipairs(subEntry['dependents']) do
        local frame = settingsTable[dependentKey]['frame']

        setFrameState(frame, false)
      end
    end
  end

  if entry.dependents then -- Dependents
    for _, subKey in ipairs(entry.dependents) do
      local frame = settingsTable[subKey]['frame']
      
      setFrameState(frame, isSet)
    end
  end
end

local applyChange = function(key, newValue)
  local entry = settingsTable[key]

  local consoleVariable = entry['consoleVariableName']

  if consoleVariable then
    local success = false

    if not InCombatLockdown() then
      success = SetCVar(consoleVariable, newValue)
    end

    if not success then
      DEFAULT_CHAT_FRAME:AddMessage(L.CANT_CHANGE_IN_COMBAT, 1, 0.3, 0.3)
      return
    else
      DEFAULT_CHAT_FRAME:AddMessage(L.CVAR_CHANGED, 1, 0.501, 0)
    end
  end

  UIChanges_Profile[key] = newValue

  if entry['updateCallback'] then
    entry['updateCallback'](newValue)
  end

  subframesSetEnable(entry, newValue) -- Enable/Disable subframes
end

-- The sound files refer to checkbox but the frame type is actually CheckButton
local createCheckBox = function(frameName, text, key, tooltipText)
  local checkbox = CreateFrame('CheckButton', frameName, scrollChild, 'InterfaceOptionsCheckButtonTemplate')
  checkbox.Text:SetText(text)
  checkbox:SetChecked(UIChanges_Profile[key])
  checkbox:SetScript('OnClick', function(self, button, down)
    local newValue = self:GetChecked()

    applyChange(key, newValue)

    if newValue then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end
  end)

  checkbox['SetValue'] = function(self, newValue)
    checkbox:SetChecked(newValue)
  end

  if tooltipText then
    checkbox.tooltipText = tooltipText
  end

  return checkbox
end

local createDropDown = function(frameName, text, key, tooltipText)
  local enumTable = settingsTable[key]['dropdownEnum']

  local dropdown = LibDD:Create_UIDropDownMenu(frameName, scrollChild)

  -- The dropdown doesn't have a title so we'll add one ourselves.
  dropdown.label = dropdown:CreateFontString(frameName..'Label', 'OVERLAY', 'GameFontNormalSmall')
  dropdown.label:SetPoint('TOPLEFT', 20, 10)
  dropdown.label:SetText(text)

  -- This is called each time the downArrow button is clicked
  LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, _)
    local info = LibDD:UIDropDownMenu_CreateInfo()

    local selectedIndex = UIChanges_Profile[key]

    for i, enum in ipairs(enumTable) do
      local label = enum[1]

      info.text = label
      info.arg1 = key
      info.arg2 = i

      if i == selectedIndex then
        info.checked = true
      else
        info.checked = false
      end

      info.func = function(self, arg1, arg2)
        LibDD:UIDropDownMenu_SetText(dropdown, label)
        self.checked = true

        applyChange(arg1, arg2)
      end

      LibDD:UIDropDownMenu_AddButton(info)
    end
  end)

  -- Define functions for parity with the default frame types
  dropdown['SetValue'] = function(self, newValue)
    local newLabel = enumTable[newValue][1]
    LibDD:UIDropDownMenu_SetText(dropdown, newLabel)
  end

  dropdown['SetEnabled'] = function(self, isSet)
    if isSet then
      LibDD:UIDropDownMenu_EnableDropDown(dropdown)
    else
      LibDD:UIDropDownMenu_DisableDropDown(dropdown)
    end
  end

  dropdown['IsEnabled'] = function(self)
    if not self.dropDown then
      return false
    end

    return UIDropDownMenu_IsEnabled()
  end

  -- The frame structure of the LibUIDropDownMenu is rather complicated due to how the element is composed
  -- of 3 pieces and the outer pieces have larger-than-visible sizes to make the side textures fit.
  -- The situation creates an offset when trying to set the width of the dropdown and makes the size
  -- related queries return unexpected results.
  -- We'll do some setup here to have the dropdowns be the same width as the buttons and override the GetSize
  -- function of the dropdown frame so it returns values matching what is visible.
  local dropdownSizeOffset = math.ceil(BUTTON_WIDTH * 0.133) -- Magic number to account for the offset

  LibDD:UIDropDownMenu_SetWidth(dropdown, BUTTON_WIDTH - dropdownSizeOffset)
  
  dropdown.DefaultGetSize = dropdown.GetSize -- We'll hold on to the original function

  dropdown['GetSize'] = function(self)
    local middleWidth = math.ceil(dropdown.Middle:GetWidth())
    -- Roughly a third of the side frames' width is occupied by the visible textures, so we use another magic number.
    local sideWidth = math.ceil((dropdown.Left:GetWidth() + dropdown.Right:GetWidth()) / 3)

    local visibleWidth = middleWidth + sideWidth

    local _, height = dropdown:DefaultGetSize()
    local visibleHeight = math.ceil(height + dropdown.label:GetStringHeight())

    return visibleWidth, visibleHeight
  end

  return dropdown
end

local createButton = function(frameName, text, key, tooltipText)
  local button = CreateFrame('Button', frameName, scrollChild, 'UIPanelButtonTemplate')
  button.Text:SetText('|cFFFFD100'..text)
  button.Text:SetTextScale(0.9)
  button:SetWidth(BUTTON_WIDTH)
  button:SetScript('OnClick', function()
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    settingsTable[key]['updateCallback']() -- Unlike other widgets, buttons don't call applyChange
  end)

  -- Buttons don't need a SetValue function but they will have a dummy function assigned to keep things consistent
  button.SetValue = C.DUMMY_FUNCTION

  return button
end

local drawSeparator = function(entries, separatorInfo)
  if separatorInfo == nil then
    return
  end

  local topFrame = entries[separatorInfo['topFrame']]['frame']
  local bottomFrame = entries[separatorInfo['bottomFrame']]['frame']

  if not topFrame or not bottomFrame then
    return
  end

  local line = scrollChild:CreateLine()
  line:SetColorTexture(0.8, 0.8, 0.8)
  line:SetThickness(1.5)
  line:SetStartPoint('TOPLEFT', topFrame, -12, -4)
  line:SetEndPoint('BOTTOMLEFT', bottomFrame, -12, 4)
end

local determineOffsetY = function(frame, columnIndex, leftAnchorFrame)
  if columnIndex <= 1 or leftAnchorFrame == nil or frame.entryType == 'dropdown' then
    return 0
  end

  -- The leftAnchorFrame could be a dropdown or another type of frame that is left anchored to one
  return leftAnchorFrame.adjustmentY or 0
end

local determineOffsetX = function(frame, columnIndex, groupOffsetX)
  local offsetX = 0

  if columnIndex == 1 then
    if frame.entryType == 'dropdown' then
      offsetX = frame.subOffsetX
    end
  else
    offsetX = groupOffsetX + frame.subOffsetX
  end

  return offsetX
end

local findWidestFrameInColumn = function(entries, initialLeftAnchor, rowSize, columnIndex)
  if columnIndex < 1 then
    return initialLeftAnchor
  end

  local i = columnIndex
  local maxWidth = 0
  local widestFrame = nil

  while i <= #entries do
    local frame = entries[i]['frame']

    -- Getting the width of a dropdown is not straightforward but the button are sized to roughly
    -- match the dropdowns so we'll use the hardcoded button width for buttons and dropdowns
    local width = BUTTON_WIDTH

    if frame.entryType == 'checkbox' then
      width = frame:GetSize() + frame.Text:GetStringWidth()
    end

    if width > maxWidth then
      maxWidth = width
      widestFrame = frame
    end

    i = i + rowSize
  end
  
  return widestFrame
end

-- Set the horizontal anchors per column
local anchorSubsettingsToLeft = function(entries, initialLeftAnchor, rowSize, groupOffsetX)
  local entryIndex

  for columnIndex = 1, rowSize do
    local leftAnchorFrame = findWidestFrameInColumn(entries, initialLeftAnchor, rowSize, columnIndex - 1)

    entryIndex = columnIndex

    while entryIndex <= #entries do
      local frame = entries[entryIndex]['frame']
      local previousFrame = entryIndex > 1 and entries[entryIndex - 1].frame or nil
      -- Need to watch for this reference when left anchoring to our own subsetting frames. Don't change the
      -- reference for other frames though.
      local leftAnchor = leftAnchorFrame.nextLeftAnchor or leftAnchorFrame

      local offsetX = determineOffsetX(frame, columnIndex, groupOffsetX)
      local offsetY = determineOffsetY(frame, columnIndex, previousFrame)

      frame:SetPoint('LEFT', leftAnchor, 'RIGHT', currentOffsetX, 0)
      if offsetY ~= 0 then
        frame:AdjustPointsOffset(0, offsetY)
        frame.adjustmentY = offsetY -- Need to propagate the Y adjustment
      end

      entryIndex = entryIndex + rowSize
    end
  end
end

local findTallestFrameInRow = function(entries, rowSize, rowIndex)
  if rowIndex < 1 then
    return lastFrameTop
  end

  local entryIndex = 1 + ((rowIndex - 1) * rowSize)
  local maxHeight = 0
  local tallestFrame = nil

  for j = 1, rowSize do
    if entryIndex > #entries then
      break
    end

    local frame = entries[entryIndex]['frame']

    local _, height = frame:GetSize()

    -- Getting the height of a dropdown is not straightforward so we'll go off of the label
    -- height + the value used in LibUIDropDown + apporoximation of the padding
    if frame.entryType == 'dropdown' then
      height = frame.label:GetStringHeight() + 22
    end

    if height > maxHeight then
      maxHeight = height
      tallestFrame = frame
    end

    entryIndex = entryIndex + 1
  end

  return tallestFrame
end

-- Set the vertical anchors per row
local anchorSubsettingsToTop = function(entries, rowSize)
  local rowCount = math.ceil(#entries / rowSize)
  local entryIndex = 1

  for rowIndex = 1, rowCount do
    local topAnchor = findTallestFrameInRow(entries, rowSize, rowIndex - 1)

    for j = 1, rowSize do
      if entryIndex > #entries then
        return
      end

      local frame = entries[entryIndex]['frame']

      frame:SetPoint('TOP', topAnchor, 'BOTTOM', 0, frame.subOffsetY)

      entryIndex = entryIndex + 1
    end
  end
end

local createSubsettingFrame = function(entry)
  local key = entry['entryKey']
  local entryType = entry['entryType']
  local subTitle = entry['subTitle']
  local tooltipText = entry['tooltipText']
  local subLabel = entry['subLabel']

  local frame

  -- Each entry type needs different offsets for fine tuning and each entry type has a different part that
  -- should be used as a left anchor by nearby frames
  if entryType == 'dropdown' then
    frame = createDropDown(subLabel, subTitle, key, tooltipText)
    frame.nextLeftAnchor = _G[frame:GetName()..'Right']
    frame.subOffsetX = -16
    frame.subOffsetY = -18

    -- Dropdowns have a different height than other elements. This attribute will flag that any non-dropdown
    -- elements anchoring to this one from the right need to adjust their Y offset.
    local labelHeight = math.floor(frame.label:GetStringHeight())
    frame.adjustmentY = (-1 * labelHeight) + 1
  elseif entryType == 'button' then
    frame = createButton(subLabel, subTitle, key, tooltipText)
    frame.nextLeftAnchor = frame
    frame.subOffsetX = 1
    frame.subOffsetY = -12
  else
    frame = createCheckBox(subLabel, subTitle, key, tooltipText)
    frame.nextLeftAnchor = frame.Text
    frame.subOffsetX = 0
    frame.subOffsetY = -10

    -- Subsetting checkboxes should not become wider than buttons or dropdowns
    local maxTextWidth = BUTTON_WIDTH - (frame:GetWidth() + 6)
    
    frame.Text:SetWidth(maxTextWidth)
    frame.Text:SetNonSpaceWrap(true)
    frame.Text:SetWordWrap(true)
    frame.Text:SetMaxLines(3)
  end

  frame.entryType = entryType

  settingsTable[key]['frame'] = frame
end

-- Different entry types have different sizes but we would like to have a consistent grid of elements.
-- To achieve this goal we first initialize all frames without anchoring them and then anchor all frames
-- per row and column. The module definitons have the fine tuning parameters.
local createSubsettingOptions = function(initialLeftAnchor, subsettings)
  if subsettings and subsettings['entries'] then
    local entries = subsettings['entries']
    local offsetX = subsettings['offsetX'] or 20
    local rowSize = subsettings['rowSize'] or math.min(4, #entries)
    local separator = subsettings['separator']

    for i = 1, #entries do
      createSubsettingFrame(entries[i])
    end

    anchorSubsettingsToTop(entries, rowSize)
    anchorSubsettingsToLeft(entries, initialLeftAnchor, rowSize, offsetX)

    drawSeparator(entries, separator)

    lastFrameTop = entries[#entries]['frame']
  end
end

local createModuleOptions = function(moduleEntry)
  local key = moduleEntry['moduleKey']
  local label = moduleEntry['label']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local subsettings = moduleEntry['subsettings']

  -- If the base options are missing and this will be the first entry
  local isFirstEntry = lastFrameTop:GetName() and lastFrameTop:GetName():match('ScrollFrame') ~= nil
  local offsetY = isFirstEntry and 0 or -12

  local moduleCheckbox = createCheckBox('UIC_Options_CB_'..label, title, key)
  moduleCheckbox:SetPoint('LEFT', scrollChild, 'LEFT', 0, 0)
  moduleCheckbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, offsetY)
  moduleCheckbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])

  settingsTable[key]['frame'] = moduleCheckbox

  -- Module description
  local textWidth = scrollChild:GetWidth() - math.floor(moduleCheckbox:GetSize())
  local extraTextOffsetY = -16

  for i = 1, #description do
    local descriptionText = moduleCheckbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    descriptionText:SetTextColor(1, 1, 1)
    descriptionText:SetFormattedText(description[i])
    descriptionText:SetPoint('LEFT', moduleCheckbox.Text, 'LEFT', 0, 0)
    descriptionText:SetPoint('TOP', moduleCheckbox, 'BOTTOM', 0, (i - 1) * extraTextOffsetY)
    descriptionText:SetJustifyH('LEFT')
    descriptionText:SetWidth(textWidth)

    lastFrameTop = descriptionText
  end

  createSubsettingOptions(moduleCheckbox, subsettings)
end

-- These base module cannot be toggled and only has subsettings.
local createBaseOptions = function(moduleEntry)
  local label = moduleEntry['label']
  local subsettings = moduleEntry['subsettings']

  local anchorFrame = CreateFrame('Frame', 'UIC_'..label, scrollChild)
  anchorFrame:SetPoint('LEFT', scrollChild, 'LEFT', 0, 0)
  anchorFrame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, 10) -- There is already a gap above us, shorten it a bit
  anchorFrame:SetWidth(1)
  anchorFrame:SetHeight(1)

  lastFrameTop = anchorFrame

  createSubsettingOptions(anchorFrame, subsettings)
end

local setupOptionsPanel = function()
  local optionsPanel = CreateFrame('Frame', 'UIC_Options', _G['InterfaceOptionsFramePanelContainer'].NineSlice)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for _, moduleEntry in ipairs(C.MODULES) do
      local moduleKey = moduleEntry['moduleKey']

      if moduleKey then
        local isModuleEnabled = UIChanges_Profile[moduleKey]

        moduleEntry['frame']:SetValue(isModuleEnabled)

        -- This makes the subsettings display the correct information
        if moduleEntry.subsettings and moduleEntry.subsettings.entries then
          for _, subEntry in ipairs(moduleEntry['subsettings']['entries']) do
            local subKey = subEntry['entryKey']
            local currentValue = UIChanges_Profile[subKey]

            subEntry['frame']:SetValue(currentValue)
          end
        end

        subframesSetEnable(moduleEntry, isModuleEnabled) -- This sets whether the subsettings are accepting user input
      end
    end
  end)

  local outerPanelWidth = _G['InterfaceOptionsFramePanelContainer']:GetWidth() - 20

  -- Header text
  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 12, -16)

  -- Informational text
  local infoText = optionsPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  infoText:SetWidth(outerPanelWidth)
  infoText:SetJustifyH('LEFT')
  infoText:SetSpacing(2)
  infoText:SetText(L.OPTIONS_INFO)
  infoText:SetPoint('TOPLEFT', headerText, 7, -24)

  -- All the options will be within a scrollFrame
  local scrollFrame = CreateFrame('ScrollFrame', 'UIC_Options_ScrollFrame', optionsPanel, 'UIPanelScrollFrameTemplate')
  scrollChild = CreateFrame('Frame', 'UIC_Options_ScrollFrameChild', scrollFrame) -- This frame will be the one scrolling

  scrollFrame:SetPoint('TOPLEFT', infoText, 'BOTTOMLEFT', 0, -14) -- Y offset is needed so the scrolling elements won't touch the infoText
  scrollFrame:SetPoint('BOTTOMRIGHT', -27, 4)
  scrollFrame:SetScrollChild(scrollChild)

  scrollChild:SetWidth(outerPanelWidth)
  scrollChild:SetHeight(1) -- Absolutely necessary

  local scrollBar = _G['UIC_Options_ScrollFrameScrollBar']
  scrollBar.texture = scrollBar:CreateTexture(scrollBar:GetName()..'_Texture', 'ARTWORK')
  scrollBar.texture:SetTexture('Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew')
  scrollBar.texture:SetAllPoints()
  scrollBar.texture:SetColorTexture(0, 0, 0, 0.35)

  lastFrameTop = scrollChild

  return optionsPanel
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  settingsTable = C.SETTINGS_TABLE

  local optionsPanel = setupOptionsPanel()

  for _, moduleEntry in ipairs(C.MODULES) do
    if moduleEntry['moduleKey'] then
      createModuleOptions(moduleEntry)
    else
      createBaseOptions(moduleEntry)
    end
  end

  InterfaceOptions_AddCategory(optionsPanel)
end

addonTable.UIC_Options = UIC_Options
