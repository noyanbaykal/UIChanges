--[[
UIChanges

Copyright (C) 2019 - 2025 Melik Noyan Baykal

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
  local percentage = manaMax > 0 and (mana / manaMax) or 0

  manaBar:SetValue(percentage)
  manaBar.value:SetText(mana)
  manaBar.percentage:SetText(math.ceil(100 * percentage)..'%')
  manaBar.numeric:SetText(mana..' / '..manaMax)
end

local EVENTS = {}
EVENTS['CVAR_UPDATE'] = function(eventName, value)
  if eventName == 'STATUS_TEXT_DISPLAY' then
    updateStatusTextStyle(value)
  end
end
EVENTS['UNIT_DISPLAYPOWER'] = function(unitTarget)
  if unitTarget == 'player' then
    setManaBarDisplay()
  end
end
EVENTS['UNIT_POWER_UPDATE'] = function(unitTarget, powerType)
  if unitTarget == 'player' and powerType == 'MANA' then
    setManaBarValue()
  end
end

local updateManaBar = function()
  local style = GetCVar('statusTextDisplay')
  setManaBarDisplay()
  updateStatusTextStyle(style)
  setManaBarValue()
end

local initializeManaBar = function()
  manaBarBorder = CreateFrame('Frame', 'UIC_DMB_MANA_BAR_BORDER', _G['PlayerFrameManaBar'], 'BackdropTemplate')
  manaBarBorder:SetBackdrop(C.BACKDROP_INFO(8, 1))
  manaBarBorder:SetBackdropColor(0, 0, 0, 1)
  manaBarBorder:SetSize(122, 16)
  manaBarBorder:SetPoint('LEFT', _G['PlayerFrameManaBar'], 'LEFT', 0, 0)
  manaBarBorder:SetPoint('TOP', _G['PlayerFrameManaBar'], 'BOTTOM', 0, 0)

  manaBar = CreateFrame('StatusBar', 'UIC_DMB_MANA_BAR', manaBarBorder)
  manaBar:SetSize(117, 12)
  manaBar:SetFrameStrata('HIGH')
  manaBar:SetMinMaxValues(0, 1.0)
  manaBar:SetPoint('LEFT', _G['PlayerFrameManaBar'], 'LEFT', 2, 0)
  manaBar:SetPoint('TOP', _G['PlayerFrameManaBar'], 'BOTTOM', 0, -2)
  manaBar:SetStatusBarTexture('Interface/TargetingFrame/UI-StatusBar')
  manaBar:SetStatusBarColor(0, 0, 1, 1)

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

  manaBarBorder:Hide()
  manaBar:Hide()

  updateManaBar()
end

local hideManaBar = function()
  manaBarBorder:Hide()
  manaBar:Hide()
  manaBar.value:Hide()
  manaBar.numeric:Hide()
  manaBar.percentage:Hide()
end

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
