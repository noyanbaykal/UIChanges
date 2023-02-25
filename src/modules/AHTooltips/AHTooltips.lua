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

-- These calls differ between classic era and wotlk
local ALIAS_GetContainerNumSlots
local ALIAS_GetContainerItemLink

local TIMER_INTERVAL = 0.08 -- Seconds
local AH_SEARCH_INTERVAL = 0.3 -- Seconds

-- Forward declaring modules
local mainFrame, hoverTooltip, buyoutTooltip, calculator
local trackingTimer
local lastAHSearchTime
local isWOTLK
local loadedAH = false

local function checkFrames()
  if hoverTooltip then
    hoverTooltip.Update()
  end
  
  buyoutTooltip.Update()
end

local function onShow()
  -- The first time the AH is shown, we'll hook into the button onClicks
  if loadedAH == false then
    buyoutTooltip.LoadedAH()
    calculator.LoadedAH()
    loadedAH = true
  end

  calculator.Show()
  
  trackingTimer = C_Timer.NewTicker(TIMER_INTERVAL, checkFrames)
end

local function hideTooltips()
  if hoverTooltip then
    hoverTooltip.Hide()
  end

  buyoutTooltip.Hide(true)
end

local function onClosed()
  if trackingTimer and trackingTimer:IsCancelled() ~= true then
    trackingTimer:Cancel()
  end

  calculator.Hide()

  hideTooltips()
end

local EVENTS = {}
EVENTS['AUCTION_HOUSE_SHOW'] = function(...)
  onShow(...)
end

EVENTS['AUCTION_HOUSE_CLOSED'] = function(...)
  onClosed(...)
end

EVENTS['AUCTION_ITEM_LIST_UPDATE'] = function()
  hideTooltips()
end

EVENTS['AUCTION_BIDDER_LIST_UPDATE'] = function()
  hideTooltips()
end

local function searchItemInAH(bagID, slotID)
  local item = ALIAS_GetContainerItemLink(bagID, slotID)
  if item then
    local itemName = select(1, GetItemInfo(item))

    if isWOTLK then
      itemName = '"'..itemName..'"'
    end
    
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
  local capacity = ALIAS_GetContainerNumSlots(bagID)
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

AHTooltips = {}

AHTooltips.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AHTooltips', UIParent)
  mainFrame:Hide()

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then -- This was added to TBCC sometime after release
    hoverTooltip = HoverTooltip.new()
  end

  buyoutTooltip = BuyoutTooltip.new()

  calculator = Calculator.new()

  if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    ALIAS_GetContainerNumSlots = C_Container.GetContainerNumSlots
    ALIAS_GetContainerItemLink = C_Container.GetContainerItemLink
    isWOTLK = true
  else
    ALIAS_GetContainerNumSlots = GetContainerNumSlots
    ALIAS_GetContainerItemLink = GetContainerItemLink
    isWOTLK = false
  end

  lastAHSearchTime = time()

  hookContainerFrames()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AHTooltips.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)

  if _G['AuctionFrame'] and _G['AuctionFrame']:IsShown() then
    onShow()
  end
end

AHTooltips.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  onClosed()
end

return AHTooltips
