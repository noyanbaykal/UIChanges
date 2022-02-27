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

UI_CHANGES_CONSTANTS.MODULE_VARIABLES = {
  'UIC_AHT_IsEnabled',
  'UIC_AFR_IsEnabled',
  'UIC_PA_IsEnabled',
}

UI_CHANGES_CONSTANTS.MODULES = {}
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[1]] = {}
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[1]]['frame'] = nil -- Frames will be set by UIChanges.lua
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[1]]['label'] = 'AHT'
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[1]]['title'] = 'AH Tooltips'

UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[2]] = {}
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[2]]['frame'] = nil
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[2]]['label'] = 'AFR'
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[2]]['title'] = 'Attack Failure Reminder'

UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[3]] = {}
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[3]]['frame'] = nil
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[3]]['label'] = 'PA'
UI_CHANGES_CONSTANTS.MODULES[UI_CHANGES_CONSTANTS.MODULE_VARIABLES[3]]['title'] = 'Ping Announcer'

UI_CHANGES_CONSTANTS.REGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:RegisterEvent(event)
  end
end

UI_CHANGES_CONSTANTS.UNREGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:UnregisterEvent(event)
  end
end

UI_CHANGES_CONSTANTS.BACKDROP_INFO = function(edgeSize, insetSize)
  return {
    bgFile = "Interface/Tooltips/UI-Tooltip-Background", 
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
    edgeSize = edgeSize, 
    insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize }
  }
end

-- AHTooltips
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

UI_CHANGES_CONSTANTS.CreateWarningFrame = function(frameName)
  local warningFrame = CreateFrame('Frame', frameName, _G['AuctionFrame'], 'BackdropTemplate')
  warningFrame:SetBackdrop(UI_CHANGES_CONSTANTS.BACKDROP_INFO(8, 1))
  warningFrame:SetBackdropColor(0, 0, 0)
  warningFrame:SetSize(30, 30)
  warningFrame:SetFrameStrata('TOOLTIP')
  warningFrame:Hide()

  warningFrame.texture = warningFrame:CreateTexture(frameName..'_Texture', 'ARTWORK')
  warningFrame.texture:SetTexture('Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew')
  warningFrame.texture:SetPoint('CENTER', warningFrame, 'CENTER', 0, 0)
  warningFrame.texture:SetSize(24, 24)

  return warningFrame
end

UI_CHANGES_CONSTANTS.UpdateWarningIcon = function(warningFrame, warningLabel)
  local r = 1
  local g = 1
  local b = 0

  if warningLabel and warningLabel == UI_CHANGES_CONSTANTS.SCAM_TEXT then
    warningFrame.texture:SetVertexColor(1, 0, 0)
    g = 0
  else
    warningFrame.texture:SetVertexColor(1, 1, 1)
  end

  warningFrame:SetBackdropBorderColor(r, g, b)
end
-- ~AHTooltips

return UI_CHANGES_CONSTANTS
