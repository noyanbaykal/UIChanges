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

local optionsPanel, toggleFrames

local changes = {}

local createToggleFrame = function(changeKey, label, title, initialValue, x, y)
  local cb = CreateFrame('CheckButton', 'UIC_Options_CB_'..label, optionsPanel, 'InterfaceOptionsCheckButtonTemplate')
  cb:SetPoint('TOPLEFT', x, y)
  cb.Text:SetText(text)
  cb:SetChecked(initialValue)
  cb:SetScript("OnClick", function(self)
    local newValue = self:GetChecked()

    changes[changeKey] = newValue

    if tick then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end
  end)
end

UIC_Options = {}

UIC_Options.Initialize = function()
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
  end

  -- Header text
  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 16, -16)

  toggleFrames = {}
  for i = 1, #C.MODULE_VARIABLES do
    local changeKey = C.MODULE_VARIABLES[i]
    local label = C.MODULES[C.MODULE_VARIABLES[i]]['label']
    local title = C.MODULES[C.MODULE_VARIABLES[i]]['title']
    local initialValue = _G[changeKey]
    local x = 20
    local y = i * -20

    toggleFrames[i] = createToggleFrame(changeKey, label, title, initialValue, x, y)
  end

  InterfaceOptions_AddCategory(optionsPanel)
end

return UIC_Options
