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

UI_CHANGES_LOCALE = {}

UI_CHANGES_LOCALE.TXT_NOT_CLASSIC = 'UI Changes supports classic only!'
UI_CHANGES_LOCALE.FIRST_TIME = 'UI Changes encountered new variables with this character! Please check out the Interface Options/AddOns/UIChanges page to see the available options.'
UI_CHANGES_LOCALE.OPTIONS_INFO = '|cFFFFFFFFYou can individually toggle modules here. |cFFFF8000Settings that modify console variables have to be toggled when not in combat and require a UI reload afterwards to take effect.'
UI_CHANGES_LOCALE.CVAR_CHANGED = 'UI Changes: Console variable changed, please reload your UI!'
UI_CHANGES_LOCALE.CANT_CHANGE_IN_COMBAT = 'UI Changes: Unable to change setting while in combat! Please check the options page again after combat.' 
UI_CHANGES_LOCALE.CHANGES_CANCELLED = 'UI Changes: Options screen cancelled, no changes will be made!'

-- AHTooltips
UI_CHANGES_LOCALE.AHT = {'Shows single bid and buyout tooltips in the AH. Also displays a warning sign for possible scams.'}
UI_CHANGES_LOCALE.SINGLE_BID = 'Single bid price: '
UI_CHANGES_LOCALE.SINGLE_BUYOUT = 'Single buyout price: '
-- ~AHTooltips

-- AFR
UI_CHANGES_LOCALE.AFR = {'Makes some failure related UI Error messages more visible by adding an icon above the messages.'}
UI_CHANGES_LOCALE.ENTERED_COMBAT_CHECKBOX = 'Entered Combat Warning'
UI_CHANGES_LOCALE.NO_RESOURCE_CHECKBOX = 'No Resource Warning'
-- ~AFR

-- PartyPetFrames
UI_CHANGES_LOCALE.PPF = {'Re-enables the hidden pet frames & adds their missing power bars when using default party frames.', '|cFFFF8000This modifies a console variable! Please remember to disable this first if you\'re going to remove the addon.'}
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
