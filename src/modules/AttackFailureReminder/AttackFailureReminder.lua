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

local mainFrame, errorFrame, breathFrame, attackTimer, breathTimer, breathValues

local ERROR_FAILURE = 50
local ERROR_DIRECTION = 254 -- Wrong melee direction
local ERROR_RANGE_MELEE = 255
local ERROR_DIRECTION_WOTLK = 260
local ERROR_RANGE_MELEE_WOTLK = 261
local ERROR_RANGE_SPELL = 363

local SPELL_ID_SHOOT_BOW = 2480
local SPELL_ID_SHOOT_WAND = 5019
local SPELL_ID_SHOOT_GUN = 7918
local SPELL_ID_SHOOT_CROSSBOW = 7919

local TIMER_INTERVAL = 4 -- Seconds
local BREATH_TIMER_INTERVAL = 1 -- Seconds

local showNoResourceReminder = function()
  return _G['UIC_AFR_NoResource']
end

local MessageMap = {
  [ERR_BADATTACKPOS] = true,
  [ERR_BADATTACKFACING] = true,
  [SPELL_FAILED_UNIT_NOT_INFRONT] = true,
  [SPELL_FAILED_MOVING] = true,
  [ERR_OUT_OF_RANGE] = true,
  [ACTION_SPELL_INTERRUPT] = true,
  [SPELL_FAILED_TOO_CLOSE] = true,
  [INTERRUPTED] = true,
  [LOSS_OF_CONTROL_DISPLAY_INTERRUPT] = true,
  [LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT] = true,
  [SPELL_FAILED_INTERRUPTED] = true,
  [SPELL_FAILED_INTERRUPTED_COMBAT] = true,
  [ERR_TOO_FAR_TO_INTERACT] = true,
  [ERR_SPELL_COOLDOWN] = true,
  [ERR_ABILITY_COOLDOWN] = true,
  [ERR_USE_TOO_FAR] = true,
  [SPELL_FAILED_LINE_OF_SIGHT ] = true,
  [SPELL_FAILED_TRY_AGAIN] = true,
  [ERR_OUT_OF_RAGE] = showNoResourceReminder,
  [OUT_OF_RAGE] = showNoResourceReminder,
  [ERR_OUT_OF_ENERGY] = showNoResourceReminder,
  [OUT_OF_ENERGY] = showNoResourceReminder,
  [ERR_OUT_OF_MANA] = showNoResourceReminder,
  [OUT_OF_MANA] = showNoResourceReminder,
  ['PLAYER_REGEN_DISABLED'] = function() return _G['UIC_AFR_EnteredCombat'] end
}

local isDamageTaken = function(type)
  return type == 'DODGE' or type == 'BLOCK' or type == 'WOUND' or type == 'PARRY'
end

local isShootType = function(spellID)
  return spellID == SPELL_ID_SHOOT_BOW or spellID == SPELL_ID_SHOOT_CROSSBOW or
    spellID == SPELL_ID_SHOOT_GUN or spellID == SPELL_ID_SHOOT_WAND
end

local isInterruptedMessage = function(message)
  return message == SPELL_FAILED_MOVING or
    message == INTERRUPTED or
    message == LOSS_OF_CONTROL_DISPLAY_INTERRUPT or
    message == LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT or
    message == SPELL_FAILED_INTERRUPTED or
    message == SPELL_FAILED_INTERRUPTED_COMBAT
end

local setErrorFrame = function(errorType, message)
  local size = 40
  local offsetX = 0
  local offsetY = 0
  local textureName
  
  if errorType == ERROR_RANGE_MELEE or errorType == ERROR_RANGE_MELEE_WOTLK then
    textureName = 'Interface\\CURSOR\\UnableAttack'
  elseif errorType == ERROR_DIRECTION  or errorType == ERROR_DIRECTION_WOTLK then
    textureName = 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete'
    size = 52
  elseif errorType == ERROR_RANGE_SPELL or message == ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS then
    textureName = 'Interface\\CURSOR\\UnableCast'
    offsetX = 1
    offsetY = -2
  elseif message == ERR_TOO_FAR_TO_INTERACT or message == ERR_USE_TOO_FAR then
    textureName = 'Interface\\CURSOR\\UnableInteract'
    offsetX = 1
    offsetY = -2
  elseif errorType == ERROR_FAILURE then
    if message == SPELL_FAILED_UNIT_NOT_INFRONT then
      textureName = 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete'
      size = 52
    elseif message == SPELL_FAILED_TOO_CLOSE then
      textureName = 'Interface\\CURSOR\\UnableCrosshairs'
    elseif isInterruptedMessage(message) then
      textureName = 'Interface\\CURSOR\\UnableUI-Cursor-Move'
    elseif message == SPELL_FAILED_LINE_OF_SIGHT then
      textureName = 'Interface\\ICONS\\INV_Misc_Eye_01'
    elseif message == SPELL_FAILED_TRY_AGAIN then
      textureName = 'Interface\\CURSOR\\UnableGatherHerbs'
    end
  elseif message == 'PLAYER_REGEN_DISABLED' then
    textureName = 'Interface\\PVPFrame\\Icon-Combat'
  elseif message == ERR_SPELL_COOLDOWN or message == ERR_ABILITY_COOLDOWN then
    textureName = 'Interface\\ICONS\\INV_Misc_PocketWatch_01'
  elseif message == ERR_OUT_OF_MANA or message == OUT_OF_MANA then
    textureName = 'Interface\\ICONS\\Spell_Shadow_ManaBurn'
  elseif message == ERR_OUT_OF_RAGE or message == OUT_OF_RAGE then
    textureName = 'Interface\\ICONS\\Ability_Racial_BloodRage'
  elseif message == ERR_OUT_OF_ENERGY or message == OUT_OF_ENERGY then
    textureName = 'Interface\\ICONS\\ClassIcon_Rogue'
  elseif message == ERR_OUT_OF_RANGE then
    textureName = 'Interface\\CURSOR\\UnableCrosshairs'
  end

  if textureName then
    errorFrame.texture:SetPoint('CENTER', errorFrame, 'CENTER', offsetX, offsetY)
    errorFrame.texture:SetSize(size, size)
    errorFrame.texture:SetTexture(textureName)
    errorFrame:Show()

    if _G['UIC_AFR_PlaySound'] == true then
      PlaySound(8959) -- RAID_WARNING
    end
  end
end

local updateBreathFrame = function()
  if not breathValues or breathValues[3] > 0 then
    breathFrame:Hide()
    return
  elseif breathValues[3] == 0 then
    return
  end

  local maxSeconds = breathValues[2]
  local secondsleft = math.max(breathValues[1] + breathValues[3], 0)
  
  breathValues[1] = secondsleft

  local index = 1
  for i = 1, 3 do
    if _G['MirrorTimer'..i..'Text']:GetText() == BREATH_LABEL then
      index = i
      break
    end
  end

  local r, g, b = 1, 1, 1
  if secondsleft <= 10 then
    r, g, b = 1, 0, 0
  elseif (maxSeconds / secondsleft) > 2 then
    r, g, b = 1, 1, 0
  end

  breathFrame:SetPoint('LEFT', _G['MirrorTimer'..index], 'LEFT', -45, 0)
  breathFrame:SetPoint('TOP', _G['MirrorTimer'..index], 'TOP', 0, 8)

  breathFrame.title:SetTextColor(r, g, b)
  breathFrame.title:SetText(secondsleft)

  breathFrame:Show()
end

local breathStop = function()
  if breathTimer and not breathTimer:IsCancelled() then
    breathTimer:Cancel()
  end

  breathValues = nil

  updateBreathFrame()
end

local breathStart = function(value, maxValue, scale, paused)
  if breathTimer and not breathTimer:IsCancelled() then
    breathTimer:Cancel()
  end

  local secondsleft = math.floor((value / 1000) / math.abs(scale))
  local maxSeconds = math.floor(maxValue / 1000)

  breathValues = {secondsleft - scale, maxSeconds, scale} -- The initial secondsleft value needs to be padded with 1 scale

  updateBreathFrame()

  if paused ~= 1 then
    breathTimer = C_Timer.NewTicker(BREATH_TIMER_INTERVAL, updateBreathFrame)
  end
end

local stopTimer = function()
  if attackTimer and not attackTimer:IsCancelled() then
    attackTimer:Cancel()
  end

  errorFrame:Hide()
end

local combatEvent = function(unitTarget, event, flagText, amount, schoolMask)
  if unitTarget == 'target' and isDamageTaken(event) then
    stopTimer()
  end
end

local spellCastSuccess = function(unitTarget, castGUID, spellID)
  if unitTarget == 'player' and isShootType(spellID) then
    stopTimer()
  end
end

local isRelevantMessage = function(message)
  local lookup = MessageMap[message]

  if lookup == nil then
    return false
  elseif type(lookup) == 'function' then
    return lookup()
  else
    return lookup
  end
end

local gotUIErrorMessage = function(errorType, message)
  if isRelevantMessage(message) then
    stopTimer()
    attackTimer = C_Timer.NewTicker(TIMER_INTERVAL, stopTimer)
    setErrorFrame(errorType, message)
  end
end

local errorFrameAnchoringTable = {}
errorFrameAnchoringTable['TOPLEFT'] = function()
  errorFrame:SetPoint('LEFT', _G['TargetFrame'], 'LEFT', 2, 0)
  errorFrame:SetPoint('BOTTOM', _G['TargetFramePortrait'], 'TOP', 0, 5)
end
errorFrameAnchoringTable['TOP'] = function()
  local x = (_G['TargetFrameTextureFrame']:GetRight() - _G['TargetFrameTextureFrame']:GetLeft()) / 4
  
  errorFrame:SetPoint('LEFT', _G['TargetFrame'], 'LEFT', x, 0)
  errorFrame:SetPoint('BOTTOM', _G['TargetFramePortrait'], 'TOP', 0, 5)
end
errorFrameAnchoringTable['TOPRIGHT'] = function()
  errorFrame:SetPoint('RIGHT', _G['TargetFramePortrait'], 'RIGHT', 0)
  errorFrame:SetPoint('BOTTOM', _G['TargetFramePortrait'], 'TOP', 0, 5)
end
errorFrameAnchoringTable['RIGHT'] = function()
  errorFrame:SetPoint('LEFT', _G['TargetFrame'], 'RIGHT', -10, 0)
end
errorFrameAnchoringTable['BOTTOMRIGHT'] = function()
  errorFrame:SetPoint('RIGHT', _G['TargetFramePortrait'], 'RIGHT', 0)
  errorFrame:SetPoint('TOP', _G['TargetFramePortrait'], 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['BOTTOM'] = function()
  local x = (_G['TargetFrameTextureFrame']:GetRight() - _G['TargetFrameTextureFrame']:GetLeft()) / 4

  errorFrame:SetPoint('LEFT', _G['TargetFrame'], 'LEFT', x, 0)
  errorFrame:SetPoint('TOP', _G['TargetFramePortrait'], 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['BOTTOMLEFT'] = function()
  errorFrame:SetPoint('LEFT', _G['TargetFrame'], 'LEFT', 2, 0)
  errorFrame:SetPoint('TOP', _G['TargetFramePortrait'], 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['LEFT'] = function()
  errorFrame:SetPoint('RIGHT', _G['TargetFrame'], 'LEFT', -10, 6)
end

local anchorErrorFrame = function()
  if InCombatLockdown() then
    return
  end

  local anchorDirection = C.ENUM_ANCHOR_OPTIONS[_G['UIC_AFR_TargetFrame']][2]

  errorFrame:ClearAllPoints()

  if anchorDirection == nil then
    local uiErrorsFrame = _G['UIErrorsFrame']
    local offsetX = (uiErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)
    errorFrame:SetPoint('BOTTOM', uiErrorsFrame, 'TOP', 0, 15)
    errorFrame:SetPoint('LEFT', uiErrorsFrame, 'LEFT', offsetX, 0)
  else
    errorFrameAnchoringTable[anchorDirection]()
  end
end

local EVENTS = {}
EVENTS['UI_ERROR_MESSAGE'] = function(...)
  gotUIErrorMessage(...)
end

EVENTS['PLAYER_REGEN_DISABLED'] = function()
  gotUIErrorMessage(nil, 'PLAYER_REGEN_DISABLED')
end

EVENTS['UNIT_SPELLCAST_SUCCEEDED'] = function(...)
  spellCastSuccess(...)
end

EVENTS['UNIT_COMBAT'] = function(...)
  combatEvent(...)
end

EVENTS['PLAYER_TARGET_CHANGED'] = function()
  stopTimer()
end

EVENTS['MIRROR_TIMER_START'] = function(timerName, value, maxValue, scale, paused, timerLabel)
  if timerName == 'BREATH' then
    breathStart(value, maxValue, scale, paused)
  end
end

EVENTS['MIRROR_TIMER_STOP'] = function(timerName)
  if timerName == 'BREATH' then
    breathStop()
  end
end

local initializeBreathFrame = function()
  breathFrame = CreateFrame('Frame', 'UIC_AFR_BREATH', _G['MirrorTimer1'], 'BackdropTemplate')
  breathFrame:SetSize(32, 32)
  breathFrame:SetFrameStrata('TOOLTIP')
  breathFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  breathFrame:SetBackdropColor(0, 0, 0, 1)

  breathFrame.title = breathFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  breathFrame.title:SetPoint('CENTER', 0, 0)
  breathFrame.title:SetJustifyH('RIGHT')

  breathFrame:Hide()
end

local initializeErrorFrame = function()
  errorFrame = CreateFrame('Frame', 'UIC_AttackFailureReminder_Error', UIParent, 'BackdropTemplate')
  errorFrame:SetSize(56, 56)
  errorFrame:SetFrameStrata('DIALOG')
  errorFrame:SetBackdrop(C.BACKDROP_INFO(16, 4))
  errorFrame:SetBackdropColor(0, 0, 0)
  errorFrame:SetBackdropBorderColor(1, 0, 0)

  errorFrame.texture = errorFrame:CreateTexture('UIC_AttackFailureReminder_Error_Texture', 'ARTWORK')

  anchorErrorFrame()
  errorFrame:Hide()
end

AttackFailureReminder = {}

AttackFailureReminder.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_AttackFailureReminder', UIParent)
  mainFrame:Hide()

  initializeErrorFrame()
  initializeBreathFrame()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AttackFailureReminder.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AttackFailureReminder.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  stopTimer()
end

AttackFailureReminder.Update = function()
  anchorErrorFrame()
end

return AttackFailureReminder
