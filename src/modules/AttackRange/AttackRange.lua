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

local mainFrame, errorFrame, attackTimer

-- Attack out of range or wrong direction or spellcast while moving
local ERROR_FAILURE = 50
local ERROR_DIRECTION = 254
local ERROR_RANGE_MELEE = 255
local ERROR_RANGE_SPELL = 363

local SPELL_ID_SHOOT_BOW = 2480
local SPELL_ID_SHOOT_WAND = 5019
local SPELL_ID_SHOOT_GUN = 7918
local SPELL_ID_SHOOT_CROSSBOW = 7919

local TIMER_INTERVAL = 4 -- Seconds

local IsDamageTaken = function(type)
  return type == 'DODGE' or type == 'BLOCK' or type == 'WOUND' or type == 'PARRY'
end

local IsShootType = function(spellID)
  return spellID == SPELL_ID_SHOOT_BOW or spellID == SPELL_ID_SHOOT_CROSSBOW or
    spellID == SPELL_ID_SHOOT_GUN or spellID == SPELL_ID_SHOOT_WAND
end

local IsAttackFailed = function(errorType, message)
  return
    errorType == ERROR_RANGE_MELEE or
    errorType == ERROR_RANGE_SPELL or
    errorType == ERROR_DIRECTION or
    (errorType == ERROR_FAILURE and message == SPELL_FAILED_UNIT_NOT_INFRONT)
end

local SetErrorFrame = function(errorType, message)
  local backdropBG
  
  if errorType == ERROR_FAILURE and message == SPELL_FAILED_MOVING then
    backdropBG = 'Interface\\CURSOR\\UnableUI-Cursor-Move'
  elseif errorType == ERROR_RANGE_MELEE or errorType == ERROR_RANGE_SPELL then
    backdropBG = 'Interface\\PVPFrame\\Icon-Combat'
  elseif errorType == ERROR_DIRECTION or errorType == ERROR_FAILURE then
    backdropBG = 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete'
  end

  if backdropBG then
    errorFrame:SetBackdrop(C.BACKDROP_INFO(backdropBG))
    errorFrame:SetBackdropBorderColor(1, 0, 0)
    errorFrame:Show()
  end
end

local StopTimer = function()
  if attackTimer and not attackTimer:IsCancelled() then
    attackTimer:Cancel()
  end

  errorFrame:Hide()
end

local CombatEvent = function(unitTarget, event, flagText, amount, schoolMask)
  if unitTarget == 'target' and IsDamageTaken(event) then
    StopTimer()
  end
end

local SpellCastSuccess = function(unitTarget, castGUID, spellID)
  if unitTarget == 'player' and IsShootType(spellID) then
    StopTimer()
  end
end

local IsAttackFailureMessage = function(message)
  return
    message == ERR_BADATTACKPOS or
    message == ERR_BADATTACKFACING or
    message == SPELL_FAILED_UNIT_NOT_INFRONT or
    message == SPELL_FAILED_MOVING or
    message == ERR_OUT_OF_RANGE 
end

local GotUIErrorMessage = function(errorType, message)
  if IsAttackFailureMessage(message) then
    StopTimer()
    attackTimer = C_Timer.NewTicker(TIMER_INTERVAL, StopTimer)
    SetErrorFrame(errorType, message)
  end
end

local EVENTS = {}
EVENTS['UI_ERROR_MESSAGE'] = function(...)
  GotUIErrorMessage(...)
end

EVENTS['UNIT_SPELLCAST_SUCCEEDED'] = function(...)
  SpellCastSuccess(...)
end

EVENTS['UNIT_COMBAT'] = function(...)
  CombatEvent(...)
end

EVENTS['PLAYER_TARGET_CHANGED'] = function()
  HideTooltips()
end

AttackRange = {}

AttackRange.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AttackRange', UIParent)
  mainFrame:Hide()

  errorFrame = CreateFrame('Frame', 'UIC_AttackRange_Error', UIParent, 'BackdropTemplate')
  errorFrame:SetSize(56, 56)
  errorFrame:SetFrameStrata('TOOLTIP')
  errorFrame:SetBackdropColor(0, 0, 0)
  errorFrame:SetBackdropBorderColor(1, 0, 0)
  errorFrame:ClearAllPoints()

  local uiErrorsFrame = _G['UIErrorsFrame']
  local offsetX = (uiErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)
  errorFrame:SetPoint('TOP', uiErrorsFrame, 'BOTTOM', 0, 0)
  errorFrame:SetPoint('LEFT', uiErrorsFrame, 'LEFT', offsetX, 0)
  errorFrame:Hide()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AttackRange.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AttackRange.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
end

return AttackRange
