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

local L = UI_CHANGES_LOCALE

-- All addons share the global namespace and global name conflicts are possible.
-- Bundling all constants in a single object to avoid possible conflicts.
UI_CHANGES_CONSTANTS = {}

UI_CHANGES_CONSTANTS.AD_RESET_DISPLAY_LOCATION = function()
  local adMainFrame = _G['UIC_AbsorbDisplay']
  if adMainFrame and adMainFrame.ResetDisplayLocation then
    adMainFrame:ResetDisplayLocation()
  end
end

UI_CHANGES_CONSTANTS.CR_RESET_ERROR_FRAME_LOCATION = function()
  local crMainFrame = _G['UIC_CriticalReminders']
  if crMainFrame and crMainFrame.ResetErrorFrameLocation then
    crMainFrame:ResetErrorFrameLocation()
  end
end

UI_CHANGES_CONSTANTS.ENUM_ANCHOR_OPTIONS = {
  {'Off', nil},
  {'Top Left',      'TOPLEFT'},
  {'Top',           'TOP'},
  {'Top Right',     'TOPRIGHT'},
  {'Right',         'RIGHT'},
  {'Bottom Right',  'BOTTOMRIGHT'},
  {'Bottom',        'BOTTOM'},
  {'Bottom Left',   'BOTTOMLEFT'},
  {'Left',          'LEFT'}
}

-- These toggles have the same schema as subToggles.entries
UI_CHANGES_CONSTANTS.BASE_TOGGLES = {
  {'UIC_Toggle_Quick_Zoom', L.MINIMAP_QUICK_ZOOM, false, nil, L.TOOLTIP_MINIMAP_QUICK_ZOOM},
  {'UIC_Toggle_Hide_Era_Map_Button', L.ERA_HIDE_MINIMAP_MAP_BUTTON, false, nil, L.TOOLTIP_ERA_HIDE_MINIMAP_MAP_BUTTON},
}

UI_CHANGES_CONSTANTS.MODULES = {
  {
    ['savedVariableName'] = 'UIC_AD_IsEnabled', -- Name of the corresponding savedVariable
    ['frameName'] = 'AbsorbDisplay', -- Corresponds to the class that is exported in the module file
    ['label'] = 'AD', -- Used in subframe names
    ['title'] = 'Absorb Display',
    ['description'] = L.AD,
    ['subToggles'] = {
      ['offsetX'] = 35,
      ['entries'] = {
        {nil, L.RESET_POSITION, false, {'button', UI_CHANGES_CONSTANTS.AD_RESET_DISPLAY_LOCATION}},
      }
    },
  },
  {
    ['savedVariableName'] = 'UIC_AHT_IsEnabled',
    ['frameName'] = 'AHTools',
    ['label'] = 'AHT',
    ['title'] = 'Auction House Tools',
    ['description'] = L.AHT,
  },
  {
    ['savedVariableName'] = 'UIC_BU_IsEnabled',
    ['frameName'] = 'BagUtilities',
    ['label'] = 'BU',
    ['title'] = 'Bag Utilities ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.BU,
  },
  {
    ['savedVariableName'] = 'UIC_CR_IsEnabled',
    ['frameName'] = 'CriticalReminders',
    ['label'] = 'CR',
    ['title'] = 'Critical Reminders',
    ['description'] = L.CR,
    ['subToggles'] = {
      ['offsetX'] = 42,
      ['rowSize'] = 4,
      ['entries'] = {
        {'UIC_CR_BreathWarning', L.BREATH_WARNING},
        {'UIC_CR_BreathWarning_Sound', L.BREATH_WARNING_SOUND, false, nil, L.BREATH_WARNING_SOUND_TOOLTIP},
        {'UIC_CR_CombatWarning', L.COMBAT_WARNING},
        {'UIC_CR_CombatWarning_Sound', L.COMBAT_WARNING_SOUND, false, nil, L.COMBAT_WARNING_SOUND_TOOLTIP},
        {'UIC_CR_GatheringFailure', L.GATHERING_FAILURE},
        {'UIC_CR_GatheringFailure_Sound', L.GATHERING_FAILURE_SOUND, false, nil, L.GATHERING_FAILURE_SOUND_TOOLTIP},
        {'UIC_CR_CombatLos', L.COMBAT_LOS},
        {'UIC_CR_CombatLos_Sound', L.COMBAT_LOS_SOUND, false, nil, L.COMBAT_LOS_SOUND_TOOLTIP},
        {'UIC_CR_CombatDirection', L.COMBAT_DIRECTION},
        {'UIC_CR_CombatDirection_Sound', L.COMBAT_DIRECTION_SOUND, false, nil, L.COMBAT_DIRECTION_SOUND_TOOLTIP},
        {'UIC_CR_CombatRange', L.COMBAT_RANGE},
        {'UIC_CR_CombatRange_Sound', L.COMBAT_RANGE_SOUND, false, nil, L.COMBAT_RANGE_SOUND_TOOLTIP},
        {'UIC_CR_CombatInterrupted', L.COMBAT_INTERRUPTED},
        {'UIC_CR_CombatInterrupted_Sound', L.COMBAT_INTERRUPTED_SOUND, false, nil, L.COMBAT_INTERRUPTED_SOUND_TOOLTIP},
        {'UIC_CR_CombatCooldown', L.COMBAT_COOLDOWN},
        {'UIC_CR_CombatCooldown_Sound', L.COMBAT_COOLDOWN_SOUND, false, nil, L.COMBAT_COOLDOWN_SOUND_TOOLTIP},
        {'UIC_CR_CombatNoResource', L.COMBAT_NO_RESOURCE},
        {'UIC_CR_CombatNoResource_Sound', L.COMBAT_NO_RESOURCE_SOUND, false, nil, L.COMBAT_NO_RESOURCE_SOUND_TOOLTIP},
        {'UIC_CR_InteractionRange', L.INTERACTION_RANGE},
        {'UIC_CR_InteractionRange_Sound', L.INTERACTION_RANGE_SOUND, false, nil, L.INTERACTION_RANGE_SOUND_TOOLTIP},
        {'UIC_CR_ErrorFrameAnchor', L.ERROR_FRAME_ANCHOR_DROPDOWN, true, {'dropdown', 'ENUM_ANCHOR_OPTIONS'}},
        {nil, L.RESET_POSITION, false, {'button', UI_CHANGES_CONSTANTS.CR_RESET_ERROR_FRAME_LOCATION}},
      },
      ['separator'] = {3, 19}
    },
  },
  {
    ['savedVariableName'] = 'UIC_DMB_IsEnabled',
    ['frameName'] = 'DruidManaBar',
    ['label'] = 'DMB',
    ['title'] = 'Druid Mana Bar ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.DMB,
  },
  {
    ['savedVariableName'] = 'UIC_PPF_IsEnabled',
    ['frameName'] = 'PartyPetFrames',
    ['consoleVariableName'] = 'showPartyPets', -- Modules that change console variables must be toggled outside of combat
    ['label'] = 'PPF',
    ['title'] = 'Party Pet Frames',
    ['description'] = L.PPF,
  },
  {
    ['savedVariableName'] = 'UIC_PA_IsEnabled',
    ['frameName'] = 'PingAnnouncer',
    ['label'] = 'PA',
    ['title'] = 'Ping Announcer',
    ['description'] = L.PA,
    ['subToggles'] = {
      ['offsetX'] = 72,
      ['entries'] = {
        {'UIC_PA_Raid', L.RAID},
        {'UIC_PA_Arena', L.ARENA},
        {'UIC_PA_Battleground', L.BATTLEGROUND},
        {'UIC_PA_Party', L.PARTY},
      }
    },
  },
}

UI_CHANGES_CONSTANTS.REGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:RegisterEvent(event)
  end
end

UI_CHANGES_CONSTANTS.UNREGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:UnregisterEvent(event)
  end
end

UI_CHANGES_CONSTANTS.BACKDROP_INFO = function(edgeSize, insetSize)
  return {
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
    edgeSize = edgeSize, 
    insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize }
  }
end

UI_CHANGES_CONSTANTS.RoundToPixelCount = function(count)
  if count == 0 then
    return count
  elseif count > 0 and count < 1 then
    return 1
  else
    return math.floor(0.5 + count)
  end
end

return UI_CHANGES_CONSTANTS
