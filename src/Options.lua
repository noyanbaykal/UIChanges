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

local gameFontColor = {} -- Yellow. This will override checkbox texts
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local disabledFontColor = {} -- Gray. This is used for disabled options
disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4] = _G['GameFontDisable']:GetTextColor()

local whiteFontColor = {1, 1, 1, gameFontColor[4]}

local settingsTable, scrollChild, lastFrameTop, lastFrameLeft

local subFramesSetEnable = function(dependents, isSet)
  -- Supporting subFrames only for boolean checkboxes for now
  if dependents and type(isSet) == 'boolean' then
    for _, key in ipairs(dependents) do
      local frame = settingsTable[key]['frame']

      frame:SetEnabled(isSet)

      local r, g, b, a

      if isSet then
        r, g, b, a = whiteFontColor[1], whiteFontColor[2], whiteFontColor[3], whiteFontColor[4]
      else
        r, g, b, a = disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4]
      end

      frame.Text:SetTextColor(r, g, b, a)
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
    entry['updateCallback']()
  end

  subFramesSetEnable(entry['dependents'], newValue) -- Enable/Disable subframes
end

local createCheckBox = function(frameName, text, key, tooltipText)
  local checkbox = CreateFrame('CheckButton', frameName, scrollChild, 'InterfaceOptionsCheckButtonTemplate')
  checkbox.Text:SetText(text)
  checkbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])
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
  button.SetValue = function() end

  return button
end

local createSubsettingFrame = function(entry, parentName, offsetX, subLeftAnchor, overrideOffsetY)
  local key = entry['entryKey']
  local entryType = entry['entryType']
  local subTitle = entry['subTitle']
  local tooltipText = entry['tooltipText']

  local frame, nextSubLeftAnchor
  local subOffsetX = 0
  local subOffsetY = 0

  local subLabel = parentName..'_'..subTitle
  subLabel = subLabel:gsub('%s+', '_') -- Remove any trailing whitespaces just in case

  if entryType == 'dropdown' then
    frame = createDropDown(subLabel, subTitle, key)
    nextSubLeftAnchor = _G[frame:GetName()..'Right']
    subOffsetX = -18
    subOffsetY = -18
  elseif entryType == 'button' then
    frame = createButton(subLabel, subTitle, key)
    nextSubLeftAnchor = frame
    subOffsetY = -12
  else
    frame = createCheckBox(subLabel, subTitle, key, tooltipText)
    nextSubLeftAnchor = frame.Text
    subOffsetY = overrideOffsetY and overrideOffsetY or -10
  end

  -- If we need to have a single row of mixed elements, we'd have to make adjustments here.
  -- Alternatively, the separateSubsettingsIntoRows method could become a more generic way of dealing
  -- with mixed element cases.

  frame:SetPoint('LEFT', subLeftAnchor, 'RIGHT', offsetX + subOffsetX, 0)
  frame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, subOffsetY)

  settingsTable[key]['frame'] = frame

  return frame, nextSubLeftAnchor
end

local createSubsetting = function(entry, i, parentName, offsetX, subLeftAnchor, subFrames)
  local currentOffsetX = i == 1 and 0 or offsetX

  local overrideOffsetY = nil
  if (parentName == 'UIC_BO') then -- Hardcoded override for baseOptions
    overrideOffsetY = 0
  end

  local frame, nextSubLeftAnchor = createSubsettingFrame(entry, parentName, currentOffsetX, subLeftAnchor, overrideOffsetY)
  
  subFrames[#subFrames + 1] = frame

  return nextSubLeftAnchor
end

local drawSeparator = function(subFrames, separatorInfo)
  if separatorInfo == nil then
    return
  end
  
  local topFrame = subFrames[separatorInfo['topFrame']]
  local bottomFrame = subFrames[separatorInfo['bottomFrame']]

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
local separateSubsettingsIntoRows = function(rowSize, entries, subFrames)
  if rowSize == nil then
    return
  end

  local i = rowSize + 1

  while i <= #entries do
    local prevRowStart = subFrames[i - rowSize]
    local rowStart = subFrames[i]

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
      subFrames[j]:SetPoint('LEFT', subFrames[j - rowSize], 'LEFT', 0, 0)
      subFrames[j]:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, rowOffsetY)
      j = j + 1
    end

    i = i + rowSize
  end
end

local createSubsettingOptions = function(subsettings)
  if subsettings and subsettings['entries'] then
    local entries = subsettings['entries']
    local offsetX = subsettings['offsetX']
    local rowSize = subsettings['rowSize']
    local separator = subsettings['separator']

    local subLeftAnchor = checkbox -- At this point this is referring to the module option checkbox

    local subFrames = {} -- Need to keep track of siblings for the layout

    for i = 1, #entries do
      subLeftAnchor = createSubsetting(entries[i], i, checkbox:GetName(), offsetX, subLeftAnchor, subFrames)
    end

    separateSubsettingsIntoRows(rowSize, entries, subFrames)

    drawSeparator(subFrames, separator)

    local subsettingFrameName = entries[#entries]['subTitle']:gsub('%s+', '_') -- Remove any trailing whitespaces just in case
    local lastAddedSubCheckboxName = checkbox:GetName()..'_'..subsettingFrameName
    lastFrameTop = _G[lastAddedSubCheckboxName]
  end
end

local createModuleOptions = function(moduleEntry)
  local key = moduleEntry['moduleKey']
  local label = moduleEntry['label']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local subsettings = moduleEntry['subsettings']

  local checkbox = createCheckBox('UIC_Options_CB_'..label, title, key)
  checkbox:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  checkbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -16)

  settingsTable[key]['frame'] = checkbox

  -- Module description
  local extraTextOffsetY = -16
  for i = 1, #description do
    local descriptionText = checkbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    descriptionText:SetTextColor(1, 1, 1)
    descriptionText:SetFormattedText(description[i])
    descriptionText:SetPoint('LEFT', checkbox.Text, 'LEFT', 0, 0)
    descriptionText:SetPoint('TOP', checkbox, 'BOTTOM', 0, (i - 1) * extraTextOffsetY)
    descriptionText:SetJustifyH('LEFT')

    lastFrameTop = descriptionText
  end

  -- Module subsettings
  createSubsettingOptions(subsettings)
end

-- These options lack the module association of subsettings but are otherwise very similar to them.
local createBaseOptions = function()
  local anchorFrame = CreateFrame('Frame', 'UIC_BO', scrollChild)
  anchorFrame:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  anchorFrame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, 0)
  anchorFrame:SetWidth(1)
  anchorFrame:SetHeight(1)

  local offsetX = 25

  local subLeftAnchor = anchorFrame

  local subFrames = {} -- Need to keep track of siblings for the layout

  for i = 1, #C.BASE_SETTINGS do
    subLeftAnchor = createSubsetting(C.BASE_SETTINGS[i], i, anchorFrame:GetName(), offsetX, subLeftAnchor, subFrames)
  end

  local firstCheckBox = settingsTable[C.BASE_SETTINGS[1]['entryKey']]['frame']
  lastFrameTop = firstCheckBox
  lastFrameLeft = firstCheckBox
end

local setupOptionsPanel = function()
  local optionsPanel = CreateFrame('Frame', 'UIC_Options', _G['InterfaceOptionsFramePanelContainer'].NineSlice)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for key, entry in pairs(settingsTable) do -- Read the current values and set the options
      local currentValue = UIChanges_Profile[key]

      entry['frame']:SetValue(currentValue)

      subFramesSetEnable(entry['dependents'], currentValue) -- Enable/Disable subframes
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

  scrollFrame:SetPoint('TOPLEFT', infoText, 'BOTTOMLEFT', 0, -20)
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

local buildSettingsTable = function()
  local table = {}

  for i = 1, #C.BASE_SETTINGS do
    local key = C.BASE_SETTINGS[i]['entryKey']

    table[key] = C.BASE_SETTINGS[i]
  end

  for _, moduleEntry in ipairs(C.MODULES) do
    local key = moduleEntry['moduleKey']

    table[key] = moduleEntry

    if moduleEntry['subsettings'] and moduleEntry['subsettings']['entries'] then
      local subsettings = moduleEntry['subsettings']['entries']

      for i = 1, #subsettings do
        local subKey = subsettings[i]['entryKey']
    
        table[subKey] = subsettings[i]
      end
    end
  end

  return table
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  settingsTable = buildSettingsTable()

  local optionsPanel = setupOptionsPanel()

  createBaseOptions()

  for _, moduleEntry in ipairs(C.MODULES) do
    createModuleOptions(moduleEntry)
  end

  InterfaceOptions_AddCategory(optionsPanel)
end

addonTable.UIC_Options = UIC_Options
