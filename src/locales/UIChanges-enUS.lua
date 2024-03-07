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

local _, sharedTable = ...

local colorWhite = '|cFFFFFFFF'
local colorRed = '|cFFFF0000'
local colorOrange = '|cFFFF8000'
local colorEscape = '|r'

local locale = {}

locale.TXT_NOT_CLASSIC = 'UI Changes supports classic only!'
local NEEDS_RELOAD_1 = 'This takes effect after a UI reload!'
locale.NEEDS_RELOAD = colorOrange..NEEDS_RELOAD_1..colorEscape
locale.FIRST_TIME = 'UI Changes encountered new variables with this character! Please check out the Interface Options/AddOns/UIChanges page to see the available options.'
local OPTIONS_INFO_1 = 'Settings that modify console variables have to be toggled when not in combat and require a UI reload afterwards to take effect. Then you need to log off for the game to save the changed console variable.'
locale.OPTIONS_INFO = colorRed..OPTIONS_INFO_1..colorEscape
locale.CVAR_CHANGED = 'UI Changes: Console variable changed, please reload your UI!'
locale.CANT_CHANGE_IN_COMBAT = 'UI Changes: Unable to change setting while in combat! Please check the options page again after combat.' 
locale.CHANGES_CANCELLED = 'UI Changes: Options screen cancelled, no changes will be made!'
locale.CLASSIC_ERA = 'Classic Era'
locale.CLASSIC_ERA_ONLY = locale.CLASSIC_ERA..' Only'
locale.RESET_POSITION = 'Reset Position'
locale.SOUND = 'Sound'
locale.PLAY_SOUND = 'Play '..locale.SOUND..' for'

-- Base Options
local MINIMAP_QUICK_ZOOM_1 = 'Minimap quick zoom'
locale.MINIMAP_QUICK_ZOOM = colorWhite..MINIMAP_QUICK_ZOOM_1..colorEscape
locale.TOOLTIP_MINIMAP_QUICK_ZOOM = MINIMAP_QUICK_ZOOM_1..'\n'..colorWhite..'Shift click the minimap + / - buttons for max zoom in / out.'..colorEscape
local ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide minimap map button'
locale.ERA_HIDE_MINIMAP_MAP_BUTTON = colorWhite..ERA_HIDE_MINIMAP_MAP_BUTTON_1..colorEscape
local TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide the world map button attached to the minimap in '..locale.CLASSIC_ERA..' so it won\'t overlap with the tracking icon.'
locale.TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON = ERA_HIDE_MINIMAP_MAP_BUTTON_1..'\n'..colorWhite..TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON_1..'\n'..locale.NEEDS_RELOAD
-- ~Base Options

-- AbsorbDisplay
local adStringHelper = function()
  local namePws = GetSpellInfo(17)
  local nameSacrifice = GetSpellInfo(7812)

  local spellstoneId = 128
  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    spellstoneId = 54730
  end

  local nameSpellstone = GetSpellInfo(spellstoneId)

  return 'Displays the approximate absorption provided by '..namePws..', '..nameSacrifice..' and '..nameSpellstone..'.'
end

locale.AD = {adStringHelper(), 'You can drag the display while holding CTRL.'}
-- ~AbsorbDisplay

-- AHTools
locale.AHT = {'Provides a simple stack price calculator and displays a warning sign for possible scams.', 'Also allows you to MiddleMouse click an item in your bags to initiate a search with the item\'s name.'}
-- ~AHTools

-- BagUtilities
locale.BU = {'Opens clams after picking them up.'}
-- ~BagUtilities

-- CriticalReminders
locale.CR = {'Makes the selected warnings more noticeable by displaying an error icon and optionally playing a sound.', 'When the anchor option is set to Off, the display can be dragged while holding CTRL or reset with the button.'}
locale.ERROR_FRAME_ANCHOR_DROPDOWN = 'Anchor to TargetFrame'

locale.BREATH_WARNING = 'Breath Warning'
local BREATH_WARNING_SHORT = 'BW'
locale.BREATH_WARNING_SOUND = BREATH_WARNING_SHORT..' '..locale.SOUND
locale.BREATH_WARNING_SOUND_TOOLTIP = locale.BREATH_WARNING_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.BREATH_WARNING..colorEscape

locale.COMBAT_WARNING = 'Combat Warning'
local COMBAT_WARNING_SHORT = 'CW'
locale.COMBAT_WARNING_SOUND = COMBAT_WARNING_SHORT..' '..locale.SOUND
locale.COMBAT_WARNING_SOUND_TOOLTIP = locale.COMBAT_WARNING_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_WARNING..colorEscape

locale.GATHERING_FAILURE = 'Gathering Failure'
local GATHERING_FAILURE_SHORT = 'GF'
locale.GATHERING_FAILURE_SOUND = GATHERING_FAILURE_SHORT..' '..locale.SOUND
locale.GATHERING_FAILURE_SOUND_TOOLTIP = locale.GATHERING_FAILURE_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.GATHERING_FAILURE..colorEscape

locale.COMBAT_LOS = 'Combat LOS'
local COMBAT_LOS_SHORT = 'CL'
locale.COMBAT_LOS_SOUND = COMBAT_LOS_SHORT..' '..locale.SOUND
locale.COMBAT_LOS_SOUND_TOOLTIP = locale.COMBAT_LOS_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_LOS..colorEscape

locale.COMBAT_DIRECTION = 'Combat Direction'
local COMBAT_DIRECTION_SHORT = 'CD'
locale.COMBAT_DIRECTION_SOUND = COMBAT_DIRECTION_SHORT..' '..locale.SOUND
locale.COMBAT_DIRECTION_SOUND_TOOLTIP = locale.COMBAT_DIRECTION_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_DIRECTION..colorEscape

locale.COMBAT_RANGE = 'Combat Range'
local COMBAT_RANGE_SHORT = 'CR'
locale.COMBAT_RANGE_SOUND = COMBAT_RANGE_SHORT..' '..locale.SOUND
locale.COMBAT_RANGE_SOUND_TOOLTIP = locale.COMBAT_RANGE_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_RANGE..colorEscape

locale.COMBAT_INTERRUPTED = 'Combat Interrupted'
local COMBAT_INTERRUPTED_SHORT = 'CI'
locale.COMBAT_INTERRUPTED_SOUND = COMBAT_INTERRUPTED_SHORT..' '..locale.SOUND
locale.COMBAT_INTERRUPTED_SOUND_TOOLTIP = locale.COMBAT_INTERRUPTED_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_INTERRUPTED..colorEscape

locale.COMBAT_COOLDOWN = 'Combat Cooldown'
local COMBAT_COOLDOWN_SHORT = 'CC'
locale.COMBAT_COOLDOWN_SOUND = COMBAT_COOLDOWN_SHORT..' '..locale.SOUND
locale.COMBAT_COOLDOWN_SOUND_TOOLTIP = locale.COMBAT_COOLDOWN_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_COOLDOWN..colorEscape

locale.COMBAT_NO_RESOURCE = 'Combat No Resource'
local COMBAT_NO_RESOURCE_SHORT = 'CNR'
locale.COMBAT_NO_RESOURCE_SOUND = COMBAT_NO_RESOURCE_SHORT..' '..locale.SOUND
locale.COMBAT_NO_RESOURCE_SOUND_TOOLTIP = locale.COMBAT_NO_RESOURCE_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.COMBAT_NO_RESOURCE..colorEscape

locale.INTERACTION_RANGE = 'Interaction Range'
local INTERACTION_RANGE_SHORT = 'IR'
locale.INTERACTION_RANGE_SOUND = INTERACTION_RANGE_SHORT..' '..locale.SOUND
locale.INTERACTION_RANGE_SOUND_TOOLTIP = locale.INTERACTION_RANGE_SOUND..'\n'..colorWhite..locale.PLAY_SOUND..' '..locale.INTERACTION_RANGE..colorEscape
-- ~CriticalReminders

-- DruidManaBar
locale.DMB = {'Shows the mana bar while shapeshifted into a druid form that does not use mana.'}
-- ~DruidManaBar

-- PartyPetFrames
local PPF_1 = 'Re-enables the hidden pet frames and adds their missing power bars when using default party frames.'
local PPF_2 = 'This modifies a console variable! If you\'re going to remove the addon, disable this and log off first.'
locale.PPF = {PPF_1, colorRed..PPF_2..colorEscape}
locale.CURRENT_CVAR_VALUE = function(enabled)
  local variable = enabled == true and 'enabled' or 'disabled'
  return 'The showPartyPets console variable is currently '..variable..'.'
end
-- ~PartyPetFrames

-- PingAnnouncer
locale.PA = {'Sends a party message when you click on a minimap object to alert your party members.', 'Hold down CTRL when clicking to send the message to all raid or battleground members instead.'}
locale.PARTY = 'Party'
locale.RAID = 'Raid'
locale.BATTLEGROUND = 'Battleground'
locale.ARENA = 'Arena'

locale.PINGED = 'Pinged'
locale.NEARBY = 'in the immediate vicinity!'
locale.DIRECTION = 'to the'

locale.EAST = 'East'
locale.WEST = 'West'
locale.NORTH = 'North'
locale.SOUTH = 'South'
-- ~PingAnnouncer

sharedTable.L = locale
