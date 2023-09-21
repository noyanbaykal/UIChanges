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

local colorWhite = '|cFFFFFFFF'
local colorRed = '|cFFFF0000'
local colorOrange = '|cFFFF8000'
local colorEscape = '|r'

UI_CHANGES_LOCALE = {}

UI_CHANGES_LOCALE.TXT_NOT_CLASSIC = 'UI Changes supports classic only!'
local NEEDS_RELOAD_1 = 'This takes effect after a UI reload!'
UI_CHANGES_LOCALE.NEEDS_RELOAD = colorOrange..NEEDS_RELOAD_1..colorEscape
UI_CHANGES_LOCALE.FIRST_TIME = 'UI Changes encountered new variables with this character! Please check out the Interface Options/AddOns/UIChanges page to see the available options.'
local OPTIONS_INFO_1 = 'Settings that modify console variables have to be toggled when not in combat and require a UI reload afterwards to take effect. Then you need to log off for the game to save the changed console variable.'
UI_CHANGES_LOCALE.OPTIONS_INFO = colorRed..OPTIONS_INFO_1..colorEscape
UI_CHANGES_LOCALE.CVAR_CHANGED = 'UI Changes: Console variable changed, please reload your UI!'
UI_CHANGES_LOCALE.CANT_CHANGE_IN_COMBAT = 'UI Changes: Unable to change setting while in combat! Please check the options page again after combat.' 
UI_CHANGES_LOCALE.CHANGES_CANCELLED = 'UI Changes: Options screen cancelled, no changes will be made!'
UI_CHANGES_LOCALE.CLASSIC_ERA = 'Classic Era'
UI_CHANGES_LOCALE.CLASSIC_ERA_ONLY = UI_CHANGES_LOCALE.CLASSIC_ERA..' Only'
UI_CHANGES_LOCALE.RESET_POSITION = 'Reset Position'
UI_CHANGES_LOCALE.SOUND = 'Sound'
UI_CHANGES_LOCALE.PLAY_SOUND = 'Play '..UI_CHANGES_LOCALE.SOUND..' for'

-- Base Options
local MINIMAP_QUICK_ZOOM_1 = 'Minimap quick zoom'
UI_CHANGES_LOCALE.MINIMAP_QUICK_ZOOM = colorWhite..MINIMAP_QUICK_ZOOM_1..colorEscape
UI_CHANGES_LOCALE.TOOLTIP_MINIMAP_QUICK_ZOOM = MINIMAP_QUICK_ZOOM_1..'\n'..colorWhite..'Shift click the minimap + / - buttons for max zoom in / out.'..colorEscape
local ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide minimap map button'
UI_CHANGES_LOCALE.ERA_HIDE_MINIMAP_MAP_BUTTON = colorWhite..ERA_HIDE_MINIMAP_MAP_BUTTON_1..colorEscape
local TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide the world map button attached to the minimap in '..UI_CHANGES_LOCALE.CLASSIC_ERA..' so it won\'t overlap the tracking icon.'
UI_CHANGES_LOCALE.TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON = ERA_HIDE_MINIMAP_MAP_BUTTON_1..'\n'..colorWhite..TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON_1..'\n'..UI_CHANGES_LOCALE.NEEDS_RELOAD
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

UI_CHANGES_LOCALE.AD = {adStringHelper(), 'You can drag the display while holding CTRL.'}
-- ~AbsorbDisplay

-- AHTooltips
UI_CHANGES_LOCALE.AHT = {'Provides a simple price calculator and displays a warning sign for possible scams.'}
-- ~AHTooltips

-- BagUtilities
UI_CHANGES_LOCALE.BU = {'Opens clams after picking them up.'}
-- ~BagUtilities

-- CriticalReminders
UI_CHANGES_LOCALE.CR = {'Makes the selected warnings more noticeable by displaying an error icon and / or playing a sound.', 'When the anchor is set to Off, the display can be dragged while holding CTRL and reset with the button.'}
UI_CHANGES_LOCALE.ERROR_FRAME_ANCHOR_DROPDOWN = 'Anchor to TargetFrame'

UI_CHANGES_LOCALE.BREATH_WARNING = 'Breath Warning'
local BREATH_WARNING_SHORT = 'BW'
UI_CHANGES_LOCALE.BREATH_WARNING_SOUND = BREATH_WARNING_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.BREATH_WARNING_SOUND_TOOLTIP = UI_CHANGES_LOCALE.BREATH_WARNING_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.BREATH_WARNING..colorEscape

UI_CHANGES_LOCALE.COMBAT_WARNING = 'Combat Warning'
local COMBAT_WARNING_SHORT = 'CW'
UI_CHANGES_LOCALE.COMBAT_WARNING_SOUND = COMBAT_WARNING_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_WARNING_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_WARNING_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_WARNING..colorEscape

UI_CHANGES_LOCALE.GATHERING_FAILURE = 'Gathering Failure'
local GATHERING_FAILURE_SHORT = 'GF'
UI_CHANGES_LOCALE.GATHERING_FAILURE_SOUND = GATHERING_FAILURE_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.GATHERING_FAILURE_SOUND_TOOLTIP = UI_CHANGES_LOCALE.GATHERING_FAILURE_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.GATHERING_FAILURE..colorEscape

UI_CHANGES_LOCALE.COMBAT_LOS = 'Combat LOS'
local COMBAT_LOS_SHORT = 'CL'
UI_CHANGES_LOCALE.COMBAT_LOS_SOUND = COMBAT_LOS_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_LOS_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_LOS_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_LOS..colorEscape

UI_CHANGES_LOCALE.COMBAT_DIRECTION = 'Combat Direction'
local COMBAT_DIRECTION_SHORT = 'CD'
UI_CHANGES_LOCALE.COMBAT_DIRECTION_SOUND = COMBAT_DIRECTION_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_DIRECTION_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_DIRECTION_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_DIRECTION..colorEscape

UI_CHANGES_LOCALE.COMBAT_RANGE = 'Combat Range'
local COMBAT_RANGE_SHORT = 'CR'
UI_CHANGES_LOCALE.COMBAT_RANGE_SOUND = COMBAT_RANGE_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_RANGE_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_RANGE_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_RANGE..colorEscape

UI_CHANGES_LOCALE.COMBAT_INTERRUPTED = 'Combat Interrupted'
local COMBAT_INTERRUPTED_SHORT = 'CI'
UI_CHANGES_LOCALE.COMBAT_INTERRUPTED_SOUND = COMBAT_INTERRUPTED_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_INTERRUPTED_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_INTERRUPTED_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_INTERRUPTED..colorEscape

UI_CHANGES_LOCALE.COMBAT_COOLDOWN = 'Combat Cooldown'
local COMBAT_COOLDOWN_SHORT = 'CC'
UI_CHANGES_LOCALE.COMBAT_COOLDOWN_SOUND = COMBAT_COOLDOWN_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_COOLDOWN_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_COOLDOWN_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_COOLDOWN..colorEscape

UI_CHANGES_LOCALE.COMBAT_NO_RESOURCE = 'Combat No Resource'
local COMBAT_NO_RESOURCE_SHORT = 'CNR'
UI_CHANGES_LOCALE.COMBAT_NO_RESOURCE_SOUND = COMBAT_NO_RESOURCE_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.COMBAT_NO_RESOURCE_SOUND_TOOLTIP = UI_CHANGES_LOCALE.COMBAT_NO_RESOURCE_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.COMBAT_NO_RESOURCE..colorEscape

UI_CHANGES_LOCALE.INTERACTION_RANGE = 'Interaction Range'
local INTERACTION_RANGE_SHORT = 'IR'
UI_CHANGES_LOCALE.INTERACTION_RANGE_SOUND = INTERACTION_RANGE_SHORT..' '..UI_CHANGES_LOCALE.SOUND
UI_CHANGES_LOCALE.INTERACTION_RANGE_SOUND_TOOLTIP = UI_CHANGES_LOCALE.INTERACTION_RANGE_SOUND..'\n'..colorWhite..UI_CHANGES_LOCALE.PLAY_SOUND..' '..UI_CHANGES_LOCALE.INTERACTION_RANGE..colorEscape
-- ~CriticalReminders

-- DruidManaBar
UI_CHANGES_LOCALE.DMB = {'Shows the mana bar while shapeshifted into a druid form that does not use mana.'}
-- ~DruidManaBar

-- PartyPetFrames
local PPF_1 = 'Re-enables the hidden pet frames & adds their missing power bars when using default party frames.'
local PPF_2 = 'This modifies a console variable! If you\'re going to remove the addon, disable this and log off first.'
UI_CHANGES_LOCALE.PPF = {PPF_1, colorRed..PPF_2..colorEscape}
UI_CHANGES_LOCALE.CURRENT_CVAR_VALUE = function(enabled)
  local variable = enabled == true and 'enabled' or 'disabled'
  return 'The showPartyPets console variable is currently '..variable..'.'
end
-- ~PartyPetFrames

-- PingAnnouncer
UI_CHANGES_LOCALE.PA = {'Sends a party message when you click on a minimap object to alert your party members.', 'Hold down CTRL when clicking to send the message to all raid or battleground members instead.'}
UI_CHANGES_LOCALE.PARTY = 'Party'
UI_CHANGES_LOCALE.RAID = 'Raid'
UI_CHANGES_LOCALE.BATTLEGROUND = 'Battleground'
UI_CHANGES_LOCALE.ARENA = 'Arena'

UI_CHANGES_LOCALE.PINGED = 'Pinged'
UI_CHANGES_LOCALE.NEARBY = 'in the immediate vicinity!'
UI_CHANGES_LOCALE.DIRECTION = 'to the'

UI_CHANGES_LOCALE.EAST = 'East'
UI_CHANGES_LOCALE.WEST = 'West'
UI_CHANGES_LOCALE.NORTH = 'North'
UI_CHANGES_LOCALE.SOUTH = 'South'
-- ~PingAnnouncer

return UI_CHANGES_LOCALE
