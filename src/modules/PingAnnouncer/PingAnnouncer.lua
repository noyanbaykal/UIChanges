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

local handlePing = function(unitId, x, y)
  -- Only consider pings coming from the player while there is a tooltip visible, when in a party
  local isPartyPing = unitId ~= 'player'
  local tooltipText = _G['GameTooltipTextLeft1']:GetText()
  local inParty = IsInGroup() and not IsInRaid()
  
  if isPartyPing or tooltipText == nil or not inParty then
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

  -- Let the party members know
  local messageText = getPingMessage(tooltipText, directionX, directionY)
  SendChatMessage(messageText, 'PARTY');
end

PingAnnouncer = {}

PingAnnouncer.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PingAnnouncer', UIParent)
  mainFrame:Hide()

  mainFrame:RegisterEvent('MINIMAP_PING')

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    if (event == 'MINIMAP_PING') then
      handlePing(...)
    end
  end)


  lastPingTime = time()
end

return PingAnnouncer
