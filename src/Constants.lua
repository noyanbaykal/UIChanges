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
  {'UIC_Toggle_Quick_Zoom', true, L.MINIMAP_QUICK_ZOOM, false, nil, L.TOOLTIP_MINIMAP_QUICK_ZOOM},
}

constants.MODULES = {
  {
    ['savedVariableName'] = {'UIC_AD_IsEnabled', true}, -- Name of the corresponding entry in the profile and
      --a boolean or a function for whether the module should be enabled by default
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
        -- though so the string is inside a table
        -- The second value is the default value
        {{'UIC_AD_FrameInfo'}, {}, RESET_POSITION, false, {'button', constants.AD_RESET_DISPLAY_LOCATION}},
      }
    },
  },
  {
    ['savedVariableName'] = {'UIC_AHT_IsEnabled', true},
    ['moduleName'] = 'AHTools',
    ['label'] = 'AHT',
    ['title'] = 'Auction House Tools',
    ['description'] = L.AHT,
  },
  {
    ['savedVariableName'] = {'UIC_BU_IsEnabled', true},
    ['moduleName'] = 'BagUtilities',
    ['label'] = 'BU',
    ['title'] = 'Bag Utilities ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.BU,
  },
  {
    ['savedVariableName'] = {'UIC_CR_IsEnabled', true},
    ['moduleName'] = 'CriticalReminders',
    ['label'] = 'CR',
    ['title'] = 'Critical Reminders',
    ['description'] = L.CR,
    ['subToggles'] = {
      ['offsetX'] = 42,
      ['rowSize'] = 4,
      ['entries'] = {
        {'UIC_CR_BreathWarning', true, L.BREATH_WARNING},
        {'UIC_CR_BreathWarning_Sound', true, L.BREATH_WARNING_SOUND, false, nil, L.BREATH_WARNING_SOUND_TOOLTIP},
        {'UIC_CR_CombatWarning', true, L.COMBAT_WARNING},
        {'UIC_CR_CombatWarning_Sound', false, L.COMBAT_WARNING_SOUND, false, nil, L.COMBAT_WARNING_SOUND_TOOLTIP},
        {'UIC_CR_GatheringFailure', true, L.GATHERING_FAILURE},
        {'UIC_CR_GatheringFailure_Sound', false, L.GATHERING_FAILURE_SOUND, false, nil, L.GATHERING_FAILURE_SOUND_TOOLTIP},
        {'UIC_CR_CombatLos', true, L.COMBAT_LOS},
        {'UIC_CR_CombatLos_Sound', false, L.COMBAT_LOS_SOUND, false, nil, L.COMBAT_LOS_SOUND_TOOLTIP},
        {'UIC_CR_CombatDirection', false, L.COMBAT_DIRECTION},
        {'UIC_CR_CombatDirection_Sound', false, L.COMBAT_DIRECTION_SOUND, false, nil, L.COMBAT_DIRECTION_SOUND_TOOLTIP},
        {'UIC_CR_CombatRange', false, L.COMBAT_RANGE},
        {'UIC_CR_CombatRange_Sound', false, L.COMBAT_RANGE_SOUND, false, nil, L.COMBAT_RANGE_SOUND_TOOLTIP},
        {'UIC_CR_CombatInterrupted', false, L.COMBAT_INTERRUPTED},
        {'UIC_CR_CombatInterrupted_Sound', false, L.COMBAT_INTERRUPTED_SOUND, false, nil, L.COMBAT_INTERRUPTED_SOUND_TOOLTIP},
        {'UIC_CR_CombatCooldown', false, L.COMBAT_COOLDOWN},
        {'UIC_CR_CombatCooldown_Sound', false, L.COMBAT_COOLDOWN_SOUND, false, nil, L.COMBAT_COOLDOWN_SOUND_TOOLTIP},
        {'UIC_CR_CombatNoResource', false, L.COMBAT_NO_RESOURCE},
        {'UIC_CR_CombatNoResource_Sound', false, L.COMBAT_NO_RESOURCE_SOUND, false, nil, L.COMBAT_NO_RESOURCE_SOUND_TOOLTIP},
        {'UIC_CR_InteractionRange', false, L.INTERACTION_RANGE},
        {'UIC_CR_InteractionRange_Sound', false, L.INTERACTION_RANGE_SOUND, false, nil, L.INTERACTION_RANGE_SOUND_TOOLTIP},
        {'UIC_CR_ErrorFrameAnchor', 1, L.ERROR_FRAME_ANCHOR_DROPDOWN, true, {'dropdown', 'ENUM_ANCHOR_OPTIONS'}},
        {{'UIC_CR_ErrorFrameInfo'}, {}, RESET_POSITION, false, {'button', constants.CR_RESET_ERROR_FRAME_LOCATION}},
      },
      ['separator'] = {3, 19}
    },
  },
  {
    ['savedVariableName'] = {'UIC_DMB_IsEnabled', true},
    ['moduleName'] = 'DruidManaBar',
    ['label'] = 'DMB',
    ['title'] = 'Druid Mana Bar ('..L.CLASSIC_ERA_ONLY..')',
    ['description'] = L.DMB,
  },
  {
    ['savedVariableName'] = {'UIC_PPF_IsEnabled', function() return GetCVar('showPartyPets') == 1 end},
    ['moduleName'] = 'PartyPetFrames',
    ['consoleVariableName'] = 'showPartyPets', -- Modules that change console variables must be toggled outside of combat
    ['label'] = 'PPF',
    ['title'] = 'Party Pet Frames',
    ['description'] = L.PPF,
  },
  {
    ['savedVariableName'] = {'UIC_PA_IsEnabled', true},
    ['moduleName'] = 'PingAnnouncer',
    ['label'] = 'PA',
    ['title'] = 'Ping Announcer',
    ['description'] = L.PA,
    ['subToggles'] = {
      ['offsetX'] = 72,
      ['entries'] = {
        {'UIC_PA_Raid', false, RAID},
        {'UIC_PA_Arena', false, ARENA},
        {'UIC_PA_Battleground', false, BATTLEGROUND},
        {'UIC_PA_Party', true, PARTY},
      }
    },
  },
}

-- Traverses the BASE_TOGGLES and MODULES tables to dynamically gather the names and default values
-- of all the entries that will be stored in the UIChanges_Profile savedVariablePerCharacter.
local generateSavedVariableEntries = function()
  local entries = {}

  for i = 1, #constants.BASE_TOGGLES do
    local baseToggle = constants.BASE_TOGGLES[i]

    entries[baseToggle[1]] = baseToggle[2]
  end

  for i = 1, #constants.MODULES do
    local module = constants.MODULES[i]

    local moduleName = module.savedVariableName[1]

    local defaultState = module.savedVariableName[2]
    if type(defaultState) == 'function' then
      defaultState = defaultState()
    end

    entries[moduleName] = defaultState

    if module.subToggles and module.subToggles.entries then
      for i = 1, #module.subToggles.entries do
        local entry = module.subToggles.entries[i]

        local entryName = entry[1]
        if type(entryName) == 'table' then
          entryName = entryName[1]
        end

        entries[entryName] = entry[2]
      end
    end
  end

  return entries
end

constants.INITIALIZE_PROFILE = function()
  local hasUnexpectedChanges = false

  if not UIChanges_Profile then -- Either first time using UIChanges or upgrading from version < 1.2.0
    hasUnexpectedChanges = true

    UIChanges_Profile = {}
  end

  -- Store all the keys from the profile in case there are any no-longer-used ones
  local keysToBeDeleted = {}
  for variableName, _ in pairs(UIChanges_Profile) do
    keysToBeDeleted[variableName] = true
  end

  local savedVariableEntries = generateSavedVariableEntries()

  -- Initialize variables if they haven't been initialized already
  for name, defaultValue in pairs(savedVariableEntries) do
    keysToBeDeleted[name] = nil -- Remove this from the set of keys to be deleted

    if UIChanges_Profile[name] == nil then
      hasUnexpectedChanges = true

      -- If the user is upgrading from version < 1.2.0, they have the old, individual savedVariables.
      -- The old savedVariables will be wiped out the next time the client saves the savedVariables.
      -- There is a one time chance of reading those variables and converting them into the new format
      -- so we won't reset the user's preferences.
      local previousVersionValue = _G[name]
    
      if previousVersionValue and type(previousVersionValue) == type(defaultValue) then
        UIChanges_Profile[name] = previousVersionValue
      else
        UIChanges_Profile[name] = defaultValue
      end
    end
  end

  -- Remove any no-longer-used variables
  for variableName, _ in pairs(keysToBeDeleted) do
    UIChanges_Profile[variableName] = nil
  end

  if hasUnexpectedChanges then
    DEFAULT_CHAT_FRAME:AddMessage(L.FIRST_TIME)
  end
end

addonTable.C = constants
