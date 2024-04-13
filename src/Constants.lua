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

local _, addonTable = ...

-- Localization setup

-- Injects the strings that need additional work. The work here is needed regardless of the language being used
-- by the client. Having this function here prevents code duplication in locale files.
local buildRemainingStrings = function (L)
  local colorWhite = '|cFFFFFFFF'
  local colorRed = '|cFFFF0000'
  local colorOrange = '|cFFFF8000'
  local colorEscape = '|r'

  L.NEEDS_RELOAD = colorOrange .. L.NEEDS_RELOAD_1 .. colorEscape
  L.OPTIONS_INFO = colorRed .. L.OPTIONS_INFO_1 .. colorEscape

  L.MINIMAP_QUICK_ZOOM = colorWhite .. L.MINIMAP_QUICK_ZOOM_1 .. colorEscape
  L.TOOLTIP_MINIMAP_QUICK_ZOOM = L.MINIMAP_QUICK_ZOOM_1 .. '\n' .. colorWhite .. L.MINIMAP_QUICK_ZOOM_2 .. colorEscape

  L.PPF = {L.PPF_1, colorRed .. L.PPF_2 ..colorEscape}

  local AbsorbDisplayStringHelper = function()
    local namePws = GetSpellInfo(17)
    local nameSacrifice = GetSpellInfo(7812)
  
    local spellstoneId = 128
    if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
      spellstoneId = 54730
    end
  
    local nameSpellstone = GetSpellInfo(spellstoneId)
  
    return namePws..', '..nameSacrifice..' & '..nameSpellstone..'.'
  end

  L.AD = {L.ABSORB_DISPLAY_1 .. AbsorbDisplayStringHelper(), L.ABSORB_DISPLAY_2}
  
  local buildCriticalRemindersVariables = function()
    local CRITICAL_REMINDERS_VARIABLES = {
      'BREATH_WARNING',
      'COMBAT_WARNING',
      'GATHERING_FAILURE',
      'COMBAT_LOS',
      'COMBAT_DIRECTION',
      'COMBAT_RANGE',
      'COMBAT_INTERRUPTED',
      'COMBAT_COOLDOWN',
      'COMBAT_NO_RESOURCE',
      'INTERACTION_RANGE',
    }

    for _, variableKey in ipairs(CRITICAL_REMINDERS_VARIABLES) do
      local name = L[variableKey]

      local shortName = ''
      
      for character in string.gmatch(name, '%u+') do -- Find all the uppercase letters
        shortName = shortName .. character
      end

      local soundText = shortName .. ' ' ..SOUND
      
      L[variableKey .. '_SOUND'] = soundText
      L[variableKey .. '_SOUND_TOOLTIP'] = soundText .. '\n' .. colorWhite .. L.PLAY_SOUND .. ' ' .. name .. colorEscape
    end
  end

  buildCriticalRemindersVariables()
end

local languages = {
	['enUS'] = true,
	['koKR'] = true,
	['frFR'] = true,
	['deDE'] = true,
	['zhCN'] = true,
	['esES'] = true,
	['zhTW'] = true,
	['esMX'] = true,
	['ruRU'] = true,
	['ptBR'] = true,
	['itIT'] = true,
}

-- Try to match the client's language
local locale = GetLocale()

if not addonTable[locale] then
  locale = 'enUS' -- Default to English
end

addonTable.L = addonTable[locale] -- Set the localization table for all the other files

if locale ~= 'enUS' then
  setmetatable(addonTable.L, {__index = addonTable.enUS}) -- Set the enUS table as fallback
end

buildRemainingStrings(addonTable.L)

-- Remove the direct refences to the language tables so the unused ones will be garbage collected
for language, _ in pairs(languages) do
  addonTable[language] = nil
end

-- ~Localization setup

local L = addonTable.L

local constants = {}

-- There is a single SavedVariablesPerCharacter named UIChanges_Profile. All the entries listed below
-- correspond to entries in the UIChanges_Profile table.
constants.savedVariableEntries = {
  {'UIC_Toggle_Quick_Zoom',           true},
  {'UIC_AD_IsEnabled',                true},
  {'UIC_AD_FrameInfo',                {}},
  {'UIC_AHT_IsEnabled',               true},
  {'UIC_BU_IsEnabled',                true},
  {'UIC_CR_IsEnabled',                true},
  {'UIC_CR_ErrorFrameAnchor',         1},
  {'UIC_CR_ErrorFrameInfo',           {}},
  {'UIC_CR_BreathWarning',            true},
  {'UIC_CR_BreathWarning_Sound',      true},
  {'UIC_CR_CombatWarning',            true},
  {'UIC_CR_CombatWarning_Sound',      false},
  {'UIC_CR_GatheringFailure',         true},
  {'UIC_CR_GatheringFailure_Sound',   false},
  {'UIC_CR_CombatLos',                true},
  {'UIC_CR_CombatLos_Sound',          false},
  {'UIC_CR_CombatDirection',          false},
  {'UIC_CR_CombatDirection_Sound',    false},
  {'UIC_CR_CombatRange',              false},
  {'UIC_CR_CombatRange_Sound',        false},
  {'UIC_CR_CombatInterrupted',        false},
  {'UIC_CR_CombatInterrupted_Sound',  false},
  {'UIC_CR_CombatCooldown',           false},
  {'UIC_CR_CombatCooldown_Sound',     false},
  {'UIC_CR_CombatNoResource',         false},
  {'UIC_CR_CombatNoResource_Sound',   false},
  {'UIC_CR_InteractionRange',         false},
  {'UIC_CR_InteractionRange_Sound',   false},
  {'UIC_DMB_IsEnabled',               true},
  {'UIC_PPF_IsEnabled',               function() return GetCVar('showPartyPets') == 1 end},
  {'UIC_PA_IsEnabled',                true},
  {'UIC_PA_Party',                    true},
  {'UIC_PA_Battleground',             false},
  {'UIC_PA_Raid',                     false},
  {'UIC_PA_Arena',                    false},
}

constants.AD_RESET_DISPLAY_LOCATION = function()
  local adMainFrame = _G['UIC_AbsorbDisplay']
  if adMainFrame and adMainFrame.ResetDisplayLocation then
    adMainFrame:ResetDisplayLocation()
  end
end

constants.CR_RESET_ERROR_FRAME_LOCATION = function()
  local crMainFrame = _G['UIC_CriticalReminders']
  if crMainFrame and crMainFrame.ResetErrorFrameLocation then
    crMainFrame:ResetErrorFrameLocation()
  end
end

constants.ENUM_ANCHOR_OPTIONS = {
  {OFF,                    nil},
  {L.ANCHOR_TOPLEFT,       'TOPLEFT'},
  {L.ANCHOR_TOP,           'TOP'},
  {L.ANCHOR_TOPRIGHT,      'TOPRIGHT'},
  {L.ANCHOR_RIGHT,         'RIGHT'},
  {L.ANCHOR_BOTTOMRIGHT,   'BOTTOMRIGHT'},
  {L.ANCHOR_BOTTOM,        'BOTTOM'},
  {L.ANCHOR_BOTTOMLEFT,    'BOTTOMLEFT'},
  {L.ANCHOR_LEFT,          'LEFT'}
}

-- These toggles have the same schema as subToggles.entries
constants.BASE_TOGGLES = {
  {'UIC_Toggle_Quick_Zoom', L.MINIMAP_QUICK_ZOOM, false, nil, L.TOOLTIP_MINIMAP_QUICK_ZOOM},
}

constants.MODULES = {
  {
    ['savedVariableName'] = 'UIC_AD_IsEnabled', -- Name of the corresponding savedVariable
    ['moduleName'] = 'AbsorbDisplay', -- Corresponds to the class that is exported in the module file
    ['label'] = 'AD', -- Used in subframe names
    ['title'] = 'Absorb Display',
    ['description'] = L.AD,
    ['subToggles'] = {
      ['offsetX'] = 35,
      ['entries'] = {
        -- Unlike the checkbox and dropdown subToggles, the button subToggles don't change their display based
        -- on the relevant variable's value. To escape that type of behaviour the entries that map to buttons
        -- should not have a string in the first index. Still want to keep the relevant variable name around
        -- though so the string is inside a table.
        {{'UIC_AD_FrameInfo'}, RESET_POSITION, false, {'button', constants.AD_RESET_DISPLAY_LOCATION}},
      }
    },
  },
  {
    ['savedVariableName'] = 'UIC_AHT_IsEnabled',
    ['moduleName'] = 'AHTools',
    ['label'] = 'AHT',
    ['title'] = 'Auction House Tools',
    ['description'] = L.AHT,
  },
  {
    ['savedVariableName'] = 'UIC_BU_IsEnabled',
    ['moduleName'] = 'BagUtilities',
    ['label'] = 'BU',
    ['title'] = 'Bag Utilities ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.BU,
  },
  {
    ['savedVariableName'] = 'UIC_CR_IsEnabled',
    ['moduleName'] = 'CriticalReminders',
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
        {{'UIC_CR_ErrorFrameInfo'}, RESET_POSITION, false, {'button', constants.CR_RESET_ERROR_FRAME_LOCATION}},
      },
      ['separator'] = {3, 19}
    },
  },
  {
    ['savedVariableName'] = 'UIC_DMB_IsEnabled',
    ['moduleName'] = 'DruidManaBar',
    ['label'] = 'DMB',
    ['title'] = 'Druid Mana Bar ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.DMB,
  },
  {
    ['savedVariableName'] = 'UIC_PPF_IsEnabled',
    ['moduleName'] = 'PartyPetFrames',
    ['consoleVariableName'] = 'showPartyPets', -- Modules that change console variables must be toggled outside of combat
    ['label'] = 'PPF',
    ['title'] = 'Party Pet Frames',
    ['description'] = L.PPF,
  },
  {
    ['savedVariableName'] = 'UIC_PA_IsEnabled',
    ['moduleName'] = 'PingAnnouncer',
    ['label'] = 'PA',
    ['title'] = 'Ping Announcer',
    ['description'] = L.PA,
    ['subToggles'] = {
      ['offsetX'] = 72,
      ['entries'] = {
        {'UIC_PA_Raid', RAID},
        {'UIC_PA_Arena', ARENA},
        {'UIC_PA_Battleground', BATTLEGROUND},
        {'UIC_PA_Party', PARTY},
      }
    },
  },
}

constants.REGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:RegisterEvent(event)
  end
end

constants.UNREGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:UnregisterEvent(event)
  end
end

constants.BACKDROP_INFO = function(edgeSize, insetSize)
  return {
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
    edgeSize = edgeSize, 
    insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize }
  }
end

constants.RoundToPixelCount = function(count)
  if count == 0 then
    return count
  elseif count > 0 and count < 1 then
    return 1
  else
    return math.floor(0.5 + count)
  end
end

addonTable.C = constants
