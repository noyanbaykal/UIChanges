--[[
UIChanges

Copyright (C) 2019 - 2026 Melik Noyan Baykal

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

local addonName, addonTable = ...

local L = addonTable.L
local C = addonTable.C

local settingsTable = C.SETTINGS_TABLE -- We'll be able to reference entries by their keys through the settingsTable

local onSettingChanged = function(setting, newValue)
  local key = setting['variableKey']
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
end

local isSubsettingModifiable = function(parentInitializer)
  return parentInitializer:GetData().setting:GetValue()
end

local createSubsettingOptions = function(category, layout, parentInitializer, subsettings)
  if subsettings then
    for i = 1, #subsettings do
      local entry = subsettings[i]

      local key = entry['entryKey']
      local entryType = entry['entryType']
      local title = entry['title']
      local tooltipText = entry['tooltipText']
      local frameName = entry['frameName']
      local updateCallback = entry['updateCallback']

      local subsettingInitializer

      if entryType == 'dropdown' then
        local enumTable = settingsTable[key]['dropdownEnum']
        local selectedIndex = UIChanges_Profile[key]

        local function getOptions()
            local container = Settings.CreateControlTextContainer()

            for i, enum in ipairs(enumTable) do
              container:Add(i, enum)
            end

            return container:GetData()
        end

        local dropdown = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Number, title, selectedIndex)
        dropdown:SetValueChangedCallback(onSettingChanged)

        subsettingInitializer = Settings.CreateDropdown(category, dropdown, getOptions, tooltipText)
      elseif entryType == 'button' then
        subsettingInitializer = CreateSettingsButtonInitializer(frameName, title, updateCallback, tooltipText, true, nil, nil)

        layout:AddInitializer(subsettingInitializer)
      else
        local selectedState = UIChanges_Profile[key]

        local checkbox = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Boolean, title, selectedState)
        checkbox:SetValueChangedCallback(onSettingChanged)

        subsettingInitializer = Settings.CreateCheckbox(category, checkbox, tooltipText)
      end

      if parentInitializer then
        subsettingInitializer:SetParentInitializer(parentInitializer, GenerateClosure(isSubsettingModifiable, parentInitializer));
      end
    end
  end
end

local createModuleOptions = function(category, layout, moduleEntry)
  local key = moduleEntry['moduleKey']
  local frameName = moduleEntry['frameName']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local moduleButtonEntry = moduleEntry['moduleButton']
  local subsettings = moduleEntry['subsettings']

  local parentInitializer
  local selectedState = UIChanges_Profile[key]

  local moduleSetting = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Boolean, title, selectedState)
  moduleSetting:SetValueChangedCallback(onSettingChanged)

  if moduleButtonEntry then
    local mbTitle = moduleButtonEntry['title']
    local mbCallback = moduleButtonEntry['updateCallback']

    parentInitializer = CreateSettingsCheckboxWithButtonInitializer(moduleSetting, mbTitle, mbCallback, nil, true, description)

    parentInitializer:AddSearchTags(title, mbTitle);
    layout:AddInitializer(parentInitializer);
  else
    parentInitializer = Settings.CreateCheckbox(category, moduleSetting, description)
  end

  createSubsettingOptions(category, layout, parentInitializer, subsettings)
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  local optionsCategory, optionsLayout = Settings.RegisterVerticalLayoutCategory(addonName)

  local disclaimerText = { name = '|cFFFF8000' .. L.MODULE_AVAILABILITY_TEXT .. '|r' }
  local modulesDisclaimer = Settings.CreateElementInitializer("SettingsListSectionHeaderTemplate", disclaimerText)
  optionsLayout:AddInitializer(modulesDisclaimer)

  for _, moduleEntry in ipairs(C.MODULES) do
    if not moduleEntry['moduleKey'] then
      -- The base module cannot be toggled and only has subsettings.
      createSubsettingOptions(optionsCategory, optionsLayout, nil, moduleEntry['subsettings'])
    else
      createModuleOptions(optionsCategory, optionsLayout, moduleEntry)
    end
  end

  Settings.RegisterAddOnCategory(optionsCategory)

  _G[C.MAIN_FRAME_NAME].optionsCategoryID = optionsCategory:GetID() -- We'll use this variable to open the panel with a macro
end

addonTable.UIC_Options = UIC_Options
