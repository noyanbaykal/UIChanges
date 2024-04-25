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

local initialize = function()
  C.DEFINE_MODULES()
  C.INITIALIZE_PROFILE()

  for _, moduleEntry in ipairs(C.MODULES) do
    local moduleName = moduleEntry['moduleName']
    local moduleKey = moduleEntry['moduleKey']

    local module = addonTable[moduleName]
    if module then
      module:Initialize()
    end

    if UIChanges_Profile[moduleKey] then
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

mainFrame:SetScript('OnEvent', function(self, event, ...)
  if event == 'PLAYER_LOGIN' then
    initialize()
  end
end)

local onMinimapZoomChange = function(level)
  Minimap:SetZoom(level)

  -- Call the minimap update function to update the button states
  Minimap_OnEvent(_G['MiniMap'], 'MINIMAP_UPDATE_ZOOM')
end

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
