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

local gameFontColor = {} -- This will be used for checkbox texts
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local optionsPanel, changes, cvarMap, lastFrameTop, lastFrameLeft

local subFramesSetEnable = function(subFrames, isSet)
  if subFrames then
    for i = 1, #subFrames do
      subFrames[i]:SetEnabled(isSet)
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

    if cvarMap[changeKey] then
      subFramesSetEnable(cvarMap[changeKey]['subFrames'], newValue) -- Enable/disable subcomponents, if any
    end
  end)

  return checkbox
end

local createModuleOptions = function(i)
  local changeKey = C.MODULE_VARIABLES[i]
  local label = C.MODULES[C.MODULE_VARIABLES[i]]['label']
  local title = C.MODULES[C.MODULE_VARIABLES[i]]['title']
  local description = C.MODULES[C.MODULE_VARIABLES[i]]['description']
  local subToggles = C.MODULES[C.MODULE_VARIABLES[i]]['subToggles']

  local checkbox = createCheckBox('UIC_Options_CB_'..label, title, changeKey)
  checkbox:SetPoint('LEFT', lastFrameLeft, 'LEFT', 0, 0)
  checkbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -10)

  cvarMap[changeKey] = {}
  cvarMap[changeKey]['checkbox'] = checkbox

  -- Module description
  local extraTextOffsetY = -16
  for i = 1, #description do
    local descriptionText = checkbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    descriptionText:SetTextColor(1, 1, 1)
    descriptionText:SetText(description[i])
    descriptionText:SetPoint('LEFT', checkbox.Text, 'LEFT', 0, 0)
    descriptionText:SetPoint('TOP', checkbox, 'BOTTOM', 0, (i - 1) * extraTextOffsetY)
    descriptionText:SetJustifyH('LEFT')

    lastFrameTop = descriptionText
  end

  -- Module subtoggles
  if subToggles then
    local subLeftAnchor = checkbox
    cvarMap[changeKey]['subFrames'] = {}

    for i = 1, #subToggles do
        local subChangeKey = subToggles[i][1]
        local subTitle = subToggles[i][2]
        local subLabel = checkbox:GetName()..'_'..subTitle
        local offsetX = i == 1 and 0 or 72

        local subCheckbox = createCheckBox(subLabel, subTitle, subChangeKey)
        subCheckbox:SetPoint('LEFT', subLeftAnchor, 'RIGHT', offsetX, 0)
        subCheckbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, -10)

        subLeftAnchor = subCheckbox.Text

        local subFrames = cvarMap[changeKey]['subFrames']
        subFrames[#subFrames + 1] = subCheckbox
    end

    local lastAddedSubCheckboxName = checkbox:GetName()..'_'..subToggles[#subToggles][2]
    lastFrameTop = _G[lastAddedSubCheckboxName]
  end
end

local populateOptions = function()
  -- Header text
  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 16, -16)

  -- Informational text
  local infoText = optionsPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  infoText:SetTextColor(1, 1, 1)
  infoText:SetText(L.OPTIONS_INFO)
  infoText:SetPoint('TOPLEFT', headerText, 7, -24)

  lastFrameTop = infoText
  lastFrameLeft = infoText

  for i = 1, #C.MODULE_VARIABLES do
    createModuleOptions(i)
  end
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
    for moduleVariable, newValue in pairs(changes) do
      _G[moduleVariable] = newValue

      if newValue then
        C.MODULES[moduleVariable]['frame']:Enable()
      else
        C.MODULES[moduleVariable]['frame']:Disable()
      end
    end
  end

  optionsPanel.cancel = function(...)
    changes = {}
    DEFAULT_CHAT_FRAME:AddMessage(L.CHANGES_CANCELLED)
  end

  populateOptions()

  InterfaceOptions_AddCategory(optionsPanel)
end

return UIC_Options
