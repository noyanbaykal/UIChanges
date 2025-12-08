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

addonTable.C = {}

local L
local C = addonTable.C

-- These will be populated during initialization
C.SETTINGS_TABLE = {} -- This is for key lookups into the Modules table but beware of unordered traversal!
C.INCOMPATIBLE_MODULE_NAMES = {}
C.MODULES = {}

C.GET_SPELL_NAME = C_Spell and C_Spell.GetSpellName or GetSpellInfo
C.GET_SPELL_DESCRIPTION = C_Spell and C_Spell.GetSpellDescription or GetSpellDescription

C.DUMMY_FUNCTION = function() end -- Will re-use this single function when we need a dummy function.

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

C.BACKDROP_INFO = function(edgeSize, insetSize, isTotalDarkBackground)
  local bgFile = isTotalDarkBackground and 'Interface/CharacterFrame/UI-Party-Background'
    or 'Interface/Tooltips/UI-Tooltip-Background'

  return {
    bgFile = bgFile,
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

C.SetupMoveableFrame = function(moveableFrame, frameInfoKey, anchoringCallback)
  moveableFrame:EnableMouse(true)
  moveableFrame:SetMovable(true)

  local frameInfo = UIChanges_Profile[frameInfoKey]

  if frameInfo and frameInfo.point ~= nil then
    local point = frameInfo.point
    local relativeTo = frameInfo.relativeTo
    local relativePoint = frameInfo.relativePoint
    local offsetX = frameInfo.offsetX
    local offsetY = frameInfo.offsetY

    local status, _ = pcall(function () moveableFrame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end)
    if status == false then
      UIChanges_Profile[frameInfoKey] = {}

      anchoringCallback()
    else
      moveableFrame:SetUserPlaced(true)
    end
  else
    anchoringCallback()
  end

  moveableFrame:SetScript('OnMouseDown', function(frame)
    if IsControlKeyDown() == true then
      frame:StartMoving()
    end
  end)

  moveableFrame:SetScript('OnMouseUp', function(frame)
    frame:StopMovingOrSizing()

    local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()

    UIChanges_Profile[frameInfoKey] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      offsetX = math.floor(offsetX),
      offsetY = math.floor(offsetY),
    }
  end)
end

C.InitializeMoveableFrame = function(moveableFrame, frameInfoKey, anchoringCallback, width, height, edgeSize, backdropColorTable)
  moveableFrame:SetSize(width, height)
  moveableFrame:SetBackdrop(C.BACKDROP_INFO(edgeSize, 1))
  moveableFrame:SetBackdropColor(unpack(backdropColorTable))
  moveableFrame:SetClampedToScreen(true)
  moveableFrame:Hide()

  C.SetupMoveableFrame(moveableFrame, frameInfoKey, anchoringCallback)
end

-- Injects the strings that need additional work. The work here is needed regardless of the language being used
-- by the client. Having this function here prevents code duplication in locale files.
local buildCommonStrings = function (L)
  local colorWhite = '|cFFFFFFFF'
  local colorRed = '|cFFFF0000'
  local colorOrange = '|cFFFF8000'
  local colorEscape = '|r'

  L.GET_INCOMPATIBLE_MODULES_TEXT = function()
    if #C.INCOMPATIBLE_MODULE_NAMES < 1 then
      return nil
    end

    local list = colorOrange .. L.INCOMPATIBLE_MODULES_TEXT .. colorWhite .. '\n'

    return list .. table.concat(C.INCOMPATIBLE_MODULE_NAMES, ', ') .. colorEscape
  end

  L.TXT_NOT_CLASSIC = colorRed .. L.TXT_NOT_CLASSIC_1 .. colorEscape
  L.OPTIONS_INFO = colorRed .. L.OPTIONS_INFO_1 .. colorEscape

  L.PPF = {L.PPF_1, colorRed .. L.PPF_2 ..colorEscape}

  local AbsorbDisplayStringHelper = function()
    local namePws = C.GET_SPELL_NAME(17)
    local nameSacrifice = C.GET_SPELL_NAME(7812)
  
    local spellstoneId = 128
    if LE_EXPANSION_LEVEL_CURRENT > LE_EXPANSION_BURNING_CRUSADE then
      spellstoneId = 54730
    end
  
    local nameSpellstone = C.GET_SPELL_NAME(spellstoneId)

    if not nameSpellstone then
      return namePws..' & '..nameSacrifice..'.'
    end
  
    return namePws..', '..nameSacrifice..' & '..nameSpellstone..'.'
  end

  L.AD = {L.ABSORB_DISPLAY_1 .. AbsorbDisplayStringHelper(), L.ABSORB_DISPLAY_2}
  
  local buildCriticalRemindersVariables = function(L)
    for variableName, value in pairs(L.CR_SUBSETTING_STRINGS) do
      local shortName = ''

      for word in string.gmatch(value, '[^%s]+') do -- Tokenize on spaces
        -- Get the first character. Avoid string.sub in case we have non-ascii characters.
        shortName = shortName .. word:gmatch(".[\128-\191]*")()
      end

      local soundText = shortName .. ' ' ..SOUND
      
      L[variableName] = value
      L[variableName .. '_SOUND'] = soundText
      L[variableName .. '_SOUND_TOOLTIP'] = L.PLAY_SOUND .. ' ' .. value .. colorEscape
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
end

C.DEFINE_MODULES = function()
  -- Anything that needs the localization table needs to wait until after the localization setup
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

  local buildCheckboxEntry = function(entryKey, defaultValue, title, tooltipText)
    local entry = {}
  
    entry['entryKey'] = entryKey
    entry['entryType'] = 'checkbox'
    entry['defaultValue'] = defaultValue
    entry['title'] = title
    entry['tooltipText'] = tooltipText
  
    return entry
  end

  -- Each warning entry comes with a relevant sound entry
  local CR_BuildWarningEntries = function(entryKey, defaultValue, titleVariableName, soundEntryDefaultValue)
    local warningEntryTitle = L[titleVariableName]

    local soundEntryKey = entryKey .. '_Sound'
    local soundEntryTitle = L[titleVariableName .. '_SOUND']
    local soundEntryTooltip = L[titleVariableName .. '_SOUND' .. '_TOOLTIP']

    local warningEntry = buildCheckboxEntry(entryKey, defaultValue, warningEntryTitle)
    local soundEntry = buildCheckboxEntry(soundEntryKey, soundEntryDefaultValue, soundEntryTitle, soundEntryTooltip)

    -- We want the sound entry checkbox to be inactive if the warning entry is disabled.
    warningEntry['dependents'] = {soundEntryKey}

    return warningEntry, soundEntry
  end

  local CR_SubsettingBuilder = function(checkboxEntries, otherEntries)
    local entries = {}

    for i, checkboxEntry in ipairs(checkboxEntries) do
      local warningEntry, soundEntry = CR_BuildWarningEntries(unpack(checkboxEntry))

      entries[#entries + 1] = warningEntry
      entries[#entries + 1] = soundEntry
    end

    for _, otherEntry in ipairs(otherEntries) do
      entries[#entries + 1] = otherEntry
    end

    return entries
  end

  local allModules = {
    {
      ['frameName'] = 'BM', -- This is the base module to store base settings. It does not have a moduleKey.
      ['checkCompatibility'] = function() return true end,
      ['subsettings'] = {
        -- Having the offsetX, offsetY or rowSize attributes here will override the defaults to fine tune the layout per module.
        ['entries'] = {
          buildCheckboxEntry('UIC_Toggle_Quick_Zoom', true, L.MINIMAP_QUICK_ZOOM, L.TOOLTIP_MINIMAP_QUICK_ZOOM),
        },
      },
    },
    {
      ['moduleName'] = 'AbsorbDisplay', -- The key corresponds to the class that is exported in the module file
      ['moduleKey'] = 'UIC_AD_IsEnabled', -- Name of the corresponding entry in UIChanges_Profile
      ['defaultValue'] = true, -- Is enabled by default
      ['frameName'] = 'AD', -- Used in subframe names
      ['title'] = 'Absorb Display',
      ['description'] = L.AD,
      ['checkCompatibility'] = function() return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_CATACLYSM end,
      ['subsettings'] = { -- If a module is disabled, it's subsetting widgets in the options page will be unavailable.
        ['entries'] = {
          {
            ['entryKey'] = 'UIC_AD_FrameInfo', -- Matches the entry in UIChanges_Profile
            ['entryType'] = 'button', -- Unlike other subsetting types, buttons do not display the value of the relevant
            ['defaultValue'] = {}, --  entry in UIChanges_Profile. The button is just a way to reset the value.
            ['title'] = RESET_POSITION,
            ['updateCallback'] = function() addonTable.AbsorbDisplay:ResetDisplayLocation() end,
          },
        },
      },
    },
    {
      ['moduleName'] = 'AHTools',
      ['moduleKey'] = 'UIC_AHT_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'AHT',
      ['title'] = 'Auction House Tools',
      ['description'] = L.AHT,
      ['checkCompatibility'] = function() return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_CATACLYSM end,
    },
    {
      ['moduleName'] = 'BagUtilities',
      ['moduleKey'] = 'UIC_BU_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'BU',
      ['title'] = 'Bag Utilities',
      ['description'] = L.BU,
      ['checkCompatibility'] = function() return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_BURNING_CRUSADE end,
    },
    {
      ['moduleName'] = 'CriticalReminders',
      ['moduleKey'] = 'UIC_CR_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'CR',
      ['title'] = 'Critical Reminders',
      ['description'] = L.CR,
      ['checkCompatibility'] = function() return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_MISTS_OF_PANDARIA end,
      ['subsettings'] = {
        ['separator'] = { -- To draw a straight line in the middle of all the subsetting checkboxes
          ['topFrame'] = 3, -- These are hardcoded indices for the frames the line will be drawn relative to
          ['bottomFrame'] = 19, -- The numbers are derived from the entries defined below
        },
        ['entries'] = CR_SubsettingBuilder(
          { -- CheckboxEntries
            {'UIC_CR_BreathWarning',      true,   'BREATH_WARNING',     true},
            {'UIC_CR_CombatWarning',      true,   'COMBAT_WARNING',     false},
            {'UIC_CR_GatheringFailure',   true,   'GATHERING_FAILURE',  false},
            {'UIC_CR_CombatLos',          true,   'COMBAT_LOS',         false},
            {'UIC_CR_CombatDirection',    false,  'COMBAT_DIRECTION',   false},
            {'UIC_CR_CombatRange',        false,  'COMBAT_RANGE',       false},
            {'UIC_CR_CombatInterrupted',  false,  'COMBAT_INTERRUPTED', false},
            {'UIC_CR_CombatCooldown',     false,  'COMBAT_COOLDOWN',    false},
            {'UIC_CR_CombatNoResource',   false,  'COMBAT_NO_RESOURCE', false},
            {'UIC_CR_InteractionRange',   false,  'INTERACTION_RANGE',  false},
          },
          { -- OtherEntries
            {
              ['entryKey'] = 'UIC_CR_ErrorFrameAnchor',
              ['entryType'] = 'dropdown',
              ['defaultValue'] = 1, -- 1 is off
              ['title'] = L.ERROR_FRAME_ANCHOR_DROPDOWN,
              ['dropdownEnum'] = C.ENUM_ANCHOR_OPTIONS, -- The dropdown options will be populated from this enum
              ['updateCallback'] = function() addonTable.CriticalReminders:Update() end,
              ['dependents'] = {'UIC_CR_ErrorFrameInfo'}, -- The reset button should be disabled if this setting is active
            },
            {
              ['entryKey'] = 'UIC_CR_ErrorFrameInfo',
              ['entryType'] = 'button',
              ['defaultValue'] = {},
              ['title'] = RESET_POSITION,
              ['updateCallback'] = function() addonTable.CriticalReminders:ResetErrorFrameLocation() end,
            },
          }
        ),
      },
    },
    {
      ['moduleName'] = 'DruidManaBar',
      ['moduleKey'] = 'UIC_DMB_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'DMB',
      ['title'] = 'Druid Mana Bar',
      ['description'] = L.DMB,
      ['checkCompatibility'] = function()
        return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_BURNING_CRUSADE and select(2, UnitClass('player')) == 'DRUID'
      end,
    },
    {
      ['moduleName'] = 'PartyPetFrames',
      ['moduleKey'] = 'UIC_PPF_IsEnabled',
      ['defaultValue'] = GetCVar('showPartyPets') == 1, -- We can run this by the time DEFINE_MODULES() is called
      ['frameName'] = 'PPF',
      ['title'] = 'Party Pet Frames',
      ['description'] = L.PPF,
      ['checkCompatibility'] = function() return LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_MISTS_OF_PANDARIA end,
      -- If a module's state is tied to a console variable, that must be declared here. Such modules must be toggled outside of combat.
      ['consoleVariableName'] = 'showPartyPets', -- This is the name of the cVar that will be modified when this module's state is modified
    },
    {
      ['moduleName'] = 'PingAnnouncer',
      ['moduleKey'] = 'UIC_PA_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'PA',
      ['title'] = 'Ping Announcer',
      ['description'] = L.PA,
      ['checkCompatibility'] = function() return true end,
      ['subsettings'] = {
        ['entries'] = {
          buildCheckboxEntry('UIC_PA_Raid', false, RAID),
          buildCheckboxEntry('UIC_PA_Arena', false, ARENA),
          buildCheckboxEntry('UIC_PA_Battleground', false, BATTLEGROUND),
          buildCheckboxEntry('UIC_PA_Party', true, PARTY),
        }
      },
    },
    {
      ['moduleName'] = 'SpellTargetDisplay',
      ['moduleKey'] = 'UIC_STD_IsEnabled',
      ['defaultValue'] = true,
      ['frameName'] = 'STD',
      ['title'] = 'Spell Target Display',
      ['description'] = L.STD,
      ['checkCompatibility'] = function() return true end,
      ['subsettings'] = {
        ['entries'] = {
          {
            ['entryKey'] = 'UIC_STD_FrameInfo',
            ['entryType'] = 'button',
            ['defaultValue'] = {},
            ['title'] = RESET_POSITION,
            ['updateCallback'] = function() addonTable.SpellTargetDisplay:ResetTargetNameFrameLocation() end,
          },
        },
      },
    },
  }

  local addSubsetting = function(subsettingEntry, parentName)
    -- Add the subsetting to the settings and defaults tables
    local entryKey = subsettingEntry['entryKey']
    local defaultValue = subsettingEntry['defaultValue']
    local title = subsettingEntry['title']

    C.SETTINGS_TABLE[entryKey] = subsettingEntry

    -- Set these here for easy lookup in Options
    subsettingEntry['frameName'] = ('UIC_Subsetting_'..parentName..'_'..title):gsub('%s+', '_') -- Remove spaces
  end

  local addModuleToggle = function(moduleEntry)
    local className = moduleEntry['moduleName'] -- The base module doesn't have this attribute

    if className then
      -- Add the module toggle to the settings and defaults tables
      local moduleKey = moduleEntry['moduleKey']

      C.SETTINGS_TABLE[moduleKey] = moduleEntry

      -- Module states will be altered when their option frames' are clicked on
      moduleEntry['updateCallback'] = function(newValue)
        local module = addonTable[className]
        
        if newValue then
          module:Enable()
        else
          module:Disable()
        end
      end
    end
  end

  -- Setup the lookup table & the attributes that will be used in the options panel
  local populateSettingsTable = function()
    for _, moduleEntry in ipairs(C.MODULES) do
      addModuleToggle(moduleEntry)

      if moduleEntry['subsettings'] then
        local subsettingEntries = moduleEntry['subsettings']['entries']
        local parentName = moduleEntry['frameName']
  
        for i, subsettingEntry in ipairs(subsettingEntries) do
          addSubsetting(subsettingEntry, parentName)
        end
      end
    end
  end

  -- Check each module for compatibility
  for _, moduleEntry in ipairs(allModules) do
    if moduleEntry['checkCompatibility']() then
      C.MODULES[#C.MODULES + 1] = moduleEntry
    else
      if moduleEntry['moduleName'] then
        C.INCOMPATIBLE_MODULE_NAMES[#C.INCOMPATIBLE_MODULE_NAMES + 1] = moduleEntry['moduleName']
      end
    end
  end

  populateSettingsTable()
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

  -- Initialize variables if they haven't been initialized already. Unordered traversal is okay here.
  for settingName, entry in pairs(C.SETTINGS_TABLE) do
    local defaultValue = entry['defaultValue']

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
