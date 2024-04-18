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

local settingsTable -- We'll be able to reference entries by their keys through the settingsTable
local scrollChild -- All frames that need to scroll have to be parented to this frame
local lastFrameTop, lastFrameLeft -- We'll need references for anchoring all the frames

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
    return value == 1 -- The first value of enums should correspond to off
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

local createDropDown = function(frameName, text, key)
  local enumTable = settingsTable[key]['dropdownEnum']

  local dropdown = LibDD:Create_UIDropDownMenu(frameName, scrollChild)
  local dropdownLabel = dropdown:CreateFontString(frameName..'Label', 'OVERLAY', 'GameFontNormalSmall')
  dropdownLabel:SetPoint('TOPLEFT', 20, 10)

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

  dropdownLabel:SetText(text)

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

  return dropdown
end

local createButton = function(frameName, text, key)
  local button = CreateFrame('Button', frameName, scrollChild, 'UIPanelButtonTemplate')
  button.Text:SetText('|cFFFFD100'..text)
  button:SetWidth(160)
  button:SetScript('OnClick', function()
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    settingsTable[key]['updateCallback']() -- Unlike other widgets, buttons don't call applyChange
  end)

  -- Nor do they need a SetValue function but they will have a dummy function assigned to keep things consistent
  button.SetValue = C.DUMMY_FUNCTION

  return button
end

local createSubsettingFrame = function(entry)
  local key = entry['entryKey']
  local entryType = entry['entryType']
  local subTitle = entry['subTitle']
  local tooltipText = entry['tooltipText']
  local subLabel = entry['subLabel']
  local offsetX = entry['offsetX']

  local frame, nextLeftAnchor

  local subOffsetX = 0
  local subOffsetY = 0

  if entryType == 'dropdown' then
    frame = createDropDown(subLabel, subTitle, key)
    nextLeftAnchor = _G[frame:GetName()..'Right']
    subOffsetX = -18
    subOffsetY = -18
  elseif entryType == 'button' then
    frame = createButton(subLabel, subTitle, key)
    nextLeftAnchor = frame
    subOffsetY = -12
  else
    frame = createCheckBox(subLabel, subTitle, key, tooltipText)
    nextLeftAnchor = frame.Text
    subOffsetY = -10
  end

  frame:SetPoint('LEFT', lastFrameLeft, 'RIGHT', offsetX + subOffsetX, 0)
  frame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, subOffsetY)

  settingsTable[key]['frame'] = frame

  return frame, nextLeftAnchor
end

local drawSeparator = function(separatorInfo, subframes)
  if separatorInfo == nil then
    return
  end
  
  local topFrame = subframes[separatorInfo['topFrame']]
  local bottomFrame = subframes[separatorInfo['bottomFrame']]

  if not topFrame or not bottomFrame then
    return
  end

  local line = scrollChild:CreateLine()
  line:SetColorTexture(0.8, 0.8, 0.8)
  line:SetThickness(1.5)
  line:SetStartPoint("TOPLEFT", topFrame, -4, -4)
  line:SetEndPoint("BOTTOMLEFT", bottomFrame, -4, 4)
end

-- Currently this handles aligning after a checkbox or a dropdown as the rowStart as a special case.
-- If we need to support more cases, this function would need to be changed into a generic function
-- which would separate elements into rows and then for each row, account for element types to correctly
-- adjust Y offsets.
local separateSubsettingsIntoRows = function(rowSize, entries, subframes)
  if rowSize == nil then
    return
  end

  local i = rowSize + 1

  while i <= #entries do
    local prevRowStart = subframes[i - rowSize]
    local rowStart = subframes[i]

    local offsetX = 0
    local offsetY = -4
    local rowOffsetY = -4

    if entries[i]['entryType'] == 'dropdown' then
      offsetX = -15
      offsetY = -16
      rowOffsetY = -19
    end

    rowStart:SetPoint('LEFT', prevRowStart, 'LEFT', offsetX, 0)
    rowStart:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, offsetY)

    local j = i + 1
    while j < i + rowSize and j <= #entries do
      subframes[j]:SetPoint('LEFT', subframes[j - rowSize], 'LEFT', 0, 0)
      subframes[j]:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, rowOffsetY)
      j = j + 1
    end

    i = i + rowSize
  end
end

local createSubsettingOptions = function(subsettings)
  if subsettings and subsettings['entries'] then
    local entries = subsettings['entries']
    local rowSize = subsettings['rowSize']
    local separator = subsettings['separator']

    local initialLeftAnchor = lastFrameLeft

    local subframes = {} -- Keep track of the frames for layout purposes
    local frame

    for i = 1, #entries do
      frame, lastFrameLeft = createSubsettingFrame(entries[i])

      subframes[#subframes + 1] = frame
    end

    separateSubsettingsIntoRows(rowSize, entries, subframes)

    drawSeparator(separator, subframes)

    lastFrameLeft = initialLeftAnchor
    lastFrameTop = frame
  end
end

local createModuleOptions = function(moduleEntry)
  local key = moduleEntry['moduleKey']
  local label = moduleEntry['label']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local subsettings = moduleEntry['subsettings']

  local moduleCheckbox = createCheckBox('UIC_Options_CB_'..label, title, key)
  moduleCheckbox:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  moduleCheckbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -10)
  moduleCheckbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])

  settingsTable[key]['frame'] = moduleCheckbox

  lastFrameLeft = moduleCheckbox

  -- Module description
  local extraTextOffsetY = -16
  for i = 1, #description do
    local descriptionText = moduleCheckbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    descriptionText:SetTextColor(1, 1, 1)
    descriptionText:SetFormattedText(description[i])
    descriptionText:SetPoint('LEFT', moduleCheckbox.Text, 'LEFT', 0, 0)
    descriptionText:SetPoint('TOP', moduleCheckbox, 'BOTTOM', 0, (i - 1) * extraTextOffsetY)
    descriptionText:SetJustifyH('LEFT')

    lastFrameTop = descriptionText
  end

  createSubsettingOptions(subsettings)
end

-- These base module cannot be toggled and only has subsettings.
local createBaseOptions = function(moduleEntry)
  local label = moduleEntry['label']
  local subsettings = moduleEntry['subsettings']

  local anchorFrame = CreateFrame('Frame', 'UIC_'..label, scrollChild)
  anchorFrame:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  anchorFrame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, 0)
  anchorFrame:SetWidth(1)
  anchorFrame:SetHeight(1)

  lastFrameLeft = anchorFrame
  lastFrameTop = anchorFrame

  createSubsettingOptions(subsettings)
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

  scrollFrame:SetPoint('TOPLEFT', infoText, 'BOTTOMLEFT', 0, 0)
  scrollFrame:SetPoint('BOTTOMRIGHT', -27, 4)
  scrollFrame:SetScrollChild(scrollChild)

  scrollChild:SetWidth(outerPanelWidth)
  scrollChild:SetHeight(1) -- Absolutely necessary

  local scrollBar = _G['UIC_Options_ScrollFrameScrollBar']
  scrollBar.texture = scrollBar:CreateTexture(scrollBar:GetName()..'_Texture', 'ARTWORK')
  scrollBar.texture:SetTexture('Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew')
  scrollBar.texture:SetAllPoints()
  scrollBar.texture:SetColorTexture(0, 0, 0, 0.35)

  lastFrameLeft = scrollChild -- Starting with the most topLeft anchoring point
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
