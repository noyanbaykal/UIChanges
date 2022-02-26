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

local changes = {}

UIC_Options = {}

UIC_Options.Initialize = function(modules)
  local optionsPanel = CreateFrame('Frame', 'UIC_Options', UIParent)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel.okay = function(...)
    for k, v in pairs(table) do
      print(k, v) -- TEST

      _G[k] = v

      if v then
        modules[k]:Enable()
      else
        modules[k]:Disable()
      end
    end
  end

  optionsPanel.cancel = function(...)
    changes = {}
  end

  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 16, -16)

  -- TODO: implement options!


  -- TODO: implement a generic cb generator. with sound
  local cb = CreateFrame('CheckButton', 'UIC_Options_CB_AHT', optionsPanel, 'InterfaceOptionsCheckButtonTemplate')
  cb:SetPoint('TOPLEFT', 20, -20)
  cb.Text:SetText('Print when you jump')
  cb.SetValue = function(_, value)
    local asd = (value == '1') -- value can be either '0' or '1'
  end
  cb:SetChecked(false) -- set the initial checked state

  InterfaceOptions_AddCategory(optionsPanel)
end

return UIC_Options
