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

local _, addonTable = ...

local C = addonTable.C

local mainFrame, errorFrame, breathFrame, attackTimer, breathTimer, breathValues

local TIMER_INTERVAL = 4 -- Seconds
local BREATH_TIMER_INTERVAL = 1 -- Seconds

local showCombatWarning = function()
  return UIChanges_Profile['UIC_CR_CombatWarning']
end

local showGatheringFailure = function()
  return UIChanges_Profile['UIC_CR_GatheringFailure']
end

local showNoLos = function()
  return UIChanges_Profile['UIC_CR_CombatLos']
end

local showCombatDirection = function()
  return UIChanges_Profile['UIC_CR_CombatDirection']
end

local showCombatRange = function()
  return UIChanges_Profile['UIC_CR_CombatRange']
end

local showCombatInterrupted = function()
  return UIChanges_Profile['UIC_CR_CombatInterrupted']
end

local showCombatCooldown = function()
  return UIChanges_Profile['UIC_CR_CombatCooldown']
end

local showNoResource = function()
  return UIChanges_Profile['UIC_CR_CombatNoResource']
end

local showInteractionRange = function()
  return UIChanges_Profile['UIC_CR_InteractionRange']
end

local ErrorMap = {
  ['PLAYER_REGEN_DISABLED'] =               {showCombatWarning,     'Interface\\ICONS\\Ability_DualWield',                  'UIC_CR_CombatWarning_Sound'},
  [ERR_BADATTACKPOS] =                      {showCombatRange,       'Interface\\CURSOR\\UnableAttack',                      'UIC_CR_CombatRange_Sound'},
  [ERR_BADATTACKFACING] =                   {showCombatDirection,   'Interface\\GLUES\\CharacterSelect\\CharacterUndelete', 'UIC_CR_CombatDirection_Sound', 52},
  [ERR_OUT_OF_RANGE] =                      {showCombatRange,       'Interface\\CURSOR\\UnableCrosshairs',                  'UIC_CR_CombatRange_Sound'},
  [ERR_SPELL_COOLDOWN] =                    {showCombatCooldown,    'Interface\\ICONS\\INV_Misc_PocketWatch_01',            'UIC_CR_CombatCooldown_Sound'},
  [ERR_SPELL_FAILED_ANOTHER_IN_PROGRESS] =  {showCombatInterrupted, 'Interface\\CURSOR\\UnableCast',                        'UIC_CR_CombatInterrupted_Sound', nil, 1, -2},
  [ERR_OUT_OF_MANA] =                       {showNoResource,        'Interface\\ICONS\\Spell_Shadow_ManaBurn',              'UIC_CR_CombatNoResource_Sound'},
  [ERR_OUT_OF_RAGE] =                       {showNoResource,        'Interface\\ICONS\\Ability_Racial_BloodRage',           'UIC_CR_CombatNoResource_Sound'},
  [ERR_OUT_OF_ENERGY] =                     {showNoResource,        'Interface\\ICONS\\ClassIcon_Rogue',                    'UIC_CR_CombatNoResource_Sound'},
  [ERR_TOO_FAR_TO_INTERACT] =               {showInteractionRange,  'Interface\\CURSOR\\UnableInteract',                    'UIC_CR_InteractionRange_Sound', nil, 1, -2},
  [SPELL_FAILED_TRY_AGAIN] =                {showGatheringFailure,  'Interface\\CURSOR\\UnableGatherHerbs',                 'UIC_CR_GatheringFailure_Sound'},
  [SPELL_FAILED_LINE_OF_SIGHT] =            {showNoLos,             'Interface\\ICONS\\INV_Misc_Eye_01',                    'UIC_CR_CombatLos_Sound'},
  [INTERRUPTED] =                           {showCombatInterrupted, 'Interface\\CURSOR\\UnableUI-Cursor-Move',              'UIC_CR_CombatInterrupted_Sound'},
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

  if UIChanges_Profile['UIC_CR_BreathWarning_Sound'] == true then
    local soundId

    if secondsLeft == 30 then
      soundId = 7256 -- NsabbeyBell
    elseif secondsLeft == 15 then
      soundId = 12867 -- AlarmClockWarning2
    elseif secondsLeft == 10 or secondsLeft == 5 then
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

local showUIErrorMessage = function(textureName, playSound, size, offsetX, offsetY)
  stopAttackTimer()
  attackTimer = C_Timer.NewTicker(TIMER_INTERVAL, stopAttackTimer)
  setErrorFrame(textureName, playSound, size, offsetX, offsetY)
end

local targetFrame = _G['TargetFrame']
local targetFramePortrait = _G['TargetFramePortrait']
local targetFrameTextureFrame = _G['TargetFrameTextureFrame']

local errorFrameAnchoringTable = {}
errorFrameAnchoringTable['TOPLEFT'] = function()
  errorFrame:SetPoint('LEFT', targetFrame, 'LEFT', 2, 0)
  errorFrame:SetPoint('BOTTOM', targetFramePortrait, 'TOP', 0, 5)
end
errorFrameAnchoringTable['TOP'] = function()
  local x = (targetFrameTextureFrame:GetRight() - targetFrameTextureFrame:GetLeft()) / 4

  errorFrame:SetPoint('LEFT', targetFrame, 'LEFT', x, 0)
  errorFrame:SetPoint('BOTTOM', targetFramePortrait, 'TOP', 0, 5)
end
errorFrameAnchoringTable['TOPRIGHT'] = function()
  errorFrame:SetPoint('RIGHT', targetFramePortrait, 'RIGHT', 0)
  errorFrame:SetPoint('BOTTOM', targetFramePortrait, 'TOP', 0, 5)
end
errorFrameAnchoringTable['RIGHT'] = function()
  errorFrame:SetPoint('LEFT', targetFrame, 'RIGHT', -10, 0)
end
errorFrameAnchoringTable['BOTTOMRIGHT'] = function()
  errorFrame:SetPoint('RIGHT', targetFramePortrait, 'RIGHT', 0)
  errorFrame:SetPoint('TOP', targetFramePortrait, 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['BOTTOM'] = function()
  local x = (targetFrameTextureFrame:GetRight() - targetFrameTextureFrame:GetLeft()) / 4

  errorFrame:SetPoint('LEFT', targetFrame, 'LEFT', x, 0)
  errorFrame:SetPoint('TOP', targetFramePortrait, 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['BOTTOMLEFT'] = function()
  errorFrame:SetPoint('LEFT', targetFrame, 'LEFT', 2, 0)
  errorFrame:SetPoint('TOP', targetFramePortrait, 'BOTTOM', 0, -5)
end
errorFrameAnchoringTable['LEFT'] = function()
  errorFrame:SetPoint('RIGHT', targetFrame, 'LEFT', -10, 6)
end

local anchorToUIErrorsFrame = function()
  local uiErrorsFrame = _G['UIErrorsFrame']
  local offsetX = (uiErrorsFrame:GetWidth() / 2) - (errorFrame:GetWidth() / 2)

  errorFrame:SetPoint('BOTTOM', _G['MirrorTimer1'], 'TOP', 0, 15)
  errorFrame:SetPoint('LEFT', uiErrorsFrame, 'LEFT', offsetX, 0)
end

local anchorErrorFrame = function()
  if InCombatLockdown() then
    return
  end

  local anchorDirection = C.ENUM_ANCHOR_OPTIONS[UIChanges_Profile['UIC_CR_ErrorFrameAnchor']][2]

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

      UIChanges_Profile['UIC_CR_ErrorFrameInfo'] = {
        point = point,
        relativeTo = relativeTo,
        relativePoint = relativePoint,
        offsetX = math.floor(offsetX),
        offsetY = math.floor(offsetY),
      }
    end)

    local errorFrameInfo = UIChanges_Profile['UIC_CR_ErrorFrameInfo']

    if errorFrameInfo and errorFrameInfo.point ~= nil then
      local point = errorFrameInfo.point
      local relativeTo = errorFrameInfo.relativeTo
      local relativePoint = errorFrameInfo.relativePoint
      local offsetX = errorFrameInfo.offsetX
      local offsetY = errorFrameInfo.offsetY

      local status, _ = pcall(function () errorFrame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end)
      if status == false then
        UIChanges_Profile['UIC_CR_ErrorFrameInfo'] = {}

        anchorToUIErrorsFrame()
      end
    else
      anchorToUIErrorsFrame()
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

local handleErrorMessage = function(message)
  if ErrorMap[message] == nil then
    return
  end

  local shouldShow, textureName, soundVariableName, size, offsetX, offsetY = unpack(ErrorMap[message])
  if shouldShow() ~= true or not textureName then
    return
  end

  local playSound = UIChanges_Profile[soundVariableName] == true

  showUIErrorMessage(textureName, playSound, size, offsetX, offsetY)
end

local EVENTS = {}
EVENTS['UI_ERROR_MESSAGE'] = function(errorType, message)
  handleErrorMessage(message)
end

EVENTS['PLAYER_REGEN_DISABLED'] = function()
  handleErrorMessage('PLAYER_REGEN_DISABLED')
end

EVENTS['PLAYER_REGEN_ENABLED'] = function(...)
  if errorFrame.texture:GetTexture() == 132147 then -- Ability_DualWield used when the player enters combat
    stopAttackTimer()
  end
end

EVENTS['MIRROR_TIMER_START'] = function(timerName, value, maxValue, scale, paused, timerLabel)
  if timerName == 'BREATH' and UIChanges_Profile['UIC_CR_BreathWarning'] == true then
    breathStart(value, maxValue, scale, paused)
  end
end

EVENTS['MIRROR_TIMER_STOP'] = function(timerName)
  if timerName == 'BREATH' then
    breathStop()
  end
end

local CriticalReminders = {}

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

addonTable.CriticalReminders = CriticalReminders
