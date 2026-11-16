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

local PetPowerBar = {}

-- This class isn't a singleton, things need to be defined within new
PetPowerBar.new = function(index)
  local self = {}

  -- Initialization
  local petReference = 'partypet'..index
  local healthBar = _G['PartyFrame']['MemberFrame'..index].PetFrame.HealthBar

  local powerFrame = CreateFrame('StatusBar', 'PartyMemberFrame'..index..'PetFramePowerBar', healthBar)
  powerFrame:SetStatusBarTexture('Interface/TargetingFrame/UI-StatusBar')
  powerFrame:SetPoint('TOP', healthBar, 'BOTTOM', 0, -1)
  powerFrame:SetPoint('LEFT', healthBar, 'LEFT', 1, 0)
  powerFrame:SetFrameStrata('MEDIUM')
  powerFrame:SetAlpha(1)

  local width = healthBar:GetWidth() - 2
  local height = healthBar:GetHeight()
  powerFrame:SetSize(width, height)

  powerFrame:Hide()
  -- ~Initialization

  -- Helper functions for displaying the power bar
  local function getPowerRGB()
    local petPowerType = UnitPowerType(petReference)
    local colors = PowerBarColor[petPowerType]
    if colors == nil then
      colors = PowerBarColor[0]
    end
  
    return colors.r, colors.g, colors.b
  end
  -- ~Helper functions for displaying the power bar

  function self.Update()
    local r, g, b = getPowerRGB()

    powerFrame:SetStatusBarColor(r, g, b)
    
    local power = UnitPower(petReference)
    local powerMax = UnitPowerMax(petReference)

    powerFrame:SetMinMaxValues(0, powerMax)
    powerFrame:SetValue(power)

    powerFrame:Show()
  end

  function self.Hide()
    powerFrame:Hide()
  end

  return self
end

addonTable.PetPowerBar = PetPowerBar
