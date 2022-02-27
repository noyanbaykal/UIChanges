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

local ERROR_FAILURE = 50
local ERROR_DIRECTION = 254 -- Wrong melee direction
local ERROR_RANGE_MELEE = 255
local ERROR_RANGE_SPELL = 363
local ERROR_CANT_INTERACT = 825

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

local IsInterruptedMessage = function(message)
  return message == SPELL_FAILED_MOVING or
    message == INTERRUPTED or
    message == LOSS_OF_CONTROL_DISPLAY_INTERRUPT or
    message == LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT or
    message == SPELL_FAILED_INTERRUPTED or
    message == SPELL_FAILED_INTERRUPTED_COMBAT
end

local SetErrorFrame = function(errorType, message)
  local size = 40
  local offsetX = 0
  local offsetY = 0
  local textureName
  
  if errorType == ERROR_RANGE_MELEE then
    textureName = 'Interface\\CURSOR\\UnableAttack'
  elseif errorType == ERROR_DIRECTION then
    textureName = 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete'
    size = 52
  elseif errorType == ERROR_RANGE_SPELL then
    textureName = 'Interface\\CURSOR\\UnableCast'
    offsetX = 1
    offsetY = -2
  elseif errorType == ERROR_CANT_INTERACT and message == ERR_TOO_FAR_TO_INTERACT then
    textureName = 'Interface\\CURSOR\\UnableInteract'
    offsetX = 1
    offsetY = -2
  elseif errorType == ERROR_FAILURE then
    if message == SPELL_FAILED_UNIT_NOT_INFRONT then
      textureName = 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete'
      size = 52
    elseif message == SPELL_FAILED_TOO_CLOSE then
      textureName = 'Interface\\CURSOR\\UnableCrosshairs'
    elseif IsInterruptedMessage(message) then
      textureName = 'Interface\\CURSOR\\UnableUI-Cursor-Move'
    end
  end

  if textureName then
    errorFrame.texture:SetPoint('CENTER', errorFrame, 'CENTER', offsetX, offsetY)
    errorFrame.texture:SetSize(size, size)
    errorFrame.texture:SetTexture(textureName)
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
    message == ERR_OUT_OF_RANGE or
    message == ACTION_SPELL_INTERRUPT or
    message == SPELL_FAILED_TOO_CLOSE or
    message == INTERRUPTED or
    message == LOSS_OF_CONTROL_DISPLAY_INTERRUPT or
    message == LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT or
    message == SPELL_FAILED_INTERRUPTED or
    message == SPELL_FAILED_INTERRUPTED_COMBAT or
    message == ERR_TOO_FAR_TO_INTERACT
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
  StopTimer()
end

AttackFailureReminder = {}

AttackFailureReminder.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AttackFailureReminder', UIParent)
  mainFrame:Hide()

  errorFrame = CreateFrame('Frame', 'UIC_AttackFailureReminder_Error', UIParent, 'BackdropTemplate')
  errorFrame:SetSize(56, 56)
  errorFrame:SetFrameStrata('TOOLTIP')
  errorFrame:SetBackdrop(C.BACKDROP_INFO(16, 4));
  errorFrame:SetBackdropColor(0, 0, 0)
  errorFrame:SetBackdropBorderColor(1, 0, 0)
  errorFrame:ClearAllPoints()

  local uiErrorsFrame = _G['UIErrorsFrame']
  local offsetX = (uiErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)
  errorFrame:SetPoint('TOP', uiErrorsFrame, 'BOTTOM', 0, 0)
  errorFrame:SetPoint('LEFT', uiErrorsFrame, 'LEFT', offsetX, 0)
  errorFrame:Hide()

  errorFrame.texture = errorFrame:CreateTexture('UIC_AttackFailureReminder_Error_Texture', 'ARTWORK')

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AttackFailureReminder.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AttackFailureReminder.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  StopTimer()
end

return AttackFailureReminder
