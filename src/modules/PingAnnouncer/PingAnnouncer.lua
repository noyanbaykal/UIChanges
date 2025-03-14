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

local L = addonTable.L
local C = addonTable.C

local ESCAPE_TABLE = {
  ['|c%x%x%x%x%x%x%x%x'] = '', -- color start
  ['|r'] = '', -- color end
}

local DIRECTION_MARGIN = 0.02
local MINIMUM_SECONDS = 4

local mainFrame, lastPingTime

local determineDirection = function(x, y)
  local x2 = x
  local y2 = y

  -- Rotate the coordinates if the minimap is rotated
  if GetCVar('rotateMinimap') == '1' then
    local rot = -1 * MinimapCompassTexture:GetRotation()

    x2 = x * math.cos(rot) - y * math.sin(rot)
    y2 = y * math.cos(rot) + x * math.sin(rot)
  end

  local directionX = ''
  local directionY = ''

  if x2 < -1 * DIRECTION_MARGIN then
    directionX = L.WEST
  elseif x2 > DIRECTION_MARGIN then
    directionX = L.EAST
  end

  if y2 < -1 * DIRECTION_MARGIN then
    directionY = L.SOUTH
  elseif y2 > DIRECTION_MARGIN then
    directionY = L.NORTH
  end

  return directionX, directionY
end

local getPingMessage = function(tooltipText, x, y)
  -- Have to remove color strings due to them now causing issues with the send message function
  for pattern, substitute in pairs(ESCAPE_TABLE) do
    tooltipText = gsub(tooltipText, pattern, substitute)
  end

  if tooltipText == ZOOM_IN or tooltipText == ZOOM_OUT then
    return nil
  end

  local directionX, directionY = determineDirection(x, y)

  local direction

  if directionX == '' and directionY == '' then
    direction = L.NEARBY
  elseif directionX ~= '' and directionY ~= '' then
    direction = L.DIRECTION..' '..directionY..' '..directionX
  else
    direction = L.DIRECTION..' '..directionY..directionX
  end

  return L.PINGED..': '..tooltipText..' '..direction
end

-- Check the cVars and the current state of the game
local determineTargetChannel = function(unitId)
  -- Figure out current status
  local isCTRL = IsControlKeyDown()
  local inInstance, instanceType = IsInInstance()

  local isInBattleground = instanceType == 'pvp'
  local isInArena = instanceType == 'arena'
  local isInHomeRaid = IsInRaid(LE_PARTY_CATEGORY_HOME)
  local isInRaid = isInHomeRaid or (isInBattleground == false and isInArena == false and IsInRaid())
  local isInPartyOnly = IsInGroup() and isInBattleground == false and isInArena == false and isInRaid == false

  -- Check cvars against status + instance chat edge case
  if isInBattleground and UIChanges_Profile['UIC_PA_Battleground'] == false or
      isInArena and UIChanges_Profile['UIC_PA_Arena'] == false or
      isInRaid and UIChanges_Profile['UIC_PA_Raid'] == false or
      isInPartyOnly and (UIChanges_Profile['UIC_PA_Party'] == false or isCTRL) or
      isInPartyOnly == false then
    return nil
  end

  if not isCTRL then
    return 'PARTY'
  elseif isInHomeRaid then
    return 'RAID'
  else
    return 'INSTANCE_CHAT'
  end
end

local handlePing = function(unitId, x, y)
  local tooltipText = _G['GameTooltipTextLeft1']:GetText()

  -- Only consider pings coming from the player while there is a tooltip visible
  if unitId ~= 'player' or tooltipText == nil or string.len(tooltipText) < 1 then
    return
  end

  local targetChannel = determineTargetChannel(unitId)
  if not targetChannel then
    return
  end

  -- Throttle if needed
  local currentTime = time()
  if currentTime - lastPingTime < MINIMUM_SECONDS then
    return
  else
    lastPingTime = currentTime
  end

  -- Prepare message and let others know
  local messageText = getPingMessage(tooltipText, x, y)
  if messageText then
    SendChatMessage(messageText, targetChannel)
  end
end

local EVENTS = {}
EVENTS['MINIMAP_PING'] = handlePing

local PingAnnouncer = {}

PingAnnouncer.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PingAnnouncer', UIParent)
  mainFrame:Hide()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)

  lastPingTime = time()
end

PingAnnouncer.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

PingAnnouncer.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
end

addonTable.PingAnnouncer = PingAnnouncer
