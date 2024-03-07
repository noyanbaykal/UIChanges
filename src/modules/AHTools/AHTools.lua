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

local _, sharedTable = ...

local C = sharedTable.C

-- Forward declaring modules
local mainFrame, buyoutWarning, calculator

local AH_SEARCH_INTERVAL = 0.3 -- Seconds
local loadedAH = false
local lastAHSearchTime

local function onShow()
  -- The first time the AH is shown, we'll hook into the button onClicks
  if loadedAH == false then
    buyoutWarning.LoadedAH()
    calculator.LoadedAH()
    loadedAH = true
  end

  calculator.Show()
end

local function onClosed()
  calculator.Hide()
  buyoutWarning.Hide()
end

local EVENTS = {}
EVENTS['AUCTION_HOUSE_SHOW'] = function()
  onShow()
end

EVENTS['AUCTION_HOUSE_CLOSED'] = function()
  onClosed()
end

local function searchItemInAH(bagID, slotID)
  -- It is possible for this call to return nil and then result in an GET_ITEM_INFO_RECEIVED event but
  -- that case is unlikely since we already have the bags visible and it takes a while for the player
  -- to physically click on items etc.
  local item = C_Container.GetContainerItemLink(bagID, slotID)
  if item then
    local itemName = '"'..select(1, GetItemInfo(item))..'"'

    BrowseName:SetText(itemName)
    BrowseSearchButton:Click()
  end
end

local function quickAHSearch(containerFrame, itemFrameIndex)
  -- Throttle if needed
  local currentTime = time()
  if currentTime - lastAHSearchTime < AH_SEARCH_INTERVAL then
    return
  else
    lastAHSearchTime = currentTime
  end

  local bagID = containerFrame:GetID()
  local capacity = C_Container.GetContainerNumSlots(bagID)
  local slotID = 1 + (capacity - itemFrameIndex)

  if slotID >= 0 then
    searchItemInAH(bagID, slotID)
  end
end

local function hookContainerFrames()
  for container = 1, 5 do
    local containerFrame = _G['ContainerFrame'..container]

    for slot = 1, 20 do
      local buttonFrame = _G['ContainerFrame'..container..'Item'..slot]

      if buttonFrame then
        buttonFrame:HookScript('OnMouseUp', function(self, button)
          if _G['UIC_AHT_IsEnabled'] and button == 'MiddleButton'
            and _G['AuctionFrame'] and _G['AuctionFrame']:IsShown() and BrowseName:IsVisible()
          then
            quickAHSearch(containerFrame, slot)
          end
        end)
      end
    end
  end
end

AHTools = {}

AHTools.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AHTools', UIParent)
  mainFrame:Hide()

  buyoutWarning = BuyoutWarning.new()
  calculator = Calculator.new()

  lastAHSearchTime = time()

  hookContainerFrames()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AHTools.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)

  if _G['AuctionFrame'] and _G['AuctionFrame']:IsShown() then
    onShow()
  end
end

AHTools.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  onClosed()
end

return AHTools
