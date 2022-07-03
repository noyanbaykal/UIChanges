--[[
UIChanges

Copyright (C) 2019 - 2022 Melik Noyan Baykal

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

local C = UI_CHANGES_CONSTANTS
local L = UI_CHANGES_LOCALE

local gameFontColor = {} -- Yellow. This will override checkbox texts
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local disabledFontColor = {} -- Gray. This is used for disabled options
disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4] = _G['GameFontDisable']:GetTextColor()

local whiteFontColor = {1, 1, 1, gameFontColor[4]}

local optionsPanel, changes, cvarMap, lastFrameTop, lastFrameLeft

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

local createCheckBox = function(frameName, title, changeKey)
  local checkbox = CreateFrame('CheckButton', frameName, optionsPanel, 'InterfaceOptionsCheckButtonTemplate')
  checkbox.Text:SetText(title)
  checkbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])
  checkbox:SetChecked(_G[changeKey])
  checkbox:SetScript('OnClick', function(self, button, down)
    local newValue = self:GetChecked()

    changes[changeKey] = {_G[changeKey], newValue}

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

  return checkbox
end

local createDropDown = function(frameName, title, changeKey, enumTable, onChange)
  local selectedIndex = _G[changeKey]

  local dropdown = CreateFrame('Frame', frameName, optionsPanel, 'UIDropDownMenuTemplate')
  local dropdownLabel = dropdown:CreateFontString(dropdown, 'OVERLAY', 'GameFontNormalSmall')
  dropdownLabel:SetPoint("TOPLEFT", 20, 10)

  -- This is called each time the downArrow button is clicked
  UIDropDownMenu_Initialize(dropdown, function(self, level, _)
    local info = UIDropDownMenu_CreateInfo()

    for i, enum in ipairs(enumTable) do
      local label = enum[1]
      local value = enum[2]

      info.text = label
      info.arg1 = changeKey
      info.arg2 = i

      if i == selectedIndex then
        info.checked = true
        UIDropDownMenu_SetText(dropdown, label)
      else
        info.checked = false
      end

      info.func = function(self, arg1, arg2)
        UIDropDownMenu_SetText(dropdown, label)
        self.checked = true

        changes[arg1] = {_G[arg1], arg2}
      end

      UIDropDownMenu_AddButton(info)
    end
  end)

  dropdownLabel:SetText(title)

  dropdown['SetValue'] = function(self, newValue)
    local newLabel = enumTable[newValue][1]
    UIDropDownMenu_SetText(dropdown, newLabel)
  end

  dropdown['SetEnabled'] = function(self, isSet)
    if isSet then
      UIDropDownMenu_EnableDropDown(dropdown)
    else
      UIDropDownMenu_DisableDropDown(dropdown)
    end
  end

  return dropdown
end

local createSubOptionFrame = function(subLeftAnchor, offsetX, lastFrameTop, subChangeKey, subTitle, controlType, subLabel)
  local subOption, nextSubLeftAnchor
  local subOffsetX = 0
  local subOffsetY = 0

  subLabel = subLabel:gsub("%s+", "_")

  if controlType ~= nil then
    local typeValue = controlType[1]
    local enum = C[controlType[2]]

    if typeValue == 'dropdown' then
      subOption = createDropDown(subLabel, subTitle, subChangeKey, enum)
      nextSubLeftAnchor = subOption
      subOffsetX = -18
      subOffsetY = -18
    end
  else
    subOption = createCheckBox(subLabel, subTitle, subChangeKey)
    nextSubLeftAnchor = subOption.Text
    subOffsetY = -10
  end

  subOption:SetPoint('LEFT', subLeftAnchor, 'RIGHT', offsetX + subOffsetX, 0)
  subOption:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, subOffsetY)

  return subOption, nextSubLeftAnchor
end

local createModuleOptions = function(moduleInfo)
  local changeKey = moduleInfo['savedVariableName']
  local label = moduleInfo['label']
  local title = moduleInfo['title']
  local description = moduleInfo['description']
  local subToggles = moduleInfo['subToggles']

  local checkbox = createCheckBox('UIC_Options_CB_'..label, title, changeKey)
  checkbox:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  checkbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -10)

  cvarMap[changeKey] = {}
  cvarMap[changeKey]['frame'] = _G[moduleInfo['frameName']]
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

  -- Module subtoggles
  if subToggles then
    cvarMap[changeKey]['subFrames'] = {}

    local subtoggleEntries = subToggles['entries']
    local subFrames = cvarMap[changeKey]['subFrames']
    local subLeftAnchor = checkbox

    for i = 1, #subtoggleEntries do
        local subChangeKey = subtoggleEntries[i][1]
        local subTitle = subtoggleEntries[i][2]
        local changeNeedsRestart = subtoggleEntries[i][3] == true
        local controlType = subtoggleEntries[i][4]

        local subLabel = checkbox:GetName()..'_'..subTitle
        local offsetX = i == 1 and 0 or subToggles['offsetX']

        local subOption, nextSubLeftAnchor = createSubOptionFrame(subLeftAnchor, offsetX, lastFrameTop,
          subChangeKey, subTitle, controlType, subLabel)
        
        subLeftAnchor = nextSubLeftAnchor
        
        subFrames[#subFrames + 1] = subOption

        cvarMap[subChangeKey] = {} 
        cvarMap[subChangeKey]['option'] = subOption

        -- A subToggle with this index set means that upon modification, we need the module to update
        -- so we need to store the frame reference
        if changeNeedsRestart then
          cvarMap[subChangeKey]['mainFrame'] = cvarMap[changeKey]['frame']
        end
    end

    -- Separate the subtoggles into rows
    local rowSize = subToggles['rowSize']
    if rowSize then
      local i = rowSize + 1

      while i <= #subtoggleEntries do
        local prevRowStart = subFrames[i - rowSize]
        local rowStart = subFrames[i]

        rowStart:SetPoint('LEFT', prevRowStart, 'LEFT', 0, 0)
        rowStart:SetPoint('TOP', prevRowStart, 'BOTTOM', 0, -4)

        i = i + rowSize
      end
    end

    local subToggleFrameName = subtoggleEntries[#subtoggleEntries][2]:gsub("%s+", "_")
    local lastAddedSubCheckboxName = checkbox:GetName()..'_'..subToggleFrameName
    lastFrameTop = _G[lastAddedSubCheckboxName]
  end
end

local populateOptions = function()
  local outerPanelWidth = _G['InterfaceOptionsFramePanelContainer']:GetWidth()

  -- Header text
  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 16, -16)

  -- Informational text
  local infoText = optionsPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  infoText:SetWidth(outerPanelWidth - 40)
  infoText:SetJustifyH('LEFT')
  infoText:SetSpacing(2)
  infoText:SetText(L.OPTIONS_INFO)
  infoText:SetPoint('TOPLEFT', headerText, 7, -24)

  lastFrameTop = infoText
  lastFrameLeft = infoText

  for _, moduleInfo in ipairs(C.MODULES) do
    createModuleOptions(moduleInfo)
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

  _G[savedVariableName] = newValue

  if cvarMap[savedVariableName] ~= nil then
    if cvarMap[savedVariableName]['frame'] then
      local frame = cvarMap[savedVariableName]['frame']

      if newValue then
        frame:Enable()
      else
        frame:Disable()
      end
    elseif cvarMap[savedVariableName]['mainFrame'] ~= nil then
      local frame = cvarMap[savedVariableName]['mainFrame']

      frame:Update(savedVariableName, newValue)
    end
  end
end

UIC_Options = {}

UIC_Options.Initialize = function()
  cvarMap = {}
  changes = {}

  optionsPanel = CreateFrame('Frame', 'UIC_Options', _G['InterfaceOptionsFramePanelContainer'].NineSlice)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for cvar, frames in pairs(cvarMap) do -- read the current values and set the options
      local isSet = _G[cvar]
      frames['option']:SetValue(isSet)

      if frames['subFrames'] then -- Enable/Disable subframes
        subFramesSetEnable(frames['subFrames'], isSet)
      end
    end
  end)

  optionsPanel.okay = function(...)
    for savedVariableName, values in pairs(changes) do
      applyChange(savedVariableName, values[2])
    end

    changes = {}
  end

  optionsPanel.cancel = function(...)
    DEFAULT_CHAT_FRAME:AddMessage(L.CHANGES_CANCELLED)

    for savedVariableName, values in pairs(changes) do
      cvarMap[savedVariableName]['option']:SetValue(values[1])
    end

    changes = {}
  end

  populateOptions()

  InterfaceOptions_AddCategory(optionsPanel)
end

return UIC_Options
