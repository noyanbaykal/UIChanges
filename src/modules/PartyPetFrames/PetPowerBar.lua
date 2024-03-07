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

PetPowerBar = {}

-- This class isn't a singleton, things need to be defined within new
PetPowerBar.new = function(index)
  local self = {}

  -- Initialization
  local petReference = 'partypet'..index
  local healthBar = _G['PartyMemberFrame'..index..'PetFrameHealthBar']

  local powerFrame = CreateFrame('Frame', 'PartyMemberFrame'..index..'PetFramePowerBar', healthBar)
  powerFrame:SetFrameStrata('LOW')
  powerFrame:SetPoint('TOP', healthBar, 'BOTTOM', 0, -0.3)
  powerFrame:SetPoint('LEFT', healthBar, 'LEFT', 0, 0)
  powerFrame.texture = powerFrame:CreateTexture(nil, 'BACKGROUND')
  powerFrame.texture:SetAllPoints(powerFrame)
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
  
  local function getPowerBarDrawWidth()
    local power = UnitPower(petReference)
    local powerMax = UnitPowerMax(petReference)
    
    if powerMax == nil or powerMax <= 0 or power == nil then
      return nil
    end
  
    local percentage = power * 100 / powerMax
    if percentage < 0 then
      percentage = 0
    elseif percentage > 100 then
      percentage = 100
    end

    local width = healthBar:GetWidth()
    local offset = width * 0.04 -- The bar offset is used to better position the power bar inside the existing StatusBar texture
  
    return C.RoundToPixelCount((width - offset) * percentage / 100)
  end
  -- ~Helper functions for displaying the power bar

  function self.Update()
    local drawWidth = getPowerBarDrawWidth()

    if drawWidth == nil then
      powerFrame.texture:SetAlpha(0)
      return
    end

    local r, g, b = getPowerRGB()
    
    powerFrame:SetSize(drawWidth, healthBar:GetHeight())
    powerFrame.texture:SetColorTexture(r, g, b)
    powerFrame.texture:SetAlpha(1)
  end

  return self
end

return PetPowerBar
