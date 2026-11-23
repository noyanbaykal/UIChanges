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

local TIMER_INTERVAL = 4 -- Seconds

local mirrorTimer = MirrorTimer1
if LE_EXPANSION_LEVEL_CURRENT > LE_EXPANSION_MISTS_OF_PANDARIA or WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
  mirrorTimer = MirrorTimerContainer
end

local mainFrame, errorFrame, errorTimer

local ErrorMap = {
  ['PLAYER_REGEN_DISABLED'] =               {'UIC_CR_CombatWarning',          'Interface\\ICONS\\Ability_DualWield'},
  [ERR_BADATTACKPOS] =                      {'UIC_CR_CombatRange',            'Interface\\CURSOR\\UnableAttack'},
  [ERR_BADATTACKFACING] =                   {'UIC_CR_CombatDirection',        'Interface\\GLUES\\CharacterSelect\\CharacterUndelete', 52},
  [ERR_OUT_OF_RANGE] =                      {'UIC_CR_CombatRange',            'Interface\\CURSOR\\UnableCrosshairs'},
  [ERR_SPELL_COOLDOWN] =                    {'UIC_CR_CombatCooldown',         'Interface\\ICONS\\INV_Misc_PocketWatch_01'},
  [ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS] =  {'UIC_CR_CombatInterrupted',      'Interface\\CURSOR\\UnableCast', nil, 1, -2},
  [ERR_OUT_OF_MANA] =                       {'UIC_CR_CombatNoResource',       'Interface\\ICONS\\Spell_Shadow_ManaBurn'},
  [ERR_OUT_OF_RAGE] =                       {'UIC_CR_CombatNoResource',       'Interface\\ICONS\\Ability_Racial_BloodRage'},
  [ERR_OUT_OF_ENERGY] =                     {'UIC_CR_CombatNoResource',       'Interface\\ICONS\\ClassIcon_Rogue'},
  [ERR_TOO_FAR_TO_INTERACT] =               {'UIC_CR_InteractionRange',       'Interface\\CURSOR\\UnableInteract', nil, 1, -2},
  [SPELL_FAILED_TRY_AGAIN] =                {'UIC_CR_GatheringFailure',       'Interface\\CURSOR\\UnableGatherHerbs'},
  [SPELL_FAILED_LINE_OF_SIGHT] =            {'UIC_CR_CombatLos',              'Interface\\ICONS\\INV_Misc_Eye_01'},
  [INTERRUPTED] =                           {'UIC_CR_CombatInterrupted',      'Interface\\CURSOR\\UnableUI-Cursor-Move'},
}

ErrorMap[SPELL_FAILED_UNIT_NOT_INFRONT] =             ErrorMap[ERR_BADATTACKFACING]
ErrorMap[SPELL_FAILED_TOO_CLOSE] =                    ErrorMap[ERR_OUT_OF_RANGE]
ErrorMap[ERR_ABILITY_COOLDOWN] =                      ErrorMap[ERR_SPELL_COOLDOWN]
ErrorMap[OUT_OF_MANA] =                               ErrorMap[ERR_OUT_OF_MANA]
ErrorMap[OUT_OF_RAGE] =                               ErrorMap[ERR_OUT_OF_RAGE]
ErrorMap[OUT_OF_ENERGY] =                             ErrorMap[ERR_OUT_OF_ENERGY]
ErrorMap[ERR_USE_TOO_FAR] =                           ErrorMap[ERR_TOO_FAR_TO_INTERACT]
ErrorMap[SPELL_FAILED_MOVING] =                       ErrorMap[INTERRUPTED]
ErrorMap[LOSS_OF_CONTROL_DISPLAY_INTERRUPT] =         ErrorMap[INTERRUPTED]
ErrorMap[LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT] =  ErrorMap[INTERRUPTED]
ErrorMap[SPELL_FAILED_INTERRUPTED] =                  ErrorMap[INTERRUPTED]
ErrorMap[SPELL_FAILED_INTERRUPTED_COMBAT] =           ErrorMap[INTERRUPTED]
ErrorMap[ACTION_SPELL_INTERRUPT] =                    ErrorMap[INTERRUPTED]

local setErrorFrame = function(textureName, playSound, size, offsetX, offsetY)
  size = size or 40
  offsetX = offsetX or 0
  offsetY = offsetY or 0

  errorFrame.texture:SetPoint('CENTER', errorFrame, 'CENTER', offsetX or 0, offsetY or 0)
  errorFrame.texture:SetSize(size, size)
  errorFrame.texture:SetTexture(textureName)
  errorFrame:Show()

  if playSound == true then
    PlaySound(12889) -- AlarmClockWarning3
  end
end

local stopErrorTimer = function()
  if errorTimer and not errorTimer:IsCancelled() then
    errorTimer:Cancel()
  end

  errorFrame:Hide()
end

local showUIErrorMessage = function(textureName, playSound, size, offsetX, offsetY)
  stopErrorTimer()
  errorTimer = C_Timer.NewTicker(TIMER_INTERVAL, stopErrorTimer)
  setErrorFrame(textureName, playSound, size, offsetX, offsetY)
end

local errorFrameAnchoringTable = {}
-- These have to be in the same order as in the ENUM_ANCHOR_OPTIONS. Skipping 1.
errorFrameAnchoringTable[2] = function() -- 'Top Left'
  errorFrame:SetPoint('LEFT', TargetFrame, 'LEFT', 0, 0)
  errorFrame:SetPoint('BOTTOM', TargetFrame, 'TOP', 0, 0)
end
errorFrameAnchoringTable[3] = function() -- 'Top'
  local offsetX = (TargetFrame:GetRight() - TargetFrame:GetLeft()) / 3

  errorFrame:SetPoint('LEFT', TargetFrame, 'LEFT', offsetX, 0)
  errorFrame:SetPoint('BOTTOM', TargetFrame, 'TOP', 0, 0)
end
errorFrameAnchoringTable[4] = function() -- 'Top Right'
  errorFrame:SetPoint('RIGHT', TargetFrame, 'RIGHT', 0, 0)
  errorFrame:SetPoint('BOTTOM', TargetFrame, 'TOP', 0, 0)
end
errorFrameAnchoringTable[5] = function() -- 'Right'
  errorFrame:SetPoint('LEFT', TargetFrame, 'RIGHT', 0, 0)
end
errorFrameAnchoringTable[6] = function() -- 'Bottom Right'
  errorFrame:SetPoint('RIGHT', TargetFrame, 'RIGHT', 0, 0)
  errorFrame:SetPoint('TOP', TargetFrame, 'BOTTOM', 0, 0)
end
errorFrameAnchoringTable[7] = function() -- 'Bottom'
  local offsetX = (TargetFrame:GetRight() - TargetFrame:GetLeft()) / 3

  errorFrame:SetPoint('LEFT', TargetFrame, 'LEFT', offsetX, 0, 0)
  errorFrame:SetPoint('TOP', TargetFrame, 'BOTTOM', 0, 0)
end
errorFrameAnchoringTable[8] = function() -- 'Bottom Left'
  errorFrame:SetPoint('LEFT', TargetFrame, 'LEFT', 0, 0)
  errorFrame:SetPoint('TOP', TargetFrame, 'BOTTOM', 0, 0)
end
errorFrameAnchoringTable[9] = function() -- 'Left'
  errorFrame:SetPoint('RIGHT', TargetFrame, 'LEFT', 0, 0)
end

local anchorToUIErrorsFrame = function()
  local offsetX = (UIErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)

  errorFrame:SetPoint('BOTTOM', UIErrorsFrame, 'BOTTOM', 0, -25)
  errorFrame:SetPoint('LEFT', UIErrorsFrame, 'LEFT', offsetX, 0)
end

local anchorErrorFrame = function()
  if InCombatLockdown() then
    return
  end

  local anchorDirection = UIChanges_Profile['UIC_CR_ErrorFrameAnchor']

  errorFrame:ClearAllPoints()

  if anchorDirection == 1 then
    C.SetupMoveableFrame(errorFrame, 'UIC_CR_ErrorFrameInfo', anchorToUIErrorsFrame)
  else
    errorFrame:EnableMouse(false)
    errorFrame:SetMovable(false)
    errorFrame:SetScript('OnMouseDown', function() end)
    errorFrame:SetScript('OnMouseUp', function() end)

    errorFrameAnchoringTable[anchorDirection]()
  end
end

local resetErrorFrameLocation = function()
  UIChanges_Profile['UIC_CR_ErrorFrameInfo'] = {}

  if UIChanges_Profile['UIC_CR_ErrorFrameAnchor'] == 1 then
    errorFrame:SetUserPlaced(false)
    anchorErrorFrame()
  end
end

local initializeErrorFrame = function()
  errorFrame = CreateFrame('Frame', 'UIC_CriticalReminders_Error', UIParent, 'BackdropTemplate')
  errorFrame:SetSize(56, 56)
  errorFrame:SetFrameStrata('DIALOG')
  errorFrame:SetBackdrop(C.BACKDROP_INFO(16, 4))
  errorFrame:SetBackdropColor(0, 0, 0)
  errorFrame:SetBackdropBorderColor(1, 0, 0)
  errorFrame:SetClampedToScreen(true)

  errorFrame.texture = errorFrame:CreateTexture('UIC_CriticalReminders_Error_Texture', 'ARTWORK')

  anchorErrorFrame()
  errorFrame:Hide()
end

local handleErrorMessage = function(_, message)
  if ErrorMap[message] == nil then
    return
  end
  
  local subsettingVariableName, textureName, size, offsetX, offsetY = unpack(ErrorMap[message])
  
  if UIChanges_Profile[subsettingVariableName] == 1 or not textureName then
    return
  end

  local playSound = UIChanges_Profile[subsettingVariableName] == 3

  showUIErrorMessage(textureName, playSound, size, offsetX, offsetY)
end

local EVENTS = {}
EVENTS['UI_ERROR_MESSAGE'] = handleErrorMessage

EVENTS['PLAYER_REGEN_DISABLED'] = function()
  handleErrorMessage(nil, 'PLAYER_REGEN_DISABLED')
end

EVENTS['PLAYER_REGEN_ENABLED'] = function()
  if errorFrame.texture:GetTexture() == 132147 then -- Ability_DualWield used when the player enters combat
    stopErrorTimer()
  end
end

local CriticalReminders = {}

CriticalReminders.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_CriticalReminders', UIParent)
  mainFrame:Hide()

  initializeErrorFrame()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

CriticalReminders.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

CriticalReminders.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  stopErrorTimer()
end

CriticalReminders.Update = function()
  anchorErrorFrame()
end

CriticalReminders.ResetErrorFrameLocation = function()
  resetErrorFrameLocation()
end

addonTable.CriticalReminders = CriticalReminders
