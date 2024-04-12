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

local locale = {}

locale.TXT_NOT_CLASSIC = 'UI Changes supports classic only!'
locale.NEEDS_RELOAD_1 = 'This takes effect after a UI reload!'
locale.FIRST_TIME = 'UI Changes encountered new variables with this character! Please check out the Interface Options/AddOns/UIChanges page to see the available options.'
locale.OPTIONS_INFO_1 = 'Settings that modify console variables have to be toggled when not in combat and require a UI reload afterwards to take effect. Then you need to log off for the game to save the changed console variable.'
locale.CVAR_CHANGED = 'UI Changes: Console variable changed, please reload your UI!'
locale.CANT_CHANGE_IN_COMBAT = 'UI Changes: Unable to change setting while in combat! Please check the options page again after combat.' 
locale.CLASSIC_ERA = 'Classic Era'
locale.CLASSIC_ERA_ONLY = locale.CLASSIC_ERA..' Only'
locale.PLAY_SOUND = 'Play '..SOUND..' for'

-- Base Options
locale.MINIMAP_QUICK_ZOOM_1 = 'Minimap quick zoom'
locale.MINIMAP_QUICK_ZOOM_2 = 'Shift click the minimap + / - buttons for max zoom in / out.'
locale.ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide minimap map button'
locale.TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON_1 = 'Hide the world map button attached to the minimap in '..locale.CLASSIC_ERA..' so it won\'t overlap with the tracking icon.'
-- ~Base Options

-- AbsorbDisplay
locale.ABSORB_DISPLAY_1 = 'Displays the approximate absorption provided by '
locale.ABSORB_DISPLAY_2 = 'You can drag the display while holding CTRL.'
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
locale.COMBAT_WARNING = 'Combat Warning'
locale.GATHERING_FAILURE = 'Gathering Failure'
locale.COMBAT_LOS = 'Combat LOS'
locale.COMBAT_DIRECTION = 'Combat Direction'
locale.COMBAT_RANGE = 'Combat Range'
locale.COMBAT_INTERRUPTED = 'Combat Interrupted'
locale.COMBAT_COOLDOWN = 'Combat Cooldown'
locale.COMBAT_NO_RESOURCE = 'Combat No Resource'
locale.INTERACTION_RANGE = 'Interaction Range'
-- ~CriticalReminders

-- DruidManaBar
locale.DMB = {'Shows the mana bar while shapeshifted into a druid form that does not use mana.'}
-- ~DruidManaBar

-- PartyPetFrames
locale.PPF_1 = 'Re-enables the hidden pet frames and adds their missing power bars when using default party frames.'
locale.PPF_2 = 'This modifies a console variable! If you\'re going to remove the addon, disable this and log off first.'
-- ~PartyPetFrames

-- PingAnnouncer
locale.PA = {'Sends a party message when you click on a minimap object to alert your party members.', 'Hold down CTRL when clicking to send the message to all raid or battleground members instead.'}

locale.PINGED = 'Pinged'
locale.NEARBY = 'in the immediate vicinity!'
locale.DIRECTION = 'to the'

locale.EAST = 'East'
locale.WEST = 'West'
locale.NORTH = 'North'
locale.SOUTH = 'South'
-- ~PingAnnouncer

-- Localization files should set a reference to themselves in the sharedTable with their locale code as the key
sharedTable.enUS = locale
