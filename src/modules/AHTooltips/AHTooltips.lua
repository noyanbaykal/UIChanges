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

-- Forward declaring modules
local mainFrame, hoverTooltip, buyoutTooltip
local trackingTimer
local loadedAH = false

local function CheckFrames()
  hoverTooltip.Update()
  buyoutTooltip.Update()
end

local function OnShow()
  -- The first time the AH is shown, we'll hook into the button onClicks
  if loadedAH == false then
    buyoutTooltip.LoadedAH()
    loadedAH = true
  end
  
  trackingTimer = C_Timer.NewTicker(C.TIMER_INTERVAL, CheckFrames)
end

local function HideTooltips()
  hoverTooltip.Hide()
  buyoutTooltip.Hide(true)
end

local function OnClosed()
  if trackingTimer:IsCancelled() ~= true then
    trackingTimer:Cancel()
  end

  HideTooltips()
end

AHTooltips = {}

AHTooltips.Initialize = function(isTBC)
  mainFrame = CreateFrame('Frame', 'UIC_AHTooltips', UIParent)
  mainFrame:Hide()

  hoverTooltip = HoverTooltip.new(isTBC)
  buyoutTooltip = BuyoutTooltip.new()

  mainFrame:RegisterEvent(C.EVENT_AH_SHOW)
  mainFrame:RegisterEvent(C.EVENT_AH_CLOSED)

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    if event == C.EVENT_AH_SHOW then
      OnShow(...)
    elseif event == C.EVENT_AH_CLOSED then
      OnClosed(...)
    elseif event == C.EVENT_AH_LIST_UPDATE or event == C.EVENT_AH_BIDDER_UPDATE then
      buyoutTooltip.Hide(true)
    end
  end)
end

return AHTooltips
