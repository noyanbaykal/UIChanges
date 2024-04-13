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

local _, addonTable = ...

local L = addonTable.L
local C = addonTable.C

local onMinimapZoomChange = function(level)
  Minimap:SetZoom(level)

  -- Call the minimap update function to update the button states
  Minimap_OnEvent(_G['MiniMap'], 'MINIMAP_UPDATE_ZOOM')
end

local checkSavedVariables = function()
  local hasUnexpectedChanges = false

  if not UIChanges_Profile then -- Either first time using UIChanges or upgrading from version < 1.2.0
    hasUnexpectedChanges = true

    UIChanges_Profile = {}
  end

  for _, entry in ipairs(C.savedVariableEntries) do
    local name = entry[1]

    if UIChanges_Profile[name] == nil then
      hasUnexpectedChanges = true

      local defaultValue = entry[2]
      if type(defaultValue) == 'function' then
        defaultValue = defaultValue()
      end

      local previousVersionValue = _G[name] -- Only when upgrading from version < 1.2.0
    
      if previousVersionValue and type(previousVersionValue) == type(defaultValue) then
        UIChanges_Profile[name] = previousVersionValue
      else
        UIChanges_Profile[name] = defaultValue
      end
    end
  end

  if hasUnexpectedChanges then
    DEFAULT_CHAT_FRAME:AddMessage(L.FIRST_TIME)
  end
end

local initialize = function()
  checkSavedVariables()

  for _, moduleInfo in ipairs(C.MODULES) do
    local module = addonTable[moduleInfo['moduleName']]
    module:Initialize()

    if UIChanges_Profile[moduleInfo['savedVariableName']] then
      module:Enable()
    end
  end

  addonTable.UIC_Options.Initialize()
end

-- The addon entry is right here

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
  DEFAULT_CHAT_FRAME:AddMessage(L.TXT_NOT_CLASSIC)
  return
end

local mainFrame = CreateFrame('Frame', 'UIC_Main', UIParent)
mainFrame:Hide()

mainFrame:RegisterEvent('PLAYER_LOGIN')

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
  mainFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
end

mainFrame:SetScript('OnEvent', function(self, event, ...)
  if event == 'PLAYER_LOGIN' then
    initialize()
  end
end)

_G['MinimapZoomOut']:HookScript('OnClick', function()
  if UIChanges_Profile['UIC_Toggle_Quick_Zoom'] and IsShiftKeyDown() then
    onMinimapZoomChange(0)
  end
end)

_G['MinimapZoomIn']:HookScript('OnClick', function()
  if UIChanges_Profile['UIC_Toggle_Quick_Zoom'] and IsShiftKeyDown() then
    onMinimapZoomChange(Minimap:GetZoomLevels() - 1)
  end
end)
