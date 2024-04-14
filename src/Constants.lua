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

addonTable.C = {}

local L
local C = addonTable.C

C.REGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:RegisterEvent(event)
  end
end

C.UNREGISTER_EVENTS = function(frame, eventsTable)
  for event, _ in pairs(eventsTable) do
    frame:UnregisterEvent(event)
  end
end

C.BACKDROP_INFO = function(edgeSize, insetSize)
  return {
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
    edgeSize = edgeSize, 
    insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize }
  }
end

C.RoundToPixelCount = function(count)
  if count == 0 then
    return count
  elseif count > 0 and count < 1 then
    return 1
  else
    return math.floor(0.5 + count)
  end
end

-- Injects the strings that need additional work. The work here is needed regardless of the language being used
-- by the client. Having this function here prevents code duplication in locale files.
local buildCommonStrings = function (L)
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
  
  local buildCriticalRemindersVariables = function(L)
    for variableName, value in pairs(L.CR_SUBTOGGLE_STRINGS) do
      local shortName = ''
      
      for character in string.gmatch(value, '%u+') do -- Find all the uppercase letters
        shortName = shortName .. character
      end

      local soundText = shortName .. ' ' ..SOUND
      
      L[variableName] = value
      L[variableName .. '_SOUND'] = soundText
      L[variableName .. '_SOUND_TOOLTIP'] = soundText .. '\n' .. colorWhite .. L.PLAY_SOUND .. ' ' .. value .. colorEscape
    end
  end

  buildCriticalRemindersVariables(L)
end

local initializeLocalization = function()
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

  buildCommonStrings(addonTable.L)

  -- Remove the direct refences to the language tables so the unused ones will be garbage collected
  for language, _ in pairs(languages) do
    addonTable[language] = nil
  end

  L = addonTable.L -- Set the localization table for this file

  C.ENUM_ANCHOR_OPTIONS = {
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
end

C.AD_RESET_DISPLAY_LOCATION = function()
  local adMainFrame = _G['UIC_AbsorbDisplay']
  if adMainFrame and adMainFrame.ResetDisplayLocation then
    adMainFrame:ResetDisplayLocation()
  end
end

C.CR_RESET_ERROR_FRAME_LOCATION = function()
  local crMainFrame = _G['UIC_CriticalReminders']
  if crMainFrame and crMainFrame.ResetErrorFrameLocation then
    crMainFrame:ResetErrorFrameLocation()
  end
end

C.DEFINE_MODULES = function()
  -- These toggles have the same schema as subToggles.entries
  C.BASE_SETTINGS = {
    {'UIC_Toggle_Quick_Zoom', true, L.MINIMAP_QUICK_ZOOM, false, nil, L.TOOLTIP_MINIMAP_QUICK_ZOOM},
  }

  C.MODULES = {
    ['AbsorbDisplay'] = { -- The key corresponds to the class that is exported in the module file
      ['moduleKey'] = 'UIC_AD_IsEnabled', -- Name of the corresponding entry in UIChanges_Profile
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 1,
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
            {{'UIC_AD_FrameInfo'}, {}, RESET_POSITION, false, {'button', C.AD_RESET_DISPLAY_LOCATION}},
        },
      },
    },
    ['AHTools'] = {
      ['moduleKey'] = 'UIC_AHT_IsEnabled',
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 2,
      ['label'] = 'AHT',
      ['title'] = 'Auction House Tools',
      ['description'] = L.AHT,
    },
    ['BagUtilities'] = {
      ['moduleKey'] = 'UIC_BU_IsEnabled',
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 3,
      ['label'] = 'BU',
      ['title'] = 'Bag Utilities ('..L.CLASSIC_ERA_ONLY..')',
      ['description'] = L.BU,
    },
    ['CriticalReminders'] = {
      ['moduleKey'] = 'UIC_CR_IsEnabled',
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 4,
      ['label'] = 'CR',
      ['title'] = 'Critical Reminders',
      ['description'] = L.CR,
      ['subToggles'] = {
        ['offsetX'] = 42,
        ['rowSize'] = 4,
        ['separator'] = {3, 19},
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
          {{'UIC_CR_ErrorFrameInfo'}, {}, RESET_POSITION, false, {'button', C.CR_RESET_ERROR_FRAME_LOCATION}},
        },
      },
    },
    ['DruidManaBar'] = {
      ['moduleKey'] = 'UIC_DMB_IsEnabled',
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 5,
      ['label'] = 'DMB',
      ['title'] = 'Druid Mana Bar ('..L.CLASSIC_ERA_ONLY..')',
      ['description'] = L.DMB,
    },
    ['PartyPetFrames'] = {
      ['moduleKey'] = 'UIC_PPF_IsEnabled',
      ['isEnabledByDefault'] = GetCVar('showPartyPets') == 1,
      ['optionsPanelIndex'] = 6,
      ['label'] = 'PPF',
      ['title'] = 'Party Pet Frames',
      ['description'] = L.PPF,
      ['consoleVariableName'] = 'showPartyPets', -- Modules that change console variables must be toggled outside of combat
    },
    ['PingAnnouncer'] = {
      ['moduleKey'] = 'UIC_PA_IsEnabled',
      ['isEnabledByDefault'] = true,
      ['optionsPanelIndex'] = 7,
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
end

-- Traverses the BASE_SETTINGS and MODULES tables to dynamically gather the names and default values
-- of all the entries that will be stored in the UIChanges_Profile savedVariablePerCharacter.
local generateProfileDefaults = function()
  local profileDefaults = {}

  local addSubsetting = function(subsetting)
    local key = subsetting[1]
    local defaultValue = subsetting[2]

    if type(key) == 'table' then
      key = key[1]
    end

    profileDefaults[key] = defaultValue
  end

  for i = 1, #C.BASE_SETTINGS do
    addSubsetting(C.BASE_SETTINGS[i])
  end

  for moduleName, attributes in pairs(C.MODULES) do
    local moduleKey = attributes['moduleKey']
    local defaultState = attributes['isEnabledByDefault']

    profileDefaults[moduleKey] = defaultState

    local subsettings = attributes['subToggles']

    if subsettings and subsettings.entries then
      for i = 1, #subsettings.entries do
        addSubsetting(subsettings.entries[i])
      end
    end
  end

  return profileDefaults
end

C.INITIALIZE_PROFILE = function()
  local hasUnexpectedChanges = false

  if not UIChanges_Profile then -- Either first time using UIChanges or upgrading from version < 1.2.0
    hasUnexpectedChanges = true

    UIChanges_Profile = {}
  end

  -- Store all the keys from the profile in case there are any no-longer-used ones
  local keysToBeDeleted = {}
  for settingName, _ in pairs(UIChanges_Profile) do
    keysToBeDeleted[settingName] = true
  end

  local profileDefaults = generateProfileDefaults()

  -- Initialize variables if they haven't been initialized already
  for settingName, defaultValue in pairs(profileDefaults) do
    keysToBeDeleted[settingName] = nil -- Remove this from the set of keys to be deleted

    if UIChanges_Profile[settingName] == nil then
      hasUnexpectedChanges = true

      -- If the user is upgrading from version < 1.2.0, they have the old, individual savedVariables.
      -- The old savedVariables will be wiped out the next time the client saves the savedVariables.
      -- This is the one time chance of reading those variables and converting them into the new format
      -- so we won't reset the user's preferences.
      local previousVersionValue = _G[settingName]
    
      if previousVersionValue and type(previousVersionValue) == type(defaultValue) then
        UIChanges_Profile[settingName] = previousVersionValue
      else
        UIChanges_Profile[settingName] = defaultValue
      end
    end
  end

  -- Remove any no-longer-used variables
  for settingName, _ in pairs(keysToBeDeleted) do
    UIChanges_Profile[settingName] = nil
  end

  if hasUnexpectedChanges then
    DEFAULT_CHAT_FRAME:AddMessage(L.FIRST_TIME)
  end
end

initializeLocalization()
