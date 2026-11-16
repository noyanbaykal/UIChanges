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

local mainFrame, breathFrame, breathTimer, breathValues, anchorHelper

local BREATH_TIMER_INTERVAL = 1 -- Seconds

local function anchorInClassic()
  local index = 1
  for i = 1, 3 do
    if _G['MirrorTimer'..i..'Text']:GetText() == BREATH_LABEL then
      index = i
      break
    end
  end

  breathFrame:SetPoint('LEFT', _G['MirrorTimer'..index], 'LEFT', -45, 0)
  breathFrame:SetPoint('TOP', _G['MirrorTimer'..index], 'TOP', 0, 8)
end

local function anchorInRetail()
  breathFrame:SetPoint('RIGHT', MirrorTimerContainer, 'LEFT', -5, 0)
  breathFrame:SetPoint('TOP', MirrorTimerContainer, 'TOP', 0, 0)
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

  local r, g, b = 1, 1, 1
  if secondsLeft <= 10 then
    r, g, b = 1, 0, 0
  elseif (maxSeconds / secondsLeft) > 2 then
    r, g, b = 1, 1, 0
  end

  anchorHelper()

  breathFrame.title:SetTextColor(r, g, b)
  breathFrame.title:SetText(secondsLeft)

  breathFrame:Show()

  if UIChanges_Profile['UIC_BW_Sound'] then
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

local initializeBreathFrame = function()
  breathFrame = CreateFrame('Frame', 'UIC_BW_BREATH', _G['MirrorTimer1'], 'BackdropTemplate')
  breathFrame:SetSize(32, 32)
  breathFrame:SetFrameStrata('TOOLTIP')
  breathFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  breathFrame:SetBackdropColor(0, 0, 0, 1)

  breathFrame.title = breathFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  breathFrame.title:SetPoint('CENTER', 0, 0)
  breathFrame.title:SetJustifyH('RIGHT')

  breathFrame:Hide()
end

local EVENTS = {}

EVENTS['MIRROR_TIMER_START'] = function(timerName, value, maxValue, scale, paused, timerLabel)
  if timerName == 'BREATH' and UIChanges_Profile['UIC_BW_IsEnabled'] then
    breathStart(value, maxValue, scale, paused)
  end
end

EVENTS['MIRROR_TIMER_STOP'] = function(timerName)
  if timerName == 'BREATH' then
    breathStop()
  end
end

local BreathWarning = {}

BreathWarning.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_BreathWarning', UIParent)
  mainFrame:Hide()

  if LE_EXPANSION_LEVEL_CURRENT > LE_EXPANSION_MISTS_OF_PANDARIA or WOW_PROJECT_ID == WOW_PROJECT_CAMELOT then
    anchorHelper = anchorInRetail
  else
    anchorHelper = anchorInClassic
  end

  initializeBreathFrame()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

BreathWarning.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

BreathWarning.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  breathStop()
end

addonTable.BreathWarning = BreathWarning
