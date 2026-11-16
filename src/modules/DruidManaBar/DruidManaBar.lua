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

local L = addonTable.L
local C = addonTable.C

local mainFrame, manaBarBorder, manaBar

local updateStatusTextStyle = function(style)
  if style == 'BOTH' then
    manaBar.value:Show()
    manaBar.numeric:Hide()
    manaBar.percentage:ClearAllPoints()
    manaBar.percentage:SetPoint('LEFT', 2, 0)
    manaBar.percentage:Show()
  elseif style == 'NONE' then
    manaBar.value:Hide()
    manaBar.numeric:Hide()
    manaBar.percentage:Hide()
  elseif style == 'PERCENT' then
    manaBar.value:Hide()
    manaBar.numeric:Hide()
    manaBar.percentage:ClearAllPoints()
    manaBar.percentage:SetPoint('CENTER', 0, 0)
    manaBar.percentage:Show()
  elseif style == 'NUMERIC' then
    manaBar.value:Hide()
    manaBar.numeric:Show()
    manaBar.percentage:Hide()
  end
end

local setManaBarDisplay = function()
  local powerType, _ = UnitPowerType('player')

  if powerType ~= Enum.PowerType.Mana then
    manaBarBorder:Show()
    manaBar:Show()
  else
    manaBarBorder:Hide()
    manaBar:Hide()
  end
end

local setManaBarValue = function()
  local mana = UnitPower('player', Enum.PowerType.Mana)
  local manaMax = UnitPowerMax('player', Enum.PowerType.Mana)
  local percentage = UnitPowerPercent('player', Enum.PowerType.Mana, false, CurveConstants.ScaleTo100)

  manaBar:SetValue(percentage)
  manaBar.value:SetText(mana)
  manaBar.percentage:SetText(string.format("%.0f%%", percentage))
  manaBar.numeric:SetText(mana .. ' / ' .. manaMax)
end

local updateManaBar = function()
  local style = GetCVar('statusTextDisplay')

  setManaBarDisplay()
  updateStatusTextStyle(style)
  setManaBarValue()
end

local initializeManaBar = function()
  local isForever = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

  local parentFrame
  local width
  local height

  if isForever then
    parentFrame = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar
    width = 124
    height = 14
  else
    parentFrame = PlayerFrameManaBar
    width = 122
    height = 16
  end

  manaBarBorder = CreateFrame('Frame', 'UIC_DMB_MANA_BAR_BORDER', parentFrame, 'BackdropTemplate')
  manaBarBorder:SetBackdrop(C.BACKDROP_INFO(8, 1))
  manaBarBorder:SetBackdropColor(0, 0, 0, 1)
  manaBarBorder:SetSize(width, height)
  manaBarBorder:SetPoint('LEFT', parentFrame, 'LEFT', 0, 0)

  manaBar = CreateFrame('StatusBar', 'UIC_DMB_MANA_BAR', manaBarBorder)
  manaBar:SetSize(width - 5, height - 4)
  manaBar:SetFrameStrata('HIGH')
  manaBar:SetMinMaxValues(0, 100)
  manaBar:SetPoint('LEFT', parentFrame, 'LEFT', 2, 0)
  manaBar:SetStatusBarTexture('Interface/TargetingFrame/UI-StatusBar')
  manaBar:SetStatusBarColor(0, 0, 1, 1)

  if isForever then
    manaBarBorder:SetPoint('BOTTOM', PlayerName, 'TOP', 0, 5)
    manaBar:SetPoint('BOTTOM', PlayerName, 'TOP', 0, 7)
  else
    manaBarBorder:SetPoint('TOP', parentFrame, 'BOTTOM', 0, 0)
    manaBar:SetPoint('TOP', parentFrame, 'BOTTOM', 0, -2)
  end

  manaBar.value = manaBar:CreateFontString('UIC_DMB_VALUE', 'OVERLAY', 'TextStatusBarText')
  manaBar.value:SetPoint('RIGHT', -2, 0)
  manaBar.value:SetJustifyH('RIGHT')
  manaBar.value:Hide()

  manaBar.numeric = manaBar:CreateFontString('UIC_DMB_NUMERIC', 'OVERLAY', 'TextStatusBarText')
  manaBar.numeric:SetPoint('CENTER', 0, 0)
  manaBar.numeric:SetJustifyH('CENTER')
  manaBar.numeric:SetTextScale(0.92)
  manaBar.numeric:Hide()

  manaBar.percentage = manaBar:CreateFontString('UIC_DMB_PERCENTAGE', 'OVERLAY', 'TextStatusBarText')
  manaBar.percentage:SetPoint('CENTER', 0, 0)
  manaBar.percentage:Hide()

  updateManaBar()

  manaBarBorder:Hide()
  manaBar:Hide()
end

local hideManaBar = function()
  manaBarBorder:Hide()
  manaBar:Hide()
  manaBar.value:Hide()
  manaBar.numeric:Hide()
  manaBar.percentage:Hide()
end

local function checkPowerUpdate(unitTarget, powerType)
  if unitTarget == 'player' and powerType == 'MANA' then
    setManaBarValue()
  end
end

local EVENTS = {}
EVENTS['CVAR_UPDATE'] = function(eventName, value)
  if eventName == 'statusTextDisplay' then
    updateStatusTextStyle(value)
  end
end

EVENTS['UNIT_DISPLAYPOWER'] = function(unitTarget)
  if unitTarget == 'player' then
    setManaBarDisplay()
  end
end

EVENTS['UNIT_POWER_UPDATE'] = checkPowerUpdate

EVENTS['UNIT_POWER_FREQUENT'] = checkPowerUpdate

local DruidManaBar = {}

DruidManaBar.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_DruidManaBar', UIParent)
  mainFrame:Hide()

  initializeManaBar()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

DruidManaBar.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)

  updateManaBar()
end

DruidManaBar.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)

  hideManaBar()
end

addonTable.DruidManaBar = DruidManaBar
