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

local warningFrame, buyoutWarningText

local BROWSE_BUTTON_FRAMES

local COUNT_BROWSE_FRAMES = 8

local MULTIPLIER_GOLD = 10000
local MULTIPLIER_SILVER = 100

local SCAM_RATIO = 8
local SUSPICIOUS_RATIO = 2
local SCAM_TEXT = 'Scam'
local SUSPICIOUS_TEXT = 'Warning'

local getBidPrice = function(i)
  local lookup = BROWSE_BUTTON_FRAMES[i]

  local gold = lookup.bidGold:GetText()
  local silver = lookup.bidSilver:GetText()
  local copper = lookup.bidCopper:GetText()

  return gold * MULTIPLIER_GOLD + silver * MULTIPLIER_SILVER + copper
end

local getBuyoutPrice = function(i)
  local lookup = BROWSE_BUTTON_FRAMES[i]

  if not lookup.buyoutFrame:IsVisible() then
    return nil
  end

  local gold = lookup.buyoutGold:GetText() or 0
  local silver = lookup.buyoutSilver:GetText() or 0
  local copper = lookup.buyoutCopper:GetText()

  return gold * MULTIPLIER_GOLD + silver * MULTIPLIER_SILVER + copper
end

local checkScam = function(bid, buyout)
  if buyout == nil then
    return nil
  end

  local ratio = buyout / bid

  if ratio >= SCAM_RATIO then
    return SCAM_TEXT
  elseif ratio >= SUSPICIOUS_RATIO then
    return SUSPICIOUS_TEXT
  else
    return nil
  end
end

local setWarning = function()
  local r = 1
  local g = 1
  local b = 0

  if buyoutWarningText == SCAM_TEXT then
    warningFrame.texture:SetVertexColor(1, 0, 0)
    g = 0
  else
    warningFrame.texture:SetVertexColor(1, 1, 1)
  end

  warningFrame:SetBackdropBorderColor(r, g, b)

  if _G['UIC_AHT_IsEnabled'] == true then
    warningFrame:Show()
  end
end

local onBrowseSelect = function(self, _, left, right)
  local indexString = string.sub(self:GetName(), left, right)
  local selectedBrowseFrameIndex = tonumber(indexString)

  local bid = getBidPrice(selectedBrowseFrameIndex)
  local buyout = getBuyoutPrice(selectedBrowseFrameIndex)

  buyoutWarningText = checkScam(bid, buyout)

  if not buyoutWarningText then
    warningFrame:Hide()
  else
    setWarning()
  end
end

local hookAHFrames = function()
  for i = 1, COUNT_BROWSE_FRAMES do
    local button = _G['BrowseButton'..i]
    local item = _G['BrowseButton'..i..'Item']

    button:HookScript('OnClick', function(self, buttonName)
      onBrowseSelect(self, buttonName, -1)
    end)

    item:HookScript('OnClick', function(self, buttonName)
      onBrowseSelect(self, buttonName, -5, -5)
    end)
  end

  _G['BrowseBuyoutButton']:HookScript('OnEnable', function()
    if buyoutWarningText and _G['UIC_AHT_IsEnabled'] == true then
      warningFrame:Show()
    end
  end)

  _G['BrowseBuyoutButton']:HookScript('OnDisable', function()
    warningFrame:Hide()
  end)

  _G['AuctionFrameTab2']:HookScript('OnClick', function()
    warningFrame:Hide()
  end)

  _G['AuctionFrameTab3']:HookScript('OnClick', function()
    warningFrame:Hide()
  end)
end

local populateBrowseButtonLookup = function()
  BROWSE_BUTTON_FRAMES = {}

  for i = 1, COUNT_BROWSE_FRAMES do
    local table = {}
    table['bidGold'] = _G['BrowseButton'..i..'MoneyFrameGoldButtonText']
    table['bidSilver'] = _G['BrowseButton'..i..'MoneyFrameSilverButtonText']
    table['bidCopper'] = _G['BrowseButton'..i..'MoneyFrameCopperButtonText']
    table['buyoutFrame'] = _G[ 'BrowseButton'..i..'BuyoutFrame']
    table['buyoutGold'] = _G['BrowseButton'..i..'BuyoutFrameMoneyGoldButtonText']
    table['buyoutSilver'] = _G['BrowseButton'..i..'BuyoutFrameMoneySilverButtonText']
    table['buyoutCopper'] = _G['BrowseButton'..i..'BuyoutFrameMoneyCopperButtonText']

    BROWSE_BUTTON_FRAMES[i] = table
  end
end

local setWarningFramePosition = function()
  local buyoutTextFrame = _G['BrowseBuyoutButtonText']
  local buyoutTextOffsetX = buyoutTextFrame:GetWidth() / 2
  local warningOffsetX = buyoutTextOffsetX - (warningFrame:GetWidth() / 2)

  warningFrame:ClearAllPoints()
  warningFrame:SetPoint('TOP', _G['AuctionFrameTab1'], 'TOP', 0, -2)
  warningFrame:SetPoint('LEFT', buyoutTextFrame, 'LEFT', warningOffsetX - 2, 0)
end

local createWarningFrame = function(frameName)
  warningFrame = CreateFrame('Frame', frameName, _G['AuctionFrame'], 'BackdropTemplate')
  warningFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  warningFrame:SetBackdropColor(0, 0, 0)
  warningFrame:SetSize(30, 30)
  warningFrame:SetFrameStrata('TOOLTIP')
  warningFrame:Hide()

  warningFrame.texture = warningFrame:CreateTexture(frameName..'_Texture', 'ARTWORK')
  warningFrame.texture:SetTexture('Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew')
  warningFrame.texture:SetPoint('CENTER', warningFrame, 'CENTER', 0, -1)
  warningFrame.texture:SetSize(24, 24)

  return warningFrame
end

local BuyoutWarning = {}

BuyoutWarning.new = function()
  local self = {}

  warningFrame = createWarningFrame('UIC_BuyoutWarning')

  function self.LoadedAH()
    setWarningFramePosition()
    populateBrowseButtonLookup()
    hookAHFrames()
  end

  function self.Hide()
    warningFrame:Hide()
  end

  return self
end

sharedTable.BuyoutWarning = BuyoutWarning
