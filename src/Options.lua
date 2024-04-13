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

local scrollChild, cvarMap, lastFrameTop, lastFrameLeft

local subFramesSetEnable = function(subFrames, isSet)
  if subFrames then
    for i = 1, #subFrames do
      subFrames[i]:SetEnabled(isSet)

      local r, g, b, a

      if isSet then
        r, g, b, a = whiteFontColor[1], whiteFontColor[2], whiteFontColor[3], whiteFontColor[4]
      else
        r, g, b, a = disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4]
      end

      subFrames[i].Text:SetTextColor(r, g, b, a)
    end
  end
end

local applyChange = function(savedVariableName, newValue)
  local consoleVariable = cvarMap[savedVariableName] ~= nil and cvarMap[savedVariableName]['consoleVariableName'] or nil

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

  UIChanges_Profile[savedVariableName] = newValue

  if cvarMap[savedVariableName] ~= nil then
    if cvarMap[savedVariableName]['module'] then
      local module = cvarMap[savedVariableName]['module']

      if newValue then
        module:Enable()
      else
        module:Disable()
      end
    elseif cvarMap[savedVariableName]['mainModule'] ~= nil then
      local module = cvarMap[savedVariableName]['mainModule']

      module:Update(savedVariableName, newValue)
    end
  end
end

local createCheckBox = function(frameName, title, changeKey, tooltipText)
  local checkbox = CreateFrame('CheckButton', frameName, scrollChild, 'InterfaceOptionsCheckButtonTemplate')
  checkbox.Text:SetText(title)
  checkbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])
  checkbox:SetChecked(UIChanges_Profile[changeKey])
  checkbox:SetScript('OnClick', function(self, button, down)
    local newValue = self:GetChecked()

    applyChange(changeKey, newValue)

    if newValue then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end

    if cvarMap[changeKey] and cvarMap[changeKey]['subFrames'] then -- if this is not a subToggle variable
      subFramesSetEnable(cvarMap[changeKey]['subFrames'], newValue) -- Enable/disable subcomponents, if any
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

local createDropDown = function(frameName, title, changeKey, enumTable)
  local dropdown = LibDD:Create_UIDropDownMenu(frameName, scrollChild)
  local dropdownLabel = dropdown:CreateFontString(frameName..'Label', 'OVERLAY', 'GameFontNormalSmall')
  dropdownLabel:SetPoint('TOPLEFT', 20, 10)

  -- This is called each time the downArrow button is clicked
  LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, _)
    local info = LibDD:UIDropDownMenu_CreateInfo()

    local selectedIndex = UIChanges_Profile[changeKey]

    for i, enum in ipairs(enumTable) do
      local label = enum[1]

      info.text = label
      info.arg1 = changeKey
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

  dropdownLabel:SetText(title)

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

local createButton = function(frameName, title, onChange)
  local button = CreateFrame('Button', frameName, scrollChild, 'UIPanelButtonTemplate')
  button.Text:SetText('|cFFFFD100'..title)
  button:SetWidth(160)
  button:SetScript('OnClick', function()
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    onChange()
  end)

  return button
end

local createSubOptionFrame = function(
  subLeftAnchor, offsetX, localLastFrameTop, subChangeKey, subTitle, controlData, subLabel, tooltipText, overrideOffsetY
)
  local subOption, nextSubLeftAnchor
  local subOffsetX = 0
  local subOffsetY = 0

  subLabel = subLabel:gsub('%s+', '_')

  if controlData ~= nil then
    local controlType = controlData[1]
    local typeValue = controlData[2]

    if controlType == 'dropdown' then
      local enum = C[typeValue]
      subOption = createDropDown(subLabel, subTitle, subChangeKey, enum)
      nextSubLeftAnchor = _G[subOption:GetName()..'Right']
      subOffsetX = -18
      subOffsetY = -18
    elseif controlType == 'button' then
      subOption = createButton(subLabel, subTitle, typeValue)
      nextSubLeftAnchor = subOption
      subOffsetY = -12
    end
  else
    subOption = createCheckBox(subLabel, subTitle, subChangeKey, tooltipText)
    nextSubLeftAnchor = subOption.Text
    subOffsetY = overrideOffsetY and overrideOffsetY or -10
  end

  -- If we need to have a single row of mixed elements, we'd have to make adjustments here.
  -- Alternatively, the separateSubTogglesIntoRows method could become a more generic way of dealing
  -- with mixed element cases.

  subOption:SetPoint('LEFT', subLeftAnchor, 'RIGHT', offsetX + subOffsetX, 0)
  subOption:SetPoint('TOP', localLastFrameTop, 'BOTTOM', 0, subOffsetY)

  return subOption, nextSubLeftAnchor
end

local createSubToggleEntry = function(subToggleEntry, i, parentName, offsetX, subLeftAnchor, subFrames, changeKey)
  local subChangeKey = subToggleEntry[1]
  local subTitle = subToggleEntry[2]
  local changeNeedsRestart = subToggleEntry[3] == true
  local controlData = subToggleEntry[4]
  local tooltipText = subToggleEntry[5]

  local subLabel = parentName..'_'..subTitle
  local currentOffsetX = i == 1 and 0 or offsetX

  local overrideOffsetY = nil
  if (parentName == 'UIC_BT') then
    overrideOffsetY = 0
  end

  local subOption, nextSubLeftAnchor = createSubOptionFrame(subLeftAnchor, currentOffsetX, lastFrameTop,
    subChangeKey, subTitle, controlData, subLabel, tooltipText, overrideOffsetY)

  if subFrames ~= nil then
    subFrames[#subFrames + 1] = subOption
  end

  if subChangeKey then
    cvarMap[subChangeKey] = {}
    cvarMap[subChangeKey]['option'] = subOption

    -- A subToggle with this index set means that upon modification, we need the module to update
    -- so we need to separately store the module reference
    if changeNeedsRestart then
      cvarMap[subChangeKey]['mainModule'] = cvarMap[changeKey]['module']
    end
  end

  return nextSubLeftAnchor
end

local drawSeparator = function(subFrames, separatorInfo)
  if separatorInfo == nil then
    return
  end

  local topFrame = subFrames[separatorInfo[1]]
  local bottomFrame = subFrames[separatorInfo[2]]

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
local separateSubTogglesIntoRows = function(rowSize, subToggleEntries, subFrames)
  if rowSize == nil then
    return
  end

  local i = rowSize + 1

  while i <= #subToggleEntries do
    local prevRowStart = subFrames[i - rowSize]
    local rowStart = subFrames[i]

    local offsetX = 0
    local offsetY = -4
    local rowOffsetY = -4

    if subToggleEntries[i][4] ~= nil then
      local controlType = subToggleEntries[i][4][1]

      if controlType == 'dropdown' then
        offsetX = -15
        offsetY = -16
        rowOffsetY = -19
      end
    end

    rowStart:SetPoint('LEFT', prevRowStart, 'LEFT', offsetX, 0)
    rowStart:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, offsetY)

    local j = i + 1
    while j < i + rowSize and j <= #subToggleEntries do
      subFrames[j]:SetPoint('LEFT', subFrames[j - rowSize], 'LEFT', 0, 0)
      subFrames[j]:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, rowOffsetY)
      j = j + 1
    end

    i = i + rowSize
  end
end

local createModuleOptions = function(moduleInfo)
  local changeKey = moduleInfo['savedVariableName']
  local label = moduleInfo['label']
  local title = moduleInfo['title']
  local description = moduleInfo['description']
  local subToggles = moduleInfo['subToggles']

  local checkbox = createCheckBox('UIC_Options_CB_'..label, title, changeKey)
  checkbox:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  checkbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -16)

  cvarMap[changeKey] = {}
  cvarMap[changeKey]['module'] = addonTable[moduleInfo['moduleName']]
  cvarMap[changeKey]['option'] = checkbox
  cvarMap[changeKey]['consoleVariableName'] = moduleInfo['consoleVariableName']

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

  -- Module subToggles
  if subToggles then
    cvarMap[changeKey]['subFrames'] = {}

    local subToggleEntries = subToggles['entries']
    local offsetX = subToggles['offsetX']
    local subFrames = cvarMap[changeKey]['subFrames']
    local subLeftAnchor = checkbox

    for i = 1, #subToggleEntries do
      subLeftAnchor = createSubToggleEntry(subToggleEntries[i], i, checkbox:GetName(), offsetX, subLeftAnchor, subFrames, changeKey)
    end

    separateSubTogglesIntoRows(subToggles['rowSize'], subToggleEntries, subFrames)

    drawSeparator(subFrames, subToggles['separator'])

    local subToggleFrameName = subToggleEntries[#subToggleEntries][2]:gsub('%s+', '_')
    local lastAddedSubCheckboxName = checkbox:GetName()..'_'..subToggleFrameName
    lastFrameTop = _G[lastAddedSubCheckboxName]
  end
end

-- These options lack the module association of subToggles but are otherwise very similar to them.
local createBaseOptions = function()
  local anchorFrame = CreateFrame('Frame', 'UIC_BT', scrollChild)
  anchorFrame:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  anchorFrame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, 0)
  anchorFrame:SetWidth(1)
  anchorFrame:SetHeight(1)

  local offsetX = 25
  local subFrames = nil
  local changeKey = nil

  local subLeftAnchor = anchorFrame

  for i = 1, #C.BASE_TOGGLES do
    subLeftAnchor = createSubToggleEntry(C.BASE_TOGGLES[i], i, anchorFrame:GetName(), offsetX, subLeftAnchor, subFrames, changeKey)
  end

  -- This is rather simple since we only have 1 entry here so far
  local firstCheckBox = cvarMap['UIC_Toggle_Quick_Zoom']['option']
  lastFrameTop = firstCheckBox
  lastFrameLeft = firstCheckBox
end

local populateOptions = function(parentFrame)
  local outerPanelWidth = _G['InterfaceOptionsFramePanelContainer']:GetWidth() - 20

  -- Header text
  local headerText = parentFrame:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', parentFrame, 12, -16)

  -- Informational text
  local infoText = parentFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  infoText:SetWidth(outerPanelWidth)
  infoText:SetJustifyH('LEFT')
  infoText:SetSpacing(2)
  infoText:SetText(L.OPTIONS_INFO)
  infoText:SetPoint('TOPLEFT', headerText, 7, -24)

  -- All the options will be within a scrollFrame
  local scrollFrame = CreateFrame('ScrollFrame', 'UIC_Options_ScrollFrame', parentFrame, 'UIPanelScrollFrameTemplate')
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

  lastFrameTop = scrollChild
  lastFrameLeft = scrollChild

  createBaseOptions()

  for _, moduleInfo in ipairs(C.MODULES) do
    createModuleOptions(moduleInfo)
  end
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  cvarMap = {}

  local optionsPanel = CreateFrame('Frame', 'UIC_Options', _G['InterfaceOptionsFramePanelContainer'].NineSlice)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for cvar, frames in pairs(cvarMap) do -- read the current values and set the options
      local isSet = UIChanges_Profile[cvar]
      frames['option']:SetValue(isSet)

      if frames['subFrames'] then -- Enable/Disable subframes
        subFramesSetEnable(frames['subFrames'], isSet)
      end
    end
  end)

  populateOptions(optionsPanel)

  InterfaceOptions_AddCategory(optionsPanel)
end

addonTable.UIC_Options = UIC_Options
