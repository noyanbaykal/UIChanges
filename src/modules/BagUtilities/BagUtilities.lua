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

local CLAMS_TOTAL = 4
local CLAM_IDS = {
  [5523] = true, -- Small Barnacled Clam
  [5524] = true, -- Thick-shelled Clam
  [7973] = true, -- Big-mouth Clam
  [15874] = true, -- Soft-shelled Clam
}

if LE_EXPANSION_LEVEL_CURRENT > LE_EXPANSION_CLASSIC then
  CLAM_IDS[24476] = true -- Jaggal Clam
  CLAMS_TOTAL = CLAMS_TOTAL + 1
end

local TOGGLE_TIMER_INTERVAL = 1 -- Seconds

local mainFrame, clams, clamsCount, toggleTimer, isOpeningClams, stack, isWaitLootClose

local push = function(bagSlot, slot)
  local i = #stack + 1
  stack[i] = {bagSlot, slot}
end

local pop = function()
  local i = #stack

  if i < 1 then
    return nil, nil
  end

  local bagSlot = stack[i][1]
  local slot = stack[i][2]

  stack[i] = nil

  return bagSlot, slot
end

local openNextClam = function()
  local bagSlot, slot = pop()

  if bagSlot == nil or slot == nil then
    isOpeningClams = false
    return
  end

  C_Container.UseContainerItem(bagSlot, slot)
end

local checkBag = function(bagSlot)
  local slotCount = C_Container.GetContainerNumSlots(bagSlot)

  for slot = 1, slotCount do
    local itemInfo = C_Container.GetContainerItemInfo(bagSlot, slot)

    if itemInfo then
      local itemName = itemInfo.itemName

      if clams[itemName] then
        push(bagSlot, slot)
      end
    end
  end
end

local startOpeningClams = function()
  for i = 0, 4, 1 do
    checkBag(i)
  end

  isOpeningClams = true
  openNextClam()
end

local checkIfDoneReceivingClamInfo = function()
  if clamsCount == CLAMS_TOTAL then
    mainFrame:UnregisterEvent('GET_ITEM_INFO_RECEIVED')
  end
end

local handleItemInfoReceived = function(itemID, success)
  if itemID and success and CLAM_IDS[itemID] then
    local name = GetItemInfo(itemID)

    clams[name] = true
    clamsCount = clamsCount + 1

    checkIfDoneReceivingClamInfo()
  end
end

-- Getting itemInfo is not guaranteed. Have to query and then listen to events afterwards
local initializeClamsTable = function()
  clams = {}
  clamsCount = 0

  for id, _ in pairs(CLAM_IDS) do
    local name = GetItemInfo(id)

    if name then
      clams[name] = true
      clamsCount = clamsCount + 1
    end
  end

  checkIfDoneReceivingClamInfo()
end

local EVENTS = {}
EVENTS['GET_ITEM_INFO_RECEIVED'] = handleItemInfoReceived

EVENTS['LOOT_READY'] = function()
  if isOpeningClams then
    for i = GetNumLootItems(), 1, -1 do
      LootSlot(i)
    end
  end
end

EVENTS['LOOT_CLOSED'] = function()
  if isWaitLootClose then
    isWaitLootClose = false
    startOpeningClams()
  end
end

EVENTS['PLAYER_MONEY'] = function()
  if not InCombatLockdown() and _G['LootFrame']:IsVisible() == false then
    startOpeningClams()
  end
end

EVENTS['BAG_UPDATE_DELAYED'] = function()
  if not InCombatLockdown() and _G['LootFrame']:IsVisible() == false then
    startOpeningClams()
  end
end

EVENTS['PLAYER_REGEN_ENABLED'] = function()
  if _G['LootFrame']:IsVisible() then
    -- This is for the edge case of the player getting out of combat while looting
    isWaitLootClose = true
  else
    startOpeningClams()
  end
end

-- Make sure we have finished with the itemInfos before disabling the module, to prevent breaking
-- the setup incase the user rapidly toggles the addon.
local toggleGuard = function()
  if clamsCount == CLAMS_TOTAL then
    if toggleTimer and not toggleTimer:IsCancelled() then
      toggleTimer:Cancel()
    end

    C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  end
end

local BagUtilities = {}

BagUtilities.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_BagUtilities', UIParent)
  mainFrame:Hide()

  isOpeningClams = false
  stack = {}

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

BagUtilities.Enable = function()
  if not clams then
    initializeClamsTable()
  end

  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

BagUtilities.Disable = function()
  if clamsCount == CLAMS_TOTAL then
    C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  else
    toggleTimer = C_Timer.NewTicker(TOGGLE_TIMER_INTERVAL, toggleGuard)
  end
end

addonTable.BagUtilities = BagUtilities
