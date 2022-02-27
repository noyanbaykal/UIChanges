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

local C = UI_CHANGES_CONSTANTS

local warningFrame, buyoutWarningText

local SetWarning = function(index)
  if not index then
    return
  end

  local bid = C.GetBidPrice(index)
  local buyout = C.GetBuyoutPrice(index)
  local newWarning = C.CheckScam(bid, buyout)

  if newWarning then
    C.UpdateWarningIcon(warningFrame, newWarning)
  end

  buyoutWarningText = newWarning
end

local OnBrowseSelect = function(self, buttonName, left, right)
  local index = string.sub(self:GetName(), left, right)
  SetWarning(index)
end

local HookAHButtonClicks = function()
  for i = 1, C.AH_ENTRY_COUNT do
    local button = _G['BrowseButton'..i]
    local item = _G['BrowseButton'..i..'Item']

    button:HookScript('OnClick', function(self, buttonName)
      OnBrowseSelect(self, buttonName, -1)
    end)

    item:HookScript('OnClick', function(self, buttonName)
      OnBrowseSelect(self, buttonName, -5, -5)
    end)
  end
end

local SetWarningFramePosition = function()
  local buyoutTextFrame = _G['BrowseBuyoutButtonText']
  local buyoutTextOffsetX = buyoutTextFrame:GetWidth() / 2
  local warningOffsetX = buyoutTextOffsetX - (warningFrame:GetWidth() / 2)

  warningFrame:ClearAllPoints()
  warningFrame:SetPoint('TOP', _G['AuctionFrameTab1'], 'TOP', 0, -2)
  warningFrame:SetPoint('LEFT', buyoutTextFrame, 'LEFT', warningOffsetX - 2, 0)
end

BuyoutTooltip = {}

BuyoutTooltip.new = function()
  local self = {}
  
  warningFrame = C.CreateWarningFrame('UIC_BuyoutTooltip')

  function self.LoadedAH()
    HookAHButtonClicks()
    SetWarningFramePosition()
  end

  function self.Update()
    local isBrowse = _G['AuctionFrameBrowse']:IsVisible()

    if isBrowse and buyoutWarningText then
      warningFrame:Show()
    else
      self.Hide()
    end
  end

  function self.Hide(resetWarning)
    warningFrame:Hide()

    if resetWarning then
      buyoutWarningText = nil
    end
  end

  return self
end

return BuyoutTooltip
