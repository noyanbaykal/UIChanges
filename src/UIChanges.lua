--[[
UIChanges

Copyright (C) 2019 - 2023 Melik Noyan Baykal

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

local modules

local hideEraMiniMapWorldMapButton = function()
  if MiniMapWorldMapButton then
    MiniMapWorldMapButton:SetAlpha(0)
    MiniMapWorldMapButton:SetMouseClickEnabled(false)
    MiniMapWorldMapButton:SetMouseMotionEnabled(false)
  end
end

local setMissingVariables = function()
  local encounteredNew = false

  if UIC_AHT_IsEnabled == nil then
    UIC_AHT_IsEnabled = true
    encounteredNew = true
  end
  
  if UIC_AFR_IsEnabled == nil then
    UIC_AFR_IsEnabled = false
    encounteredNew = true
  end
  
  if UIC_AFR_EnteredCombat == nil then
    UIC_AFR_EnteredCombat = false
    encounteredNew = true
  end

  if UIC_AFR_NoResource == nil then
    UIC_AFR_NoResource = false
    encounteredNew = true
  end

  if UIC_AFR_TargetFrame == nil or type(UIC_AFR_TargetFrame) ~= 'number' then
    UIC_AFR_TargetFrame = 1
    encounteredNew = true
  end

  if UIC_AFR_PlaySound == nil then
    UIC_AFR_PlaySound = false
    encounteredNew = true
  end

  if UIC_BU_IsEnabled == nil then
    UIC_BU_IsEnabled = true
    encounteredNew = true
  end

  if UIC_DMB_IsEnabled == nil then
    UIC_DMB_IsEnabled = true
    encounteredNew = true
  end
  
  if UIC_PPF_IsEnabled == nil then
    UIC_PPF_IsEnabled = PPF_IsEnabled or false -- Special case for PPF users migrating to UIC
    encounteredNew = true
  end
  
  if UIC_PA_IsEnabled == nil then
    UIC_PA_IsEnabled = true
    encounteredNew = true
  end
  
  if UIC_PA_Party == nil then
    UIC_PA_Party = true
    encounteredNew = true
  end
  
  if UIC_PA_Battleground == nil then
    UIC_PA_Battleground = true
    encounteredNew = true
  end
  
  if UIC_PA_Raid == nil then
    UIC_PA_Raid = true
    encounteredNew = true
  end
  
  if UIC_PA_Arena == nil then
    UIC_PA_Arena = true
    encounteredNew = true
  end  

  if encounteredNew then
    DEFAULT_CHAT_FRAME:AddMessage(L.FIRST_TIME)
  end
end

local initialize = function()
  setMissingVariables()

  for _, moduleInfo in ipairs(C.MODULES) do
    local frame = _G[moduleInfo['frameName']]
    frame:Initialize()

    if _G[moduleInfo['savedVariableName']] then
      frame:Enable()
    end
  end

  UIC_Options.Initialize()
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
  elseif event == 'PLAYER_ENTERING_WORLD' then
    hideEraMiniMapWorldMapButton()
  end
end)
