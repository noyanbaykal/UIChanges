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

local mainFrame, targetNameFrame, playerName, uiChangeTimer

local lastCastGuid = nil
local lastTargetName = nil
local isChanneling = false
local isNoCastTime = false

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

-- The retail UI frames can no longer be anchored to right away like they used to and the visibility
-- behaviour of frames anchored to them have changed. Will anchor to the UI instead.
local anchorTargetNameFrame = function()
  targetNameFrame:SetUserPlaced(false)
  targetNameFrame:ClearAllPoints()

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    targetNameFrame:SetPoint('CENTER', _G['CastingBarFrame'], 'CENTER', 0, -24)
    return
  end

  if _G['MultiBarBottomLeft']:IsVisible() or _G['MultiBarBottomRight']:IsVisible() then
    targetNameFrame:SetPoint('CENTER', UI, 'CENTER', 0, -274)
  else
    targetNameFrame:SetPoint('CENTER', UI, 'CENTER', 0, -323)
  end
end

local handleSent = function(unit, target, castGUID, spellID)
  if unit == 'player' then
    local spellName = UnitCastingInfo('player')

    if spellName then -- Trying to cast another spell will not interrupt an ongoing hardcast
      return
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
local handleChannelStart = function(unitTarget, _, spellID)
  if unitTarget == 'player' then
    isChanneling = true
    isNoCastTime = false
  end
end

local handleChannelStop = function(unitTarget, _, spellID)
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
    local spellName = UnitCastingInfo('player')

    if spellName then -- The event was fired for a subsequent cast that did not go through
      return
    end

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

-- The default position will be altered based on the visiblity of the bottom left and bottom right actions bars.
-- Re-anchor whenever the action bar settings are changed.
local handleUIChange = function(cvarName)
  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and not targetNameFrame:IsUserPlaced() and cvarName == 'enableMultiActionBars' then
    if uiChangeTimer and not uiChangeTimer:IsCancelled() then
      uiChangeTimer:Cancel()
    end

    uiChangeTimer = C_Timer.NewTimer(1, anchorTargetNameFrame)
  end
end

-- In TBC classic and onwards, the initial anchoring might fail because the default ui frames might not be loaded yet.
-- This will do a second pass once we know the default ui frames are ready so we can check the presence of the bottom actionbars.
local handleDelayedSetup = function()
  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and not targetNameFrame:IsUserPlaced() then
    anchorTargetNameFrame()
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

EVENTS['CVAR_UPDATE'] = handleUIChange

EVENTS['PLAYER_ENTERING_WORLD'] = handleDelayedSetup

local resetTargetNameFrameLocation = function()
  UIChanges_Profile['UIC_STD_FrameInfo'] = {}

  targetNameFrame:ClearAllPoints()
  
  anchorTargetNameFrame()
end

local initializeTargetNameFrame = function()
  targetNameFrame = CreateFrame('Frame', 'UIC_STD_TargetNameFrame', UIParent, 'BackdropTemplate')
  C.InitializeMoveableFrame(targetNameFrame, 'UIC_STD_FrameInfo', anchorTargetNameFrame, 120, 20, 8, {0, 0, 0})

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

SpellTargetDisplay.ResetTargetNameFrameLocation = function()
  resetTargetNameFrameLocation()
end

addonTable.SpellTargetDisplay = SpellTargetDisplay
