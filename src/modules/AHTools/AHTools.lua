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

local _, addonTable = ...

local C = addonTable.C

local SELL_FRAME_NAMES = {
  'ItemSellFrame',
  'CommoditiesSellFrame',
}

-- Forward declaring components
local mainFrame, buyoutWarning, calculator, vendorPriceFrame

local AH_SEARCH_INTERVAL = 0.3 -- Seconds
local oldAH = LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_CATACLYSM and WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT
local oldContainers = WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
local hookedContainerButtons = {} -- The new bag frames cannot be accessed directly like the old ones, so we need to keep track of them.
local loadedAH = false
local lastAHSearchTime

local function updateVendorPrice(sellFrame)
  local item = sellFrame and sellFrame:GetItem()

  if not (item and item:IsValid() and sellFrame:IsShown()) then
    vendorPriceFrame:Hide()
    return
  end

  local itemLink = C_Item.GetItemLink(item)
  if not itemLink then
    vendorPriceFrame:Hide()
    return
  end

  local sellPrice = select(11, C_Item.GetItemInfo(itemLink))

  vendorPriceFrame:ClearAllPoints()
  vendorPriceFrame:SetPoint('TOP', sellFrame.ItemDisplay, 'BOTTOM', 8, 0)

  local newText = ITEM_UNSELLABLE

  if sellPrice and sellPrice > 0 then
    newText = SELL_PRICE .. ': ' .. C_CurrencyInfo.GetCoinTextureString(sellPrice)
  end

  vendorPriceFrame.priceText:SetText(newText)

  vendorPriceFrame:Show()
end

local function setupSellPriceDisplay()
  vendorPriceFrame = CreateFrame('Frame', 'UIC_AHT_VENDOR_PRICE_FRAME', AuctionHouseFrame, 'BackdropTemplate')
  vendorPriceFrame:SetSize(180, 24)
  vendorPriceFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  vendorPriceFrame:SetBackdropColor(0, 0, 0)
  vendorPriceFrame:Hide()

  vendorPriceFrame.priceText = vendorPriceFrame:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
  vendorPriceFrame.priceText:SetPoint('CENTER')

  for _, sellFrameName in ipairs(SELL_FRAME_NAMES) do
    local sellFrame = AuctionHouseFrame[sellFrameName]

    hooksecurefunc(sellFrame, 'SetItem', function(self)
        updateVendorPrice(self)
    end)

    -- To handle switches between the sell frames
    sellFrame:HookScript('OnShow', function(self)
        updateVendorPrice(self)
    end)

    sellFrame:HookScript('OnHide', function()
        vendorPriceFrame:Hide()
    end)
  end
end

-- Use the , key to quickly list an item in the new AH
local function hookKeys()
  mainFrame:EnableKeyboard(true)
  mainFrame:SetPropagateKeyboardInput(true)

  mainFrame:SetScript('OnKeyDown', function(self, key)
    if key == ',' and AuctionHouseFrame then
      for _, sellFrameName in ipairs(SELL_FRAME_NAMES) do
        local sellFrame = AuctionHouseFrame[sellFrameName]

        if sellFrame then
          local postButton = sellFrame.PostButton

          if postButton and postButton:IsVisible() and postButton:IsEnabled() and not InCombatLockdown() then
            postButton:Click()
          end
        end
      end
    end
  end)

  mainFrame:Show()
end

local function hookClicks()
  if oldAH then
    buyoutWarning.LoadedAH()
    calculator.LoadedAH()
  else
    hookKeys()
    setupSellPriceDisplay()
  end

  loadedAH = true
end

local function onShow()
  -- The first time the AH is shown, we'll hook into the button onClicks
  if loadedAH == false then
    hookClicks()
  end

  if oldAH and AuctionFrame and AuctionFrame:IsShown() then
    calculator.Show()
  end
end

local function onClosed()
  if oldAH then
    calculator.Hide()
    buyoutWarning.Hide()
  end
end

local EVENTS = {}

EVENTS['AUCTION_HOUSE_SHOW'] = onShow

EVENTS['AUCTION_HOUSE_CLOSED'] = onClosed

local function searchItemInAH(bagID, slotID)
  -- It is possible for this call to return nil and then result in an GET_ITEM_INFO_RECEIVED event but
  -- that case is unlikely since we already have the bags visible and it takes a while for the player
  -- to physically click on items etc.
  local item = C_Container.GetContainerItemLink(bagID, slotID)
  if item then
    local itemName = '"'..select(1, C_Item.GetItemInfo(item))..'"'

    if oldAH then
      BrowseName:SetText(itemName)
      BrowseSearchButton:Click()
    else
      AuctionHouseFrame.SearchBar.SearchBox:SetText(itemName)
      AuctionHouseFrame.SearchBar.SearchButton:Click()
    end
  end
end

local function onMouseUpCallback(button, bagID, slotID)
  local shouldAct = UIChanges_Profile['UIC_AHT_IsEnabled'] and button == 'MiddleButton'

  local oldFramesVisible = AuctionFrame and AuctionFrame:IsShown() and BrowseName:IsVisible()
  local newFramesVisible = AuctionHouseFrame and AuctionHouseFrame.BrowseResultsFrame:IsShown()

  if shouldAct and (oldFramesVisible or newFramesVisible) then
    -- Throttle if needed
    local currentTime = time()
    if currentTime - lastAHSearchTime < AH_SEARCH_INTERVAL then
      return
    else
      lastAHSearchTime = currentTime
    end

    searchItemInAH(bagID, slotID)
  end
end

local function hookNewContainers()
  hooksecurefunc(ContainerFrameItemButtonMixin, 'OnLoad', function(outerSelf)
    outerSelf:HookScript('OnMouseUp', function(innerSelf, button)
      local bagID = innerSelf:GetBagID()
      local slotID = innerSelf:GetID()

      onMouseUpCallback(button, bagID, slotID)
    end)
  end)
end

local function hookOldContainers()
  for container = 1, 5 do
    local containerFrame = _G['ContainerFrame'..container]

    for slot = 1, 20 do
      local buttonFrame = _G['ContainerFrame'..container..'Item'..slot]

      if buttonFrame then
        buttonFrame:HookScript('OnMouseUp', function(self, button)
          local bagID = containerFrame:GetID()
          local capacity = C_Container.GetContainerNumSlots(bagID)
          local slotID = 1 + (capacity - slot)

          if slotID >= 0 then
            onMouseUpCallback(button, bagID, slotID)
          end
        end)
      end
    end
  end
end

local AHTools = {}

AHTools.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AHTools', UIParent)
  mainFrame:Hide()

  if oldAH then
    buyoutWarning = addonTable.BuyoutWarning.new()
    calculator = addonTable.Calculator.new()
  end

  lastAHSearchTime = time()

  if oldContainers then
    hookOldContainers()
  else
    hookNewContainers()
  end

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AHTools.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AHTools.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  onClosed()
end

addonTable.AHTools = AHTools
