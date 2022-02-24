--[[
UIChanges

Copyright (C) 2019 - 2022 Melik Noyan Baykal

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

-- All addons share the global namespace and global name conflicts are possible.
-- Bundling all constants in a single object to avoid possible conflicts.
UI_CHANGES_CONSTANTS = {}

UI_CHANGES_CONSTANTS.EVENT_AH_SHOW =          'AUCTION_HOUSE_SHOW'
UI_CHANGES_CONSTANTS.EVENT_AH_CLOSED =        'AUCTION_HOUSE_CLOSED'
UI_CHANGES_CONSTANTS.EVENT_AH_LIST_UPDATE =   'AUCTION_ITEM_LIST_UPDATE'
UI_CHANGES_CONSTANTS.EVENT_AH_BIDDER_UPDATE = 'AUCTION_BIDDER_LIST_UPDATE'

UI_CHANGES_CONSTANTS.TIMER_INTERVAL = 0.08 -- Seconds
UI_CHANGES_CONSTANTS.AH_ENTRY_COUNT = 8

UI_CHANGES_CONSTANTS.MULTIPLIER_GOLD = 10000
UI_CHANGES_CONSTANTS.MULTIPLIER_SILVER = 100

UI_CHANGES_CONSTANTS.SCAM_RATIO = 8
UI_CHANGES_CONSTANTS.SUSPICIOUS_RATIO = 2
UI_CHANGES_CONSTANTS.SCAM_TEXT = 'Scam'
UI_CHANGES_CONSTANTS.SUSPICIOUS_TEXT = 'Warning' 

UI_CHANGES_CONSTANTS.GetBidPrice = function(index)
  local gold = _G['BrowseButton'..index..'MoneyFrameGoldButtonText']:GetText()
  local silver = _G['BrowseButton'..index..'MoneyFrameSilverButtonText']:GetText()
  local copper = _G['BrowseButton'..index..'MoneyFrameCopperButtonText']:GetText()

  return gold * UI_CHANGES_CONSTANTS.MULTIPLIER_GOLD + silver * UI_CHANGES_CONSTANTS.MULTIPLIER_SILVER + copper
end

UI_CHANGES_CONSTANTS.GetBuyoutPrice = function(index)
  local gold = _G['BrowseButton'..index..'BuyoutFrameMoneyGoldButtonText']:GetText() or 0
  local silver = _G['BrowseButton'..index..'BuyoutFrameMoneySilverButtonText']:GetText() or 0
  local copper = _G['BrowseButton'..index..'BuyoutFrameMoneyCopperButtonText']:GetText()

  return gold * UI_CHANGES_CONSTANTS.MULTIPLIER_GOLD + silver * UI_CHANGES_CONSTANTS.MULTIPLIER_SILVER + copper
end

UI_CHANGES_CONSTANTS.CheckScam = function(bid, buyout)
  local ratio = buyout / bid

  if ratio >= UI_CHANGES_CONSTANTS.SCAM_RATIO then
    return UI_CHANGES_CONSTANTS.SCAM_TEXT
  elseif ratio >= UI_CHANGES_CONSTANTS.SUSPICIOUS_RATIO then
    return UI_CHANGES_CONSTANTS.SUSPICIOUS_TEXT
  else
    return nil
  end
end

local WARNING_BACKDROP_INFO = {
	bgFile = 'Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew',
	edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
 	edgeSize = 8,
}

UI_CHANGES_CONSTANTS.CreateWarningFrame = function(frameName)
  local warningFrame = CreateFrame('Frame', frameName, _G['AuctionFrame'], 'BackdropTemplate')
  warningFrame:SetBackdrop(WARNING_BACKDROP_INFO)
  warningFrame:SetSize(30, 30)
  warningFrame:SetFrameStrata('TOOLTIP')
  warningFrame:Hide()

  return warningFrame
end

UI_CHANGES_CONSTANTS.ReturnWarningBackdropColor = function(warningLabel)
  if warningLabel and warningLabel == UI_CHANGES_CONSTANTS.SCAM_TEXT then
    return 1, 0, 0
  else
    return 1, 1, 1
  end
end

return UI_CHANGES_CONSTANTS
