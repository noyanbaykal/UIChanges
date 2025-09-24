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

local locale = {}

-- Localization files should set a reference to themselves in the addonTable with their locale code as the key
addonTable.enUS = locale

locale.TXT_NOT_CLASSIC_1 = 'UI Changes supports classic only! You will have very limited functionality with the retail client!'
locale.OPTIONS_INFO_1 = 'Settings that modify console variables have to be toggled when not in combat and require a UI reload afterwards to take effect. Then you need to log off for the game to save the changed console variable.'
locale.FIRST_TIME = 'UI Changes encountered new variables with this character! Please check out the Interface Options/AddOns/UIChanges page to see the available options.'
locale.CVAR_CHANGED = 'UI Changes: Console variable changed, please reload your UI!'
locale.CANT_CHANGE_IN_COMBAT = 'UI Changes: Unable to change setting while in combat! Please check the options page again after combat.' 
locale.PLAY_SOUND = 'Play '..SOUND..' for'
locale.INCOMPATIBLE_MODULES_TEXT = 'Modules not compatible with this version of the game and the current character:'

locale.ANCHOR_TOPLEFT = 'Top Left'
locale.ANCHOR_TOP = 'Top'
locale.ANCHOR_TOPRIGHT = 'Top Right'
locale.ANCHOR_RIGHT = 'Right'
locale.ANCHOR_BOTTOMRIGHT = 'Bottom Right'
locale.ANCHOR_BOTTOM = 'Bottom'
locale.ANCHOR_BOTTOMLEFT = 'Bottom Left'
locale.ANCHOR_LEFT = 'Left'

-- Base Options
locale.MINIMAP_QUICK_ZOOM = 'Minimap quick zoom'
locale.TOOLTIP_MINIMAP_QUICK_ZOOM = 'Shift click the minimap + / - buttons for max zoom in / out.'
-- ~Base Options

-- AbsorbDisplay
locale.ABSORB_DISPLAY_1 = 'Displays the approximate absorption provided by '
locale.ABSORB_DISPLAY_2 = 'You can drag the display while holding CTRL.'
-- ~AbsorbDisplay

-- AHTools
locale.AHT = {
  'Provides a simple stack price calculator and displays a warning sign for possible scams.',
  'Also allows you to MiddleMouse click an item in your bags to initiate a search with the item\'s name.'
}
-- ~AHTools

-- BagUtilities
locale.BU = {'Opens bag & clams after picking them up.'}
-- ~BagUtilities

-- CriticalReminders
locale.CR = {
  'Makes the selected warnings more noticeable by displaying an error icon and optionally playing a sound.',
  'When the anchor option is set to Off, the display can be dragged while holding CTRL or reset with the button.'
}

locale.ERROR_FRAME_ANCHOR_DROPDOWN = 'Anchor to TargetFrame'

locale.CR_SUBSETTING_STRINGS = {
  ['BREATH_WARNING']      = 'Breath Warning',
  ['COMBAT_WARNING']      = 'Combat Warning',
  ['GATHERING_FAILURE']   = 'Gathering Failure',
  ['COMBAT_LOS']          = 'Combat LOS',
  ['COMBAT_DIRECTION']    = 'Combat Direction',
  ['COMBAT_RANGE']        = 'Combat Range',
  ['COMBAT_INTERRUPTED']  = 'Combat Interrupted',
  ['COMBAT_COOLDOWN']     = 'Combat Cooldown',
  ['COMBAT_NO_RESOURCE']  = 'Combat No Resource',
  ['INTERACTION_RANGE']   = 'Interaction Range',
}
-- ~CriticalReminders

-- DruidManaBar
locale.DMB = {'Shows the mana bar while shapeshifted into a druid form that does not use mana.'}
-- ~DruidManaBar

-- PartyPetFrames
locale.PPF_1 = 'Re-enables the hidden pet frames and adds their missing power bars when using default party frames.'
locale.PPF_2 = 'This modifies a console variable! If you\'re going to remove the addon, disable this and log off first.'
-- ~PartyPetFrames

-- PingAnnouncer
locale.PA = {
  'Sends a party message when you click on a minimap object to alert your party members.',
  'Hold down CTRL when clicking to send the message to all raid or battleground members instead.'
}

locale.PINGED = 'Pinged'
locale.NEARBY = 'in the immediate vicinity!'
locale.DIRECTION = 'to the'

locale.EAST = 'East'
locale.WEST = 'West'
locale.NORTH = 'North'
locale.SOUTH = 'South'
-- ~PingAnnouncer

-- SpellTargetDisplay
locale.STD = {'Displays the target\'s name under the cast bar when casting a spell. '..locale.ABSORB_DISPLAY_2}
-- ~SpellTargetDisplay
