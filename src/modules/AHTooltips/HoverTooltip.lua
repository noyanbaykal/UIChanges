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

local warningFrame, singleCostFrame

local labelBid = WrapTextInColorCode(L.SINGLE_BID, 'FFFFFFFF')
local labelBuyout = WrapTextInColorCode(L.SINGLE_BUYOUT, 'FFFFFFFF')
local SIZE_Y = 30

local calculateSingleCost = function(count, bid, buyout)
  if count == 1 then
    return nil, nil
  end

  local singleBid = math.floor(bid / count)

  local singleBuyout
  if buyout then
    singleBuyout = math.floor(buyout / count)
  end

  return singleBid, singleBuyout
end

local updateWarning = function(index, warningLabel)
  if not index or not warningLabel then
    warningFrame:Hide()
    return
  end

  if InCombatLockdown() then
    return
  end

  local relativeFrameX, relativeFrameY

  if singleCostFrame:IsVisible() then
    relativeFrameX = singleCostFrame
    relativeFrameY = singleCostFrame
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

local formatCostString = function(singleBid, singleBuyout)
  local textureBid = GetCoinTextureString(singleBid)

  if not singleBuyout then
    return labelBid..textureBid
  end

  local textureBuyout = GetCoinTextureString(singleBuyout)

  return string.format('%s\n%s', labelBid..textureBid, labelBuyout..textureBuyout)
end

local updateSingleCostFrame = function(index, singleBid, singleBuyout)
  if not index or not singleBid then
    singleCostFrame:Hide()
    return
  end

  singleCostFrame:ClearAllPoints()
  singleCostFrame:SetPoint('TOP', _G['BrowseButton'..index], 'TOP', 0, 0)
  singleCostFrame:SetPoint('LEFT', _G['AuctionFrame'], 'RIGHT', 0, 0)

  singleCostFrame.title:SetText(formatCostString(singleBid, singleBuyout))
  singleCostFrame:SetSize(singleCostFrame.title:GetStringWidth() + 16, SIZE_Y)
  singleCostFrame:Show()
end

local generateData = function(index)
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

  local singleBid, singleBuyout = calculateSingleCost(count, bid, buyout)
  local warningLabel = C.CheckScam(bid, buyout)

  return singleBid, singleBuyout, warningLabel
end

local initializeFrames = function()
  singleCostFrame = CreateFrame('Frame', 'UIC_HoverTooltipBuyout', _G['AuctionFrame'], 'BackdropTemplate')
  singleCostFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  singleCostFrame:SetBackdropColor(0, 0, 0, 1)
  singleCostFrame:SetFrameStrata('TOOLTIP')
  singleCostFrame:SetSize(125, SIZE_Y)

  singleCostFrame.title = singleCostFrame:CreateFontString('UIC_Tooltip_title', 'OVERLAY', 'GameFontNormalSmall2')
  singleCostFrame.title:SetPoint('CENTER', 0, 0)
  singleCostFrame.title:SetJustifyH('RIGHT')

  singleCostFrame:Hide()

  warningFrame = C.CreateWarningFrame('UIC_HoverTooltipWarning')
end

HoverTooltip = {}

HoverTooltip.new = function()
  local self = {}

  initializeFrames()

  function self.Update()
    local hoveredIndex = nil

    for i = 1, 8 do
      local browseButton = _G['BrowseButton'..i]
  
      if MouseIsOver(browseButton) and browseButton:IsVisible() then
        hoveredIndex = i
        break
      end
    end

    local singleBid, singleBuyout, warningLabel = generateData(hoveredIndex)

    updateSingleCostFrame(hoveredIndex, singleBid, singleBuyout)
    updateWarning(hoveredIndex, warningLabel)
  end

  function self.Hide()
    singleCostFrame:Hide()
    warningFrame:Hide()
  end

  return self
end

return HoverTooltip
