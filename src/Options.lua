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

local optionsPanel, changes, toggleFrames

local createToggleFrame = function(i, x, y)
  local changeKey = C.MODULE_VARIABLES[i]
  local label = C.MODULES[C.MODULE_VARIABLES[i]]['label']
  local title = C.MODULES[C.MODULE_VARIABLES[i]]['title']
  local description = C.MODULES[C.MODULE_VARIABLES[i]]['description']
  local initialValue = _G[changeKey]

  local checkbox = CreateFrame('CheckButton', 'UIC_Options_CB_'..label, optionsPanel, 'InterfaceOptionsCheckButtonTemplate')
  checkbox:SetPoint('TOPLEFT', x, y)
  checkbox.Text:SetText(text)
  checkbox:SetChecked(initialValue)
  checkbox:SetScript("OnClick", function(self)
    local newValue = self:GetChecked()

    changes[changeKey] = newValue

    if tick then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end
  end)

  -- Module name
  local nameText = checkbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  nameText:SetText(title)
  nameText:SetPoint('LEFT', checkbox, 'RIGHT', 6, 0)

  local offsetY = (checkbox:GetHeight() - nameText:GetHeight()) / 2
  nameText:SetPoint('TOP', checkbox, 'TOP', 0, -1 * offsetY)

  -- Module description
  local descriptionText = checkbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  descriptionText:SetTextColor(1, 1, 1)
  descriptionText:SetText(description)
  descriptionText:SetPoint('LEFT', checkbox, 'RIGHT', 10, 0)
  descriptionText:SetPoint('TOP', checkbox, 'BOTTOM', 0, 0)
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
  infoText:SetPoint('TOPLEFT', optionsPanel, 20, -40)

  local lastY = -20

  toggleFrames = {}
  for i = 1, #C.MODULE_VARIABLES do
    lastY = lastY - 45

    local x = 20
    local y = lastY

    toggleFrames[i] = createToggleFrame(i, x, y)
  end
end

UIC_Options = {}

UIC_Options.Initialize = function()
  changes = {}

  optionsPanel = CreateFrame('Frame', 'UIC_Options', UIParent)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript("OnShow", function()
    for i = 1, #toggleFrames do
      toggleFrames[i]:SetChecked(_G[C.MODULE_VARIABLES[i]])
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
