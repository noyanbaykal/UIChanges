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

local C = addonTable.C

local mainFrame, targetNameFrame, playerName, castBarFrame, targetNameFrameOffsetY

local lastCastGuid = nil
local lastTargetName = nil
local isChanneling = false
local isNoCastTime = false

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
  castBarFrame = _G['PlayerCastingBarFrame']
  targetNameFrameOffsetY = 20
else
  castBarFrame = _G['CastingBarFrame']
  targetNameFrameOffsetY = -24
end

local gameFontColor = {} -- Yellow
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local gameFontGreenColor = {}
gameFontGreenColor[1], gameFontGreenColor[2], gameFontGreenColor[3], gameFontGreenColor[4] = _G['GameFontGreen']:GetTextColor()

local gameFontRedColor = {}
gameFontRedColor[1], gameFontRedColor[2], gameFontRedColor[3], gameFontRedColor[4] = _G['GameFontRed']:GetTextColor()

local gameFontWhiteColor = {}
gameFontWhiteColor[1], gameFontWhiteColor[2], gameFontWhiteColor[3], gameFontWhiteColor[4] = _G['GameFontWhite']:GetTextColor()

local hideTargetNameFrame = function()
  targetNameFrame.text:SetText('')
  targetNameFrame:Hide()
end

local determineTargetNameColor = function(target, spellID)
  if target == playerName then
    return gameFontColor
  end

  local isHelpful = C_Spell.IsSpellHelpful(spellID)
  local isHarmful = C_Spell.IsSpellHarmful(spellID)

  if isHelpful and not isHarmful then
    return gameFontGreenColor
  elseif not isHelpful and isHarmful then
    return gameFontRedColor
  end

  return gameFontWhiteColor 
end

local showTargetNameFrame = function(target, spellID)
  if not target then
    return
  end

  targetNameFrame.text:SetText(target)

  local newWidth = math.ceil(targetNameFrame.text:GetWidth()) + 12
  targetNameFrame:SetWidth(newWidth)

  local colors = determineTargetNameColor(target, spellID)
  targetNameFrame.text:SetTextColor(colors[1], colors[2], colors[3], colors[4])

  targetNameFrame:Show()
end

local handleSent = function(unit, target, castGUID, spellID)
  if unit == 'player' then
    local spellName = UnitCastingInfo('player') -- This returns a value only if there is an ongoing hardcast

    if spellName then
      return -- Trying to cast another spell will not interrupt an ongoing hardcast
    end

    local spellInfo = C_Spell.GetSpellInfo(spellID)
    local castTime = spellInfo and spellInfo.castTime or nil

    isNoCastTime = castTime == 0 and true or false -- Unable to distinguish instant vs channel start yet

    if isNoCastTime then
      showTargetNameFrame(target, spellID)
      lastCastGuid = nil
      lastTargetName = nil
    else
      lastCastGuid = castGUID
      lastTargetName = target
    end
  end
end

-- The 'unitTarget' arguments here refer to the casting unit, not the targeted unit
local handleChannelStart = function(unitTarget, castGUID, spellID)
  if unitTarget == 'player' then
    isChanneling = true
    isNoCastTime = false
  end
end

local handleChannelStop = function(unitTarget, castGUID, spellID)
  if unitTarget == 'player' then
    isChanneling = false

    if not isNoCastTime then
      hideTargetNameFrame()
    end
  end
end

local handleStart = function(unitTarget, castGUID, spellID)
  if unitTarget == 'player' then
    if lastCastGuid == castGUID then
      showTargetNameFrame(lastTargetName, spellID)

      lastCastGuid = nil
      lastTargetName = nil
    end
  end
end

local handleStop = function(unitTarget)
  if unitTarget == 'player' then
    isNoCastTime = false
    lastCastGuid = nil
    lastTargetName = nil

    hideTargetNameFrame()
  end
end

local handleSuccess = function(unitTarget)
  if unitTarget == 'player' and not isChanneling then
    if isNoCastTime then
      C_Timer.NewTimer(1.2, function () handleStop(unitTarget) end)
      return
    end

    handleStop(unitTarget)
  end
end

local EVENTS = {}

EVENTS['UNIT_SPELLCAST_SENT'] = handleSent

EVENTS['UNIT_SPELLCAST_CHANNEL_START'] = handleChannelStart

EVENTS['UNIT_SPELLCAST_CHANNEL_STOP'] = handleChannelStop

EVENTS['UNIT_SPELLCAST_START'] = handleStart

EVENTS['UNIT_SPELLCAST_STOP'] = handleStop

EVENTS['UNIT_SPELLCAST_FAILED'] = handleStop

EVENTS['UNIT_SPELLCAST_FAILED_QUIET'] = handleStop

EVENTS['UNIT_SPELLCAST_INTERRUPTED'] = handleStop

EVENTS['UNIT_SPELLCAST_SUCCEEDED'] = handleSuccess

local anchorTargetNameFrame = function()
  targetNameFrame:SetPoint('CENTER', castBarFrame, 'CENTER', 0, targetNameFrameOffsetY)
end

local resetTargetNameFrameLocation = function()
  UIChanges_Profile['UIC_STD_FrameInfo'] = {}

  targetNameFrame:SetUserPlaced(false)
  targetNameFrame:ClearAllPoints()
  
  anchorTargetNameFrame()
end

local initializeTargetNameFrame = function()
  local frameInfoKey = 'UIC_STD_FrameInfo'
  local anchoringCallback = anchorTargetNameFrame
  local width = 120
  local height = 20
  local edgeSize = 8
  local backdropColorTable = {0, 0, 0}

  targetNameFrame = CreateFrame('Frame', 'UIC_STD_TargetNameFrame', UIParent, 'BackdropTemplate')
  C.InitializeMoveableFrame(targetNameFrame, frameInfoKey, anchoringCallback, width, height, edgeSize, backdropColorTable)

  targetNameFrame.text = targetNameFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  targetNameFrame.text:SetPoint('CENTER', targetNameFrame, 'CENTER', 0, 1)
  targetNameFrame.text:SetTextColor(1, 1, 1, 1)
  targetNameFrame.text:SetScale(1)
  targetNameFrame.text:SetText('')
end

local SpellTargetDisplay = {}

SpellTargetDisplay.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_SpellTargetDisplay', UIParent)
  mainFrame:Hide()

  playerName = UnitName('player')

  initializeTargetNameFrame()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

SpellTargetDisplay.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

SpellTargetDisplay.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  hideTargetNameFrame()
end

SpellTargetDisplay.Update = function()
  anchorTargetNameFrame()
end

SpellTargetDisplay.ResetTargetNameFrameLocation = function()
  resetTargetNameFrameLocation()
end

addonTable.SpellTargetDisplay = SpellTargetDisplay
