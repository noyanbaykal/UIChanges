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
local L = UI_CHANGES_LOCALE

local warningFrame, singleBuyoutFrame

local SIZE_Y = 30

local CalculateSingleBuyout = function(count, buyout)
  if count == 1 then
    return nil
  end

  local buyoutText = WrapTextInColorCode(L.SINGLE_BUYOUT, 'FFFFFFFF')

  local singleCost = buyout / count
  singleCost = tonumber(string.format('%.2f', singleCost))

  return buyoutText..GetCoinTextureString(singleCost)
end

local UpdateWarning = function(index, warningLabel)
  if not index or not warningLabel then
    warningFrame:Hide()
    return
  end

  local relativeFrameX, relativeFrameY

  if singleBuyoutFrame:IsVisible() then
    relativeFrameX = singleBuyoutFrame
    relativeFrameY = singleBuyoutFrame
  else
    relativeFrameX = _G['AuctionFrame']
    relativeFrameY = _G['BrowseButton'..index]
  end

  warningFrame:ClearAllPoints()
  warningFrame:SetPoint('TOP', relativeFrameY, 'TOP', 0, 0)
  warningFrame:SetPoint('LEFT', relativeFrameX, 'RIGHT', 0, 0)
  C.UpdateWarningIcon(warningFrame, warningLabel)
  warningFrame:Show()
end

local UpdateSingleBuyout = function(index, singleBuyout)
  if not index or not singleBuyout then
    singleBuyoutFrame:Hide()
    return
  end

  singleBuyoutFrame:ClearAllPoints()
  singleBuyoutFrame:SetPoint('TOP', _G['BrowseButton'..index], 'TOP', 0, 0)
  singleBuyoutFrame:SetPoint('LEFT', _G['AuctionFrame'], 'RIGHT', 0, 0)
  
  singleBuyoutFrame.title:SetText(singleBuyout)
  singleBuyoutFrame:SetSize(singleBuyoutFrame.title:GetStringWidth() + 16, SIZE_Y)
  singleBuyoutFrame:Show()
end

local GenerateData = function(index)
  if not index then
    return nil, nil
  end

  local itemCountFrame = _G['BrowseButton'..index..'ItemCount']
  local count = 1

  if itemCountFrame:IsVisible() == true then
    count = itemCountFrame:GetText()
  end

  local bid = C.GetBidPrice(index)
  local buyout = C.GetBuyoutPrice(index)

  local singleBuyout = CalculateSingleBuyout(count, buyout)
  local warningLabel = C.CheckScam(bid, buyout)

  return singleBuyout, warningLabel
end

local InitializeFrames = function()
  singleBuyoutFrame = CreateFrame('Frame', 'UIC_HoverTooltipBuyout', _G['AuctionFrame'], 'BackdropTemplate')
  singleBuyoutFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  singleBuyoutFrame:SetBackdropColor(0, 0, 0, 1)
  singleBuyoutFrame:SetSize(125, SIZE_Y)
  singleBuyoutFrame:SetFrameStrata('TOOLTIP')

  singleBuyoutFrame.title = singleBuyoutFrame:CreateFontString('UIC_Tooltip_title', 'OVERLAY', 'GameFontNormal')
  singleBuyoutFrame.title:SetPoint('TOP', 0, -10)

  singleBuyoutFrame:Hide()

  warningFrame = C.CreateWarningFrame('UIC_HoverTooltipWarning')
end

local Stub = function()
  local stub = {}
  
  function stub.Update()
  end

  function stub.Hide()
  end

  return stub
end

HoverTooltip = {}

HoverTooltip.new = function(isTBC)
  if isTBC then
    return Stub()
  end

  local self = {}

  InitializeFrames()

  function self.Update()
    local hoveredIndex = nil

    for i = 1, C.AH_ENTRY_COUNT do
      local browseButton = _G['BrowseButton'..i]
  
      if MouseIsOver(browseButton) and browseButton:IsVisible() then
        hoveredIndex = i
        break
      end
    end

    local singleBuyout, warningLabel = GenerateData(hoveredIndex)

    UpdateSingleBuyout(hoveredIndex, singleBuyout)
    UpdateWarning(hoveredIndex, warningLabel)
  end

  function self.Hide()
    singleBuyoutFrame:Hide()
    warningFrame:Hide()
  end

  return self
end

return HoverTooltip
