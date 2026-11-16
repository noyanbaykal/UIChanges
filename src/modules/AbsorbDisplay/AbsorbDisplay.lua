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

-- Unlike other modules, this one is split into two due to drastically different modes of operation between clients.
-- There is no nice API access to the shield amount before MoP, so those clients will continue working with the AbsorbDisplayBeforeMop file.
if LE_EXPANSION_LEVEL_CURRENT < LE_EXPANSION_MISTS_OF_PANDARIA and WOW_PROJECT_ID ~= WOW_PROJECT_CAMELOT then
  addonTable.AbsorbDisplay = addonTable.AbsorbDisplayBeforeMop
  
  return
end

local mainFrame, shieldFrame, shieldAmount

local updateDisplay = function()
  local amount = UnitGetTotalAbsorbs('player')

  shieldFrame.value:SetText(BreakUpLargeNumbers(amount))
end

local anchorToDefaultPosition = function()
  shieldFrame:SetUserPlaced(false)

  local anchor = PlayerLevelText
  local offsetY = -5

  if WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
    anchor = PlayerName
    offsetY = -2
  end

  shieldFrame:SetPoint('BOTTOM', anchor, 'BOTTOM', 0, offsetY)
  shieldFrame:SetPoint('LEFT', anchor, 'RIGHT', 7, 0)
end

local resetDisplayLocation = function()
  UIChanges_Profile['UIC_AD_FrameInfo'] = {}

  shieldFrame:ClearAllPoints()
  
  anchorToDefaultPosition()
end

local initializeFrames = function()
  mainFrame = CreateFrame('Frame', 'UIC_AbsorbDisplay', UIParent)
  mainFrame:Hide()

  local shieldColor = {1, 1, 0.353, 1}
  local shieldWidth = 56
  local shieldHeight = 18

  shieldFrame = CreateFrame('Frame', 'UIC_AD_Shield_Frame', UIParent, 'BackdropTemplate')
  C.InitializeMoveableFrame(shieldFrame, 'UIC_AD_FrameInfo', anchorToDefaultPosition, shieldWidth, shieldHeight, 2, shieldColor)

  shieldFrame.value = shieldFrame:CreateFontString('UIC_AD_ShieldFrameValue', 'OVERLAY', 'TextStatusBarTextLarge')
  shieldFrame.value:SetPoint('CENTER', shieldFrame, 'CENTER', 0, 0)
  shieldFrame.value:SetJustifyH('CENTER')
  shieldFrame.value:SetTextColor(1, 1, 1)
  shieldFrame.value:Show()
end

local EVENTS = {}

EVENTS['UNIT_ABSORB_AMOUNT_CHANGED'] = updateDisplay

local AbsorbDisplay = {}

AbsorbDisplay.Initialize = function()
  initializeFrames()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AbsorbDisplay.Enable = function()
  updateDisplay()
  shieldFrame:Show()

  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AbsorbDisplay.Disable = function()
  shieldFrame:Hide()
  
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
end

AbsorbDisplay.ResetDisplayLocation = function()
  resetDisplayLocation()
end

addonTable.AbsorbDisplay = AbsorbDisplay
