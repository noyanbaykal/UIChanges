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

local textEnabled = ENABLE or SCREEN_NARRATOR_DIALOG_ENABLE or SHOW_PETBATTLE_COMBAT_TEXT

local onSettingChanged = function(setting, newValue)
  local key = setting['variableKey']
  local entry = settingsTable[key]
  local consoleVariable = entry['consoleVariableName']
  local updateCallback = entry['updateCallback']

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

  if updateCallback then
    updateCallback(newValue)
  end
end

local createSubsettingOptions = function(category, layout, subsettings)
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

      if entryType == 'slider' then
        local enumTable = settingsTable[key]['sliderEnum']
        local selectedIndex = UIChanges_Profile[key]

        local subsetting = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Number, title, selectedIndex)
        subsetting:SetValueChangedCallback(onSettingChanged)

        local sliderOptions = Settings.CreateSliderOptions(1, #enumTable, 1)

        sliderOptions:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
            return enumTable[value]
        end)

        subsettingInitializer = Settings.CreateSlider(category, subsetting, sliderOptions, tooltipText)
      elseif entryType == 'button' then
        local buttonText = entry['buttonText']

        subsettingInitializer = CreateSettingsButtonInitializer(title, buttonText, updateCallback, tooltipText, false, nil, nil)

        layout:AddInitializer(subsettingInitializer)
      else
        local selectedState = UIChanges_Profile[key]

        local subsetting = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Boolean, title, selectedState)
        subsetting:SetValueChangedCallback(onSettingChanged)

        subsettingInitializer = Settings.CreateCheckbox(category, subsetting, tooltipText)
      end
    end
  end
end

local createModuleOptions = function(category, layout, moduleEntry)
  local key = moduleEntry['moduleKey']
  local frameName = moduleEntry['frameName']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local subsettings = moduleEntry['subsettings']

  local parentInitializer
  local selectedState = UIChanges_Profile[key]

  layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(title))

  local moduleSetting = Settings.RegisterAddOnSetting(category, frameName, key, UIChanges_Profile, Settings.VarType.Boolean, textEnabled, selectedState)
  moduleSetting:SetValueChangedCallback(onSettingChanged)

  parentInitializer = Settings.CreateCheckbox(category, moduleSetting, description)

  createSubsettingOptions(category, layout, subsettings)
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  local optionsCategory, optionsLayout = Settings.RegisterVerticalLayoutCategory(addonName)

  for _, moduleEntry in ipairs(C.MODULES) do
    if not moduleEntry['moduleKey'] then
      -- The base module cannot be toggled and only has subsettings.
      createSubsettingOptions(optionsCategory, optionsLayout, moduleEntry['subsettings'])
    else
      createModuleOptions(optionsCategory, optionsLayout, moduleEntry)
    end
  end

  Settings.RegisterAddOnCategory(optionsCategory)

  _G[C.MAIN_FRAME_NAME].optionsCategoryID = optionsCategory:GetID() -- We'll use this variable to open the panel with the following macro:
  -- /run Settings.OpenToCategory(_G['UIC_Main'].optionsCategoryID);
end

addonTable.UIC_Options = UIC_Options
