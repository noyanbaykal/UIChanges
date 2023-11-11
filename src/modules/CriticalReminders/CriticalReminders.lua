--[[
UIChanges

Copyright (C) 2019 - 2023 Melik Noyan Baykal

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

local ERROR_FAILURE = 51
local ERROR_DIRECTION = 262
local ERROR_RANGE_MELEE = 263
local ERROR_RANGE_SPELL = 363

local COMBAT_WARNING_TEXTURE_ID = 132147 -- Ability_DualWield

local TIMER_INTERVAL = 4 -- Seconds
local BREATH_TIMER_INTERVAL = 1 -- Seconds

local showCombatWarning = function()
  return _G['UIC_CR_CombatWarning']
end

local showGatheringFailure = function()
  return _G['UIC_CR_GatheringFailure']
end

local showNoLos = function()
  return _G['UIC_CR_CombatLos']
end

local showCombatDirection = function()
  return _G['UIC_CR_CombatDirection']
end

local showCombatRange = function()
  return _G['UIC_CR_CombatRange']
end

local showCombatInterrupted = function()
  return _G['UIC_CR_CombatInterrupted']
end

local showCombatCooldown = function()
  return _G['UIC_CR_CombatCooldown']
end

local showNoResource = function()
  return _G['UIC_CR_CombatNoResource']
end

local showInteractionRange = function()
  return _G['UIC_CR_InteractionRange']
end

local MessageMap = {
  -- Got in combat
  ['PLAYER_REGEN_DISABLED'] = showCombatWarning,
  -- Gathering failure
  [SPELL_FAILED_TRY_AGAIN] = showGatheringFailure,
  -- Combat LOS
  [SPELL_FAILED_LINE_OF_SIGHT] = showNoLos,
  -- Combat direction
  [ERR_BADATTACKFACING] = showCombatDirection,
  [SPELL_FAILED_UNIT_NOT_INFRONT] = showCombatDirection,
  -- Combat range
  [ERR_BADATTACKPOS] = showCombatRange,
  [ERR_OUT_OF_RANGE] = showCombatRange,
  [SPELL_FAILED_TOO_CLOSE] = showCombatRange,
  -- Combat interrupted
  [SPELL_FAILED_MOVING] = showCombatInterrupted,
  [ACTION_SPELL_INTERRUPT] = showCombatInterrupted,
  [INTERRUPTED] = showCombatInterrupted,
  [LOSS_OF_CONTROL_DISPLAY_INTERRUPT] = showCombatInterrupted,
  [LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT] = showCombatInterrupted,
  [SPELL_FAILED_INTERRUPTED] = showCombatInterrupted,
  [SPELL_FAILED_INTERRUPTED_COMBAT] = showCombatInterrupted,
  -- Combat cooldown
  [ERR_SPELL_COOLDOWN] = showCombatCooldown,
  [ERR_ABILITY_COOLDOWN] = showCombatCooldown,
  -- Combat no resource
  [ERR_OUT_OF_RAGE] = showNoResource,
  [OUT_OF_RAGE] = showNoResource,
  [ERR_OUT_OF_ENERGY] = showNoResource,
  [OUT_OF_ENERGY] = showNoResource,
  [ERR_OUT_OF_MANA] = showNoResource,
  [OUT_OF_MANA] = showNoResource,
  -- Interaction range
  [ERR_TOO_FAR_TO_INTERACT] = showInteractionRange,
  [ERR_USE_TOO_FAR] = showInteractionRange,
}

local isInterruptedMessage = function(message)
  return message == SPELL_FAILED_MOVING or
    message == INTERRUPTED or
    message == LOSS_OF_CONTROL_DISPLAY_INTERRUPT or
    message == LOSS_OF_CONTROL_DISPLAY_SCHOOL_INTERRUPT or
    message == SPELL_FAILED_INTERRUPTED or
    message == SPELL_FAILED_INTERRUPTED_COMBAT
end

-- Return signature is textureName, playSound, size, offsetX, offsetY
local checkError = function(errorType, message)
  if errorType == ERROR_RANGE_MELEE then
    return 'Interface\\CURSOR\\UnableAttack', _G['UIC_CR_CombatRange_Sound']
  end

  if errorType == ERROR_DIRECTION then
    return 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete', _G['UIC_CR_CombatDirection_Sound'], 52
  end

  if errorType == ERROR_RANGE_SPELL or message == ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS then
    return 'Interface\\CURSOR\\UnableCast', _G['UIC_CR_CombatInterrupted_Sound'], nil, 1, -2
  end

  if message == ERR_TOO_FAR_TO_INTERACT or message == ERR_USE_TOO_FAR then
    return 'Interface\\CURSOR\\UnableInteract', _G['UIC_CR_InteractionRange_Sound'], nil, 1, -2
  end

  if errorType == ERROR_FAILURE then
    if message == SPELL_FAILED_UNIT_NOT_INFRONT then
      return 'Interface\\GLUES\\CharacterSelect\\CharacterUndelete', _G['UIC_CR_CombatDirection_Sound'], 52
    elseif message == SPELL_FAILED_TOO_CLOSE then
      return 'Interface\\CURSOR\\UnableCrosshairs', _G['UIC_CR_CombatRange_Sound']
    elseif isInterruptedMessage(message) then
      return 'Interface\\CURSOR\\UnableUI-Cursor-Move', _G['UIC_CR_CombatInterrupted_Sound']
    elseif message == SPELL_FAILED_LINE_OF_SIGHT then
      return 'Interface\\ICONS\\INV_Misc_Eye_01', _G['UIC_CR_CombatLos_Sound']
    elseif message == SPELL_FAILED_TRY_AGAIN then
      return 'Interface\\CURSOR\\UnableGatherHerbs', _G['UIC_CR_GatheringFailure_Sound']
    end
  end

  if message == 'PLAYER_REGEN_DISABLED' then
    return 'Interface\\ICONS\\Ability_DualWield', _G['UIC_CR_CombatWarning_Sound']
  end

  if message == ERR_SPELL_COOLDOWN or message == ERR_ABILITY_COOLDOWN then
    return 'Interface\\ICONS\\INV_Misc_PocketWatch_01', _G['UIC_CR_CombatCooldown_Sound']
  end

  if message == ERR_OUT_OF_MANA or message == OUT_OF_MANA then
    return 'Interface\\ICONS\\Spell_Shadow_ManaBurn', _G['UIC_CR_CombatNoResource_Sound']
  end

  if message == ERR_OUT_OF_RAGE or message == OUT_OF_RAGE then
    return 'Interface\\ICONS\\Ability_Racial_BloodRage', _G['UIC_CR_CombatNoResource_Sound']
  end

  if message == ERR_OUT_OF_ENERGY or message == OUT_OF_ENERGY then
    return 'Interface\\ICONS\\ClassIcon_Rogue', _G['UIC_CR_CombatNoResource_Sound']
  end

  if message == ERR_OUT_OF_RANGE then
    return 'Interface\\CURSOR\\UnableCrosshairs', _G['UIC_CR_CombatRange_Sound']
  end

  return nil
end

local setErrorFrame = function(errorType, message)
  local textureName
  local playSound
  local size
  local offsetX
  local offsetY

  textureName, playSound, size, offsetX, offsetY = checkError(errorType, message)
  size = size or 40
  offsetX = offsetX or 0
  offsetY = offsetY or 0

  if textureName then
    errorFrame.texture:SetPoint('CENTER', errorFrame, 'CENTER', offsetX or 0, offsetY or 0)
    errorFrame.texture:SetSize(size, size)
    errorFrame.texture:SetTexture(textureName)
    errorFrame:Show()

    if playSound == true then
      PlaySound(12889) -- AlarmClockWarning3
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
  local secondsLeft = math.max(breathValues[1] + breathValues[3], 0)

  breathValues[1] = secondsLeft

  local index = 1
  for i = 1, 3 do
    if _G['MirrorTimer'..i..'Text']:GetText() == BREATH_LABEL then
      index = i
      break
    end
  end

  local r, g, b = 1, 1, 1
  if secondsLeft <= 10 then
    r, g, b = 1, 0, 0
  elseif (maxSeconds / secondsLeft) > 2 then
    r, g, b = 1, 1, 0
  end

  breathFrame:SetPoint('LEFT', _G['MirrorTimer'..index], 'LEFT', -45, 0)
  breathFrame:SetPoint('TOP', _G['MirrorTimer'..index], 'TOP', 0, 8)

  breathFrame.title:SetTextColor(r, g, b)
  breathFrame.title:SetText(secondsLeft)

  breathFrame:Show()

  if _G['UIC_CR_BreathWarning_Sound'] == true then
    local soundId

    if secondsLeft == 30 then
      soundId = 7256 -- NsabbeyBell
    elseif secondsLeft == 15 then
      soundId = 12867 -- AlarmClockWarning2
    elseif secondsLeft == 5 then
      soundId = 8959 -- RaidWarning
    end

    if soundId then
      PlaySound(soundId)
    end
  end
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

local stopAttackTimer = function()
  if attackTimer and not attackTimer:IsCancelled() then
    attackTimer:Cancel()
  end

  errorFrame:Hide()
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
    stopAttackTimer()
    attackTimer = C_Timer.NewTicker(TIMER_INTERVAL, stopAttackTimer)
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

local anchorToUIFrame = function()
  local uiErrorsFrame = _G['UIErrorsFrame']
  local offsetX = (uiErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)

  errorFrame:SetPoint('BOTTOM', uiErrorsFrame, 'TOP', 0, 15)
  errorFrame:SetPoint('LEFT', uiErrorsFrame, 'LEFT', offsetX, 0)
end

local anchorErrorFrame = function()
  if InCombatLockdown() then
    return
  end

  local anchorDirection = C.ENUM_ANCHOR_OPTIONS[_G['UIC_CR_ErrorFrameAnchor']][2]

  errorFrame:ClearAllPoints()

  if anchorDirection == nil then
    errorFrame:EnableMouse(true)
    errorFrame:SetMovable(true)

    errorFrame:SetScript('OnMouseDown', function(frame)
      if IsControlKeyDown() == true then
        frame:StartMoving()
      end
    end)

    errorFrame:SetScript('OnMouseUp', function(frame)
      frame:StopMovingOrSizing()

      local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()

      _G['UIC_CR_ErrorFrameInfo'] = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offsetX = math.floor(offsetX),
        offsetY = math.floor(offsetY),
      }
    end)

    if _G['UIC_CR_ErrorFrameInfo'] then
      local point = _G['UIC_CR_ErrorFrameInfo'].point
      local relativeTo = _G['UIC_CR_ErrorFrameInfo'].relativeTo
      local relativePoint = _G['UIC_CR_ErrorFrameInfo'].relativePoint
      local offsetX = _G['UIC_CR_ErrorFrameInfo'].offsetX
      local offsetY = _G['UIC_CR_ErrorFrameInfo'].offsetY

      local status, _ = pcall(function () errorFrame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end)
      if status == false then
        _G['UIC_CR_ErrorFrameInfo'] = nil

        anchorToUIFrame()
      end
    else
      anchorToUIFrame()
    end
  else
    errorFrame:EnableMouse(false)
    errorFrame:SetMovable(false)
    errorFrame:SetScript('OnMouseDown', function() end)
    errorFrame:SetScript('OnMouseUp', function() end)

    errorFrameAnchoringTable[anchorDirection]()
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

local resetErrorFrameLocation = function()
  _G['UIC_CR_ErrorFrameInfo'] = nil

  if _G['UIC_CR_ErrorFrameAnchor'] == 1 then
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

local EVENTS = {}
EVENTS['UI_ERROR_MESSAGE'] = function(...)
  gotUIErrorMessage(...)
end

EVENTS['PLAYER_REGEN_DISABLED'] = function()
  gotUIErrorMessage(nil, 'PLAYER_REGEN_DISABLED')
end

EVENTS['PLAYER_REGEN_ENABLED'] = function(...)
  if errorFrame.texture:GetTexture() == COMBAT_WARNING_TEXTURE_ID then
    stopAttackTimer()
  end
end

EVENTS['MIRROR_TIMER_START'] = function(timerName, value, maxValue, scale, paused, timerLabel)
  if timerName == 'BREATH' and _G['UIC_CR_BreathWarning'] == true then
    breathStart(value, maxValue, scale, paused)
  end
end

EVENTS['MIRROR_TIMER_STOP'] = function(timerName)
  if timerName == 'BREATH' then
    breathStop()
  end
end

CriticalReminders = {}

CriticalReminders.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_CriticalReminders', UIParent)
  mainFrame.ResetErrorFrameLocation = resetErrorFrameLocation
  mainFrame:Hide()

  initializeErrorFrame()
  initializeBreathFrame()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

CriticalReminders.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

CriticalReminders.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  stopAttackTimer()
  breathStop()
end

CriticalReminders.Update = function()
  anchorErrorFrame()
end

return CriticalReminders
