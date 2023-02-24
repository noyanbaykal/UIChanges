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

local CLAMS = {
  [5523] = true,  -- Small Barnacled Clam
  [5524] = true,  -- Thick-shelled Clam
  [7973] = true,  -- Big-mouth Clam
  [15874] = true, -- Soft-shelled Clam
  [24476] = true  -- Jaggal Clam
}

local mainFrame, awaitingCombatEnd

local openClams = function()
  for bag = 0, 4 do
    local slotCount = GetContainerNumSlots(bag)

    for slot = 0, slotCount do
      local _, _, locked, _, _, _, _, _, _, itemID, _ = GetContainerItemInfo(bag, slot)

      if CLAMS[itemID] then
        if locked then
          awaitingCombatEnd = true
        elseif not InCombatLockdown() then
          UseContainerItem(bag, slot)
        end
      end
    end
  end
end

local EVENTS = {}
EVENTS['BAG_UPDATE_DELAYED'] = function()
  if InCombatLockdown() then
    awaitingCombatEnd = true
  else
    openClams()
  end
end
EVENTS['PLAYER_REGEN_ENABLED'] = function()
  if awaitingCombatEnd then
    awaitingCombatEnd = false
    openClams()
  end
end

local shouldRespond = function()
  -- UseContainerItem becomes a secure function in WOTLK so this module is for pre-WOTLK only
  local isClassicEraOrTBC = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC 
  or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

  return isClassicEraOrTBC
end

BagUtilities = {}

BagUtilities.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_BagUtilities', UIParent)
  mainFrame:Hide()

  awaitingCombatEnd = false

  if shouldRespond() then
    mainFrame:SetScript('OnEvent', function(self, event, ...)
      EVENTS[event](...)
    end)
  end
end

BagUtilities.Enable = function()
  if shouldRespond() then
    C.REGISTER_EVENTS(mainFrame, EVENTS)
  end
end

BagUtilities.Disable = function()
  if shouldRespond() then
    C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  end
end

return BagUtilities
