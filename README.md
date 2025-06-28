# UI Changes

UI Changes consists of modules that improve parts of the default UI. The modules and their features can be individually toggled and not all are enabled by default. Please check out the in-game addon options page to see everything UI Changes has to offer.

**General**
Minimap quick zoom in / out: Shift click the minimap plus / negative buttons to set the zoom level to max in / out.

Hide the minimap worldMap button in classic era so it won't overlap with the tracking icon.

**Absorb Display**
Displays the approximate amount of damage absorption the player has from active Power Word: Shield, Sacrifice and Spellstone effects.
It is not feasible to determine other player's talents or item bonuses so the display for Power Word: Shield cast by others will start off with a base amount and then show a residual sign for any remaining amounts. The shield display can be moved with a CTRL click.

**Auction House Tools**
Provides utilities for the AH browse tab.

Calculator: A simple calculator to help with determining the total cost of a bunch.

Buyout warning: Whenever you select an item from the Browse Tab results, this module will calculate the ratio of buyout / bid amounts and might display a warning under the buyout button for suspected scam entries (for example, 40s bid and 311g buyout). The module does not track AH prices to give smart suggestions. It blindly compares the ratios to show a yellow sign if the ratio is 2 >= x < 8, or a red one if x >= 8 so false positives are possible!

Quick search: Clicking on an item in your bags with the mouse MiddleButton while the AH Browse tab is visible will initiate a search with that item's name.

**Bag Utilities**
Opens looted bags & clams for convenience and avoiding inventory congestion. Note that opening a container will cancel ongoing spell casts! UseContainerItem is protected in WOTLK & onwards so this feature is classic era only.

**Critical Reminders**
This module makes the selected types of events / failures more noticeable by displaying an error icon and optionally playing a sound.
The 'Breath Warning' reminder displays a numeric timer next to the standard breath meter and the 'BW Sound' option will play various alarm sounds when the remaining breath time is 30, 15 and 5 seconds.
The reminders that are turned on by default are breath timer with sound, enter combat event, ability / spell failed due to lack of line of sight and gathering failure. Many other reminders for combat events can be enabled. The error display can be moved with a CTRL click or anchored to the TargetFrame.

**Druid Mana Bar**
Displays a mana bar underneath the player frame when shapeshifted into a druid form that does not use mana. This feature exists in WOTLK & onwards so this is for classic era only. The mana bar obeys the "Status Text Display" preference under the Interface options.

**Party Pet Frames**
Back in vanilla the default party frames used to show party pet frames as well. This feature seems to have been hidden behind a console variable and the pet power frames dropped somewhere around patch 7.0.3. This module enables the console variable and implements the missing power bars. The visibility provided might come in handy when you are in a dungeon with a pet class and notice through the pet frame the pet getting two shotted even though you don't expect anyone to be in combat or when you are forced to make a last stand and a clutch heal to a pet might make all the difference.

**Ping Announcer**
Listens to the player pinging in the mini-map on a marker with text and sends a message to chat mentioning the player's name, marker text and direction (in relation to the player). The module defaults to party chat, but if Control (CTRL) is pressed while the mini-map ping is sent out, the instance chat channel will be used instead. The instance chat channel only exists when in a battleground, arena or instance.

Please let me know if you encounter any issues.

Support UI Changes Development
PayPal[https://www.paypal.com/donate/?hosted_button_id=A5SZGXCWNP32A]

More of my content
https://www.noyanbaykal.com/

UIChanges makes use of LibStub and LibUIDropDownMenu.

### How to Install

1. Download the code as a zip file from: <https://github.com/noyanbaykal/UIChanges/archive/refs/heads/master.zip>.
2. The zip file has a folder called "UIChanges-master" at the root.
Extract this folder & all it's contents into the AddOns folder of the WoW classic client you're targeting.
3. Rename the extracted folder to "UIChanges".

The default installation path for WoW on Windows is:

`C:\Program Files (x86)\World of Warcraft`

on Mac:

`/Applications/World of Warcraft/`

Inside the WoW directory you will find the AddOns folder.

For the classic client:
`C:\Program Files (x86)\World of Warcraft\_classic_\Interface\AddOns`

For the classic era client:
`C:\Program Files (x86)\World of Warcraft\_classic_era_\Interface\AddOns`

### License
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
