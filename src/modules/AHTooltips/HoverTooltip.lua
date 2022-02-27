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

local SIZE_Y = 30

local CalculateSingleCost = function(count, bid, buyout)
  if count == 1 then
    return nil, nil
  end

  local singleBid = bid / count
  singleBid = tonumber(string.format('%.2f', singleBid))

  local singleBuyout = buyout / count
  singleBuyout = tonumber(string.format('%.2f', singleBuyout))

  local bidText = WrapTextInColorCode(L.SINGLE_BID, 'FFFFFFFF')..GetCoinTextureString(singleBid)
  local buyoutText = WrapTextInColorCode(L.SINGLE_BUYOUT, 'FFFFFFFF')..GetCoinTextureString(singleBuyout)

  return bidText, buyoutText
end

local UpdateWarning = function(index, warningLabel)
  if not index or not warningLabel then
    warningFrame:Hide()
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

local UpdateSingleCost = function(index, singleBid, singleBuyout)
  if not index or not singleBid then
    singleCostFrame:Hide()
    return
  end

  singleCostFrame:ClearAllPoints()
  singleCostFrame:SetPoint('TOP', _G['BrowseButton'..index], 'TOP', 0, 0)
  singleCostFrame:SetPoint('LEFT', _G['AuctionFrame'], 'RIGHT', 0, 0)
  
  -- TODO: pad the shorter label
  -- TODO: fit 2 lines into the set height while handling nil singleBuyout
  singleBuyout = singleBuyout or '' -- Buyout could be missing
  
  singleCostFrame.title:SetText(singleBid..'\n'..singleBuyout)



  singleCostFrame:SetSize(singleCostFrame.title:GetStringWidth() + 16, SIZE_Y)
  singleCostFrame:Show()
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

  local singleBid, singleBuyout = CalculateSingleCost(count, bid, buyout)
  local warningLabel = C.CheckScam(bid, buyout)

  return singleBid, singleBuyout, warningLabel
end

local InitializeFrames = function()
  singleCostFrame = CreateFrame('Frame', 'UIC_HoverTooltipBuyout', _G['AuctionFrame'], 'BackdropTemplate')
  singleCostFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  singleCostFrame:SetBackdropColor(0, 0, 0, 1)
  singleCostFrame:SetSize(125, SIZE_Y)
  singleCostFrame:SetFrameStrata('TOOLTIP')

  singleCostFrame.title = singleCostFrame:CreateFontString('UIC_Tooltip_title', 'OVERLAY', 'GameFontNormal')
  singleCostFrame.title:SetPoint('TOP', 0, -10)

  singleCostFrame:Hide()

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

    local singleBid, singleBuyout, warningLabel = GenerateData(hoveredIndex)

    UpdateSingleCost(hoveredIndex, singleBid, singleBuyout)
    UpdateWarning(hoveredIndex, warningLabel)
  end

  function self.Hide()
    singleCostFrame:Hide()
    warningFrame:Hide()
  end

  return self
end

return HoverTooltip
