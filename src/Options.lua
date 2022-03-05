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

local gameFontColor = {} -- This will override checkbox texts
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local disabledFontColor = {} -- This is used for disabled checkbox texts
disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4] = _G['GameFontDisable']:GetTextColor()

local optionsPanel, changes, cvarMap, lastFrameTop, lastFrameLeft

local subFramesSetEnable = function(subFrames, isSet)
  if subFrames then
    for i = 1, #subFrames do
      subFrames[i]:SetEnabled(isSet)

      local r, g, b, a

      if isSet then
        r, g, b, a = gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4]
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
  checkbox:SetScript("OnClick", function(self, button, down)
    local newValue = self:GetChecked()

    changes[changeKey] = newValue

    if newValue then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end

    if cvarMap[changeKey] and cvarMap[changeKey]['subFrames'] then -- if this is not a subToggle variable
      subFramesSetEnable(cvarMap[changeKey]['subFrames'], newValue) -- Enable/disable subcomponents, if any
    end
  end)

  return checkbox
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
  cvarMap[changeKey]['checkbox'] = checkbox
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

    local subFrames = cvarMap[changeKey]['subFrames']
    local subLeftAnchor = checkbox

    for i = 1, #subToggles do
        local subChangeKey = subToggles[i][1]
        local subTitle = subToggles[i][2]
        local subLabel = checkbox:GetName()..'_'..subTitle
        local offsetX = i == 1 and 0 or 72

        local subCheckbox = createCheckBox(subLabel, subTitle, subChangeKey)
        subCheckbox:SetPoint('LEFT', subLeftAnchor, 'RIGHT', offsetX, 0)
        subCheckbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -10)

        subLeftAnchor = subCheckbox.Text

        subFrames[#subFrames + 1] = subCheckbox

        cvarMap[subChangeKey] = {} 
        cvarMap[subChangeKey]['checkbox'] = subCheckbox
    end

    local lastAddedSubCheckboxName = checkbox:GetName()..'_'..subToggles[#subToggles][2]
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

  if cvarMap[savedVariableName] ~= nil and cvarMap[savedVariableName]['frame'] then
    local frame = cvarMap[savedVariableName]['frame']
    if newValue then
      frame:Enable()
    else
      frame:Disable()
    end
  end
  
  _G[savedVariableName] = newValue
end

UIC_Options = {}

UIC_Options.Initialize = function()
  cvarMap = {}
  changes = {}

  optionsPanel = CreateFrame('Frame', 'UIC_Options', UIParent)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for cvar, frames in pairs(cvarMap) do -- read the current values and set the checkboxes
      local isSet = _G[cvar]
      frames['checkbox']:SetChecked(isSet)

      if frames['subFrames'] then -- Enable/Disable subframes
        subFramesSetEnable(frames['subFrames'], isSet)
      end
    end
  end)

  optionsPanel.okay = function(...)
    for savedVariableName, newValue in pairs(changes) do
      applyChange(savedVariableName, newValue)
    end

    changes = {}
  end

  optionsPanel.cancel = function(...)
    DEFAULT_CHAT_FRAME:AddMessage(L.CHANGES_CANCELLED)

    for savedVariableName, newValue in pairs(changes) do
      cvarMap[savedVariableName]['checkbox']:SetChecked(not newValue)
    end

    changes = {}
  end

  populateOptions()

  InterfaceOptions_AddCategory(optionsPanel)
end

return UIC_Options
