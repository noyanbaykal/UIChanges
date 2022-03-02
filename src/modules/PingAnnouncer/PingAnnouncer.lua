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

local DIRECTION_MARGIN = 0.02
local MINIMUM_SECONDS = 4

local C = UI_CHANGES_CONSTANTS
local L = UI_CHANGES_LOCALE

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

local getPingMessage = function(objectName, directionX, directionY)
  local direction

  if directionX == '' and directionY == '' then
    direction = L.NEARBY
  elseif directionX ~= '' and directionY ~= '' then
    direction = L.DIRECTION..' '..directionY..' '..directionX
  else
    direction = L.DIRECTION..' '..directionY..directionX
  end

  return L.PINGED..': '..objectName..' '..direction
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
  if isInBattleground and _G['UIC_PA_Battleground'] == false or
      isInArena and _G['UIC_PA_Arena'] == false or
      isInRaid and _G['UIC_PA_Raid'] == false or
      isInPartyOnly and (_G['UIC_PA_Party'] == false or isCTRL) then 
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

  if unitId ~= 'player' or tooltipText == nil then -- Only consider pings coming from the player while there is a tooltip visible
    return
  end

  local targetChannel = determineTargetChannel(unitId)
  if not targetChannel then
    return
  end

  -- Throttle if needed
  local currentTime = time()
  if(currentTime - lastPingTime < MINIMUM_SECONDS) then
    return
  else
    lastPingTime = currentTime
  end

  -- Determine the direction of the pinged coordinate
  local directionX, directionY = determineDirection(x, y)

  -- Let others know
  local messageText = getPingMessage(tooltipText, directionX, directionY)
  SendChatMessage(messageText, targetChannel);
end

local EVENTS = {}
EVENTS['MINIMAP_PING'] = function(...)
  handlePing(...)
end

PingAnnouncer = {}

PingAnnouncer.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PingAnnouncer', UIParent)
  mainFrame:Hide()

  mainFrame:RegisterEvent('MINIMAP_PING')

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

return PingAnnouncer
