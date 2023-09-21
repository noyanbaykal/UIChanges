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

local onMinimapZoomChange = function(level)
  Minimap:SetZoom(level)

  -- Call the minimap update function to update the button states
  Minimap_OnEvent(_G['MiniMap'], 'MINIMAP_UPDATE_ZOOM')
end

local hideEraMiniMapWorldMapButton = function()
  if MiniMapWorldMapButton then
    MiniMapWorldMapButton:SetAlpha(0)
    MiniMapWorldMapButton:SetMouseClickEnabled(false)
    MiniMapWorldMapButton:SetMouseMotionEnabled(false)
  end
end

local setMissingVariables = function()
  local encounteredNew = false

  if UIC_Toggle_Quick_Zoom == nil then
    UIC_Toggle_Quick_Zoom = true
    encounteredNew = true
  end

  if UIC_Toggle_Hide_Era_Map_Button == nil then
    UIC_Toggle_Hide_Era_Map_Button = true
    encounteredNew = true
  end

  if UIC_AD_IsEnabled == nil then
    UIC_AD_IsEnabled = true
    encounteredNew = true
  end

  if UIC_AHT_IsEnabled == nil then
    UIC_AHT_IsEnabled = true
    encounteredNew = true
  end

  if UIC_BU_IsEnabled == nil then
    UIC_BU_IsEnabled = true
    encounteredNew = true
  end

  if UIC_CR_IsEnabled == nil then
    UIC_CR_IsEnabled = true
    encounteredNew = true
  end

  if UIC_CR_ErrorFrameAnchor == nil or type(UIC_CR_ErrorFrameAnchor) ~= 'number' then
    UIC_CR_ErrorFrameAnchor = 1
    encounteredNew = true
  end

  if UIC_CR_BreathWarning == nil then
    UIC_CR_BreathWarning = true
    encounteredNew = true
  end

  if UIC_CR_BreathWarning_Sound == nil then
    UIC_CR_BreathWarning_Sound = true
    encounteredNew = true
  end

  if UIC_CR_CombatWarning == nil then
    UIC_CR_CombatWarning = true
    encounteredNew = true
  end

  if UIC_CR_CombatWarning_Sound == nil then
    UIC_CR_CombatWarning_Sound = false
    encounteredNew = true
  end

  if UIC_CR_GatheringFailure == nil then
    UIC_CR_GatheringFailure = true
    encounteredNew = true
  end

  if UIC_CR_GatheringFailure_Sound == nil then
    UIC_CR_GatheringFailure_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatLos == nil then
    UIC_CR_CombatLos = true
    encounteredNew = true
  end

  if UIC_CR_CombatLos_Sound == nil then
    UIC_CR_CombatLos_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatDirection == nil then
    UIC_CR_CombatDirection = false
    encounteredNew = true
  end

  if UIC_CR_CombatDirection_Sound == nil then
    UIC_CR_CombatDirection_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatRange == nil then
    UIC_CR_CombatRange = false
    encounteredNew = true
  end

  if UIC_CR_CombatRange_Sound == nil then
    UIC_CR_CombatRange_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatInterrupted == nil then
    UIC_CR_CombatInterrupted = false
    encounteredNew = true
  end

  if UIC_CR_CombatInterrupted_Sound == nil then
    UIC_CR_CombatInterrupted_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatCooldown == nil then
    UIC_CR_CombatCooldown = false
    encounteredNew = true
  end

  if UIC_CR_CombatCooldown_Sound == nil then
    UIC_CR_CombatCooldown_Sound = false
    encounteredNew = true
  end

  if UIC_CR_CombatNoResource == nil then
    UIC_CR_CombatNoResource = false
    encounteredNew = true
  end

  if UIC_CR_CombatNoResource_Sound == nil then
    UIC_CR_CombatNoResource_Sound = false
    encounteredNew = true
  end

  if UIC_CR_InteractionRange == nil then
    UIC_CR_InteractionRange = false
    encounteredNew = true
  end

  if UIC_CR_InteractionRange_Sound == nil then
    UIC_CR_InteractionRange_Sound = false
    encounteredNew = true
  end

  if UIC_DMB_IsEnabled == nil then
    UIC_DMB_IsEnabled = true
    encounteredNew = true
  end

  local isCvarShowPartyPets = GetCVar('showPartyPets') == 1

  if UIC_PPF_IsEnabled == nil then
    if isCvarShowPartyPets then
      UIC_PPF_IsEnabled = true
    else
      UIC_PPF_IsEnabled = false
    end

    encounteredNew = true
  else
    local cvar = isCvarShowPartyPets
    local addonVar = UIC_PPF_IsEnabled

    if cvar and addonVar == false then
      UIC_PPF_IsEnabled = true
    end
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
    UIC_PA_Battleground = false
    encounteredNew = true
  end

  if UIC_PA_Raid == nil then
    UIC_PA_Raid = false
    encounteredNew = true
  end

  if UIC_PA_Arena == nil then
    UIC_PA_Arena = false
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
    if _G['UIC_Toggle_Hide_Era_Map_Button'] and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
      hideEraMiniMapWorldMapButton()
    end
  end
end)

_G['MinimapZoomOut']:HookScript('OnClick', function()
  if _G['UIC_Toggle_Quick_Zoom'] and IsShiftKeyDown() then
    onMinimapZoomChange(0)
  end
end)

_G['MinimapZoomIn']:HookScript('OnClick', function()
  if _G['UIC_Toggle_Quick_Zoom'] and IsShiftKeyDown() then
    onMinimapZoomChange(Minimap:GetZoomLevels() - 1)
  end
end)
