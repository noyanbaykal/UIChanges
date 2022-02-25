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

-- The addon entry is right here

-- TODO: OPTIONS: initialize modules based on stored variables
-- TODO: improve PA with raid/bg/arena checks using ctrl click
-- TODO: port PPF

local L = UI_CHANGES_LOCALE

local isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
local isRetail = not (isClassic or isTBC)

if isRetail then
  DEFAULT_CHAT_FRAME:AddMessage(L.TXT_NOT_CLASSIC)
  return
end

AHTooltips.Initialize(isTBC)
AttackRange.Initialize()
PingAnnouncer.Initialize()
