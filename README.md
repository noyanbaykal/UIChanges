# UI Changes

UI Changes consists of many modules that improve parts of the default UI. The modules can be individually toggled and not all are enabled by default. Please check out the in-game addon options page of UI Changes for all the available settings. UIChanges makes use of LibStub and LibUIDropDownMenu.

**Auction House Tooltips**

Provides a calculator that takes in a price and a multiplier, to help with determining the cost of a bunch.
Shows the single bid and buyout prices for the entry you're hovering on (This feature is classic era only as it is present TBCC onwards).
Also shows warnings for both the hovered over entry and the selected entry.
Selected entry warning is displayed below the buyout button.

This addon does not track AH prices and give smart suggestions. It blindly looks at the ratio of buyout / bid and warns you if the ratio is too high.
If the ratio is >= 8, it displays a red warning sign. A yellow warning sign is displayed for when the ratio is 2 >= x < 8.
False positives are very much possible. This feature is just to give you a heads up in case you are about to accidentally buyout a scam entry (for example, 40s bid and 311g buyout).

Also provides a simple calculator that takes in a price and a number to multiply it with, to calculate the stack buyout price from a single buyout price.
Additionally, clicking on an itemFrame in a bag with the mouse middleButton allows for a quick search while the Browse tab of the AH is visible.

**Attack Failure Reminder**

This module might come in handy for people who'd like the UI Error Messages that are displayed near the top center of the screen to be more prominent. The module adds an icon above the error messages to make sure the error doesn't get lost due to everything else that might be going on in the UI / the game world.

Currently the following errors will display the icon:
  Unable to attack / shoot due to range (min and max)
  Unable to attack / shoot / cast due to direction (not facing target)
  Unable to cast due to distance (shoot wand is considered casting, same as spells)
  Cast interrupted due to movement
  Unable to interact due to distance
  Target not in line of sight
  Ability / spell on cooldown
  Failed attempt
  Entered combat (needs to be enabled in the options page)
  No energy/mana/rage (needs to be enabled in the options page)

**Bag Utilities**
Opens looted clams to avoid extra work and inventory congestion. UseContainerItem is protected in WOTLK so this feature is classic era only.

**Druid Mana Bar**
Druid Mana Bar Displays the mana bar underneath the player frame when shapeshifted into a form that does not use mana as a druid. This feature exists in WOTLK classic so this is for classic era only. The mana bar obeys the "Status Text Display" preference under the Interface options.

**Party Pet Frames**

I ported over my previously stand-alone party pet frames addon into UIC. Back in vanilla the default party frames used to show party pet frames as well. This feature seems to have been hidden behind a console variable and the power frames dropped somewhere around patch 7.0.3. This module enables the console variable and implements the missing power bars. While porting this addon, I changed it to be more in line with the current state of the party pet frames of the modern client that classic now uses.

**Ping Announcer**

This is my second stand-alone addon that I ported. It listens to the player pinging in the mini-map on a marker with text and sends a message to chat mentioning the player's name, marker text and direction (in relation to the player). While porting this addon, I added the option to selectively disable its functionality while in a battleground, arena, raid or just a party. The module defaults to party chat, but if Control (CTRL) is pressed while the mini-map ping is sent out, the instance chat channel will be used instead. The instance chat channel only exists when in a battleground, arena or instance.
The mouse click handlers for the minimap zoom in / out buttons will check for the shift button being held to set the zoom level to max in / out.

Please let me know if you encounter any issues as I currently don't have a max level character that I'm playing with.

### License
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
