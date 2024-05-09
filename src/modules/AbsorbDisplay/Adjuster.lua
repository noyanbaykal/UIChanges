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

local C = addonTable.C

-- Spells scale with the caster's level, resulting in a range of amount to amountMax. There isn't a
-- clean way of accounting for this except when the player is the one casting.
-- In that case we can read the spell tooltip which includes the correct base value, including
-- any talent modifiers. Spell power from gear will be added on top of this base value.
-- Spells cast by others will default to amount as an approximation. Unless the player is at max level
-- in which case we'll assume they are playing with other max level players and we'll use amountMax.
-- The data & lookup tables may be altered in adjustDataTables based on expansion.
-- Data read from tooltips will be stored the data tables with the 'current' key.

-- Spell ranks go away with Cataclysm.
-- The spell tooltips in the Cataclysm client seem to take into account all factors and display the final
-- amounts so we can solely rely on the tooltips for selfcast spells. Unlike in previous expansions,
-- the SPELL_AURA_APPLIED event in Cataclysm provides the amount value. This is only base amount but we'll
-- use it for PWS casts by others.

-- In TBC and WOTLK the PWS shield amount formula is different and I can't test them at this time so
-- we'll read PWS tooltips only in vanilla for now.
local DATA_PWS = { -- Power Word: Shield
  {level = 6,  rank = 1,  spellId = 17,    amount = 44,   amountMax = 48},
  {level = 12, rank = 2,  spellId = 592,   amount = 88,   amountMax = 94},
  {level = 18, rank = 3,  spellId = 600,   amount = 158,  amountMax = 166},
  {level = 24, rank = 4,  spellId = 3747,  amount = 234,  amountMax = 244},
  {level = 30, rank = 5,  spellId = 6065,  amount = 301,  amountMax = 313},
  {level = 36, rank = 6,  spellId = 6066,  amount = 381,  amountMax = 394},
  {level = 42, rank = 7,  spellId = 10898, amount = 484,  amountMax = 499},
  {level = 48, rank = 8,  spellId = 10899, amount = 605,  amountMax = 622},
  {level = 54, rank = 9,  spellId = 10900, amount = 763,  amountMax = 783},
  {level = 60, rank = 10, spellId = 10901, amount = 942,  amountMax = 964},
  {level = 65, rank = 11, spellId = 25217, amount = 1125, amountMax = 1144},
  {level = 70, rank = 12, spellId = 25218, amount = 1265, amountMax = 1286},
  {level = 75, rank = 13, spellId = 48065, amount = 1920, amountMax = 1951},
  {level = 80, rank = 14, spellId = 48066, amount = 2230, amountMax = 2230},
}
-- The index values are used to separately track different types of shield amunts.
DATA_PWS.index = 1
-- We'll run a timer to hide the shield display for the odd cases of not receiving the SPELL_AURA_REMOVED event.
DATA_PWS.timerInterval = 32

-- Voidwalker ability. It scales with player level but does not benefit from spell power.
-- Downranking is not possible here and there will only be one rank present at any time (or none).
local DATA_SACRIFICE = {
  {level = 16, rank = 1,  spellId = 7812,  amount = 305,   amountMax = 319},
  {level = 24, rank = 2,  spellId = 19438, amount = 510,   amountMax = 529},
  {level = 32, rank = 3,  spellId = 19440, amount = 770,   amountMax = 794},
  {level = 40, rank = 4,  spellId = 19441, amount = 1095,  amountMax = 1124},
  {level = 48, rank = 5,  spellId = 19442, amount = 1470,  amountMax = 1503},
  {level = 56, rank = 6,  spellId = 19443, amount = 1905,  amountMax = 1944},
  {level = 64, rank = 7,  spellId = 27273, amount = 2855,  amountMax = 2900},
  {level = 72, rank = 8,  spellId = 47985, amount = 6750,  amountMax = 6810},
  {level = 79, rank = 9,  spellId = 47986, amount = 8350,  amountMax = 8365},
}
DATA_SACRIFICE.index = 2
DATA_SACRIFICE.timerInterval = 32

-- This selfcast effect is present only in vanilla. It doesn't scale with player level or benefit from spell power.
-- The spellIds refer to the spell effects, the sourceIds refer to the spells for conjuring the spellstones.
local DATA_SPELLSTONE = {
  {level = 31, rank = 1, spellId = 128,   sourceId = 2362,  amount = 400},
  {level = 43, rank = 2, spellId = 17729, sourceId = 17727, amount = 650},
  {level = 55, rank = 3, spellId = 17730, sourceId = 17728, amount = 900},
}
DATA_SPELLSTONE.index = 3
DATA_SPELLSTONE.timerInterval = 62

local ITEM_SET_249 = {51262, 51263, 51264, 51260, 51261} -- https://www.wowhead.com/wotlk/item-set=-249/sanctified-crimson-acolytes-raiment
local ITEM_SET_230 = {51177, 51176, 51175, 51179, 51178} -- https://www.wowhead.com/wotlk/item-set=-230/sanctified-crimson-acolytes-raiment
local ITEM_SET_841 = {50769, 50768, 50767, 50766, 50765} -- https://www.wowhead.com/wotlk/item-set=-841/crimson-acolytes-raiment
local ITEM_SET_885 = {51732, 51733, 51734, 51735, 51736} -- https://www.wowhead.com/wotlk/item-set=885/crimson-acolytes-raiment

-- https://www.wowhead.com/wotlk/spell=70798/item-priest-t10-healer-4p-bonus
local PRIEST_T10_SETS = {ITEM_SET_249, ITEM_SET_230, ITEM_SET_841, ITEM_SET_885}

local playerName, playerLevel

local maxLevel = 80 -- May be adjusted in adjustDataForExpansion
local spellpowerCoefficientPWS = 0.1 -- May be adjusted in adjustDataForExpansion

-- Vanilla coefficients: https://www.reddit.com/r/classicwow/comments/95abc8/list_of_spellcoefficients_1121/
-- TBC coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient?oldid=1492745
-- WOTLK coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient

local setBonusModifierPWS = 1 -- Item - Priest T10 Healer 4P Bonus, 70798, only in WOTLK
local talentModifierIPWS = 1 -- Improved Power Word: Shield
local talentCoefficientBonusBT = 0 -- Borrowed Time, only in WOTLK

local spellpower = 0

local checkTooltips = C.DUMMY_FUNCTION -- These will be set differently based on expansion
local checkTalents = C.DUMMY_FUNCTION
local checkItemBonuses = C.DUMMY_FUNCTION

-- This is a lookup table for direct access to data table entries by spellId
local spellLookup

-- Cataclysm and later
local removeSpellRanks = function(dataTable)
  for i = #dataTable, 2, -1 do
    dataTable[i] = nil
  end

  dataTable[1].rank = nil
  dataTable[1].amount = nil
  dataTable[1].amountMax = nil
end

-- Helper called in Vanilla and TBC to remove spell entries from later expansions
local removeLaterEntries = function(dataTable)
  for i = #dataTable, 1, -1 do
    local entry = dataTable[i]
    
    if entry.level > maxLevel then
      table.remove(dataTable, i)
    else
      if entry.level == maxLevel then
        entry.amountMax = entry.amount -- This spell can only be learned at maxLevel so it won't scale any further
      end

      break
    end
  end
end

local adjustDataForExpansion = function()
  if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
    maxLevel = 60
    spellpowerCoefficientPWS = 0.1

    removeLaterEntries(DATA_PWS)
    removeLaterEntries(DATA_SACRIFICE)
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
    maxLevel = 70
    spellpowerCoefficientPWS = 0.3

    removeLaterEntries(DATA_PWS)
    removeLaterEntries(DATA_SACRIFICE)

    DATA_SPELLSTONE = nil
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
    maxLevel = 80
    spellpowerCoefficientPWS = 0.8068

    DATA_SPELLSTONE = nil
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CATACLYSM then
    maxLevel = 85
    spellpowerCoefficientPWS = 0.87

    removeSpellRanks(DATA_PWS)
    removeSpellRanks(DATA_SACRIFICE)

    DATA_PWS[1].level = 5
    DATA_SACRIFICE[1].level = 1

    DATA_SPELLSTONE = nil
  end
end

-- https://warcraft.wiki.gg/wiki/ItemLink
local getEquippedItemId = function(slot)
  local itemLink = GetInventoryItemLink('player', slot)
  if itemLink == nil then
    return nil
  end

  local _, payloadStart = string.find(itemLink, 'Hitem:')
  payloadStart = payloadStart + 1

  local payloadEnd, _ = string.find(itemLink, ':', payloadStart)
  payloadEnd = payloadEnd - 1

  return string.sub(itemLink, payloadStart, payloadEnd)
end

local hasT10Bonus = function()
  local equippedItems = {
    getEquippedItemId(7), -- legs
    getEquippedItemId(5), -- chest
    getEquippedItemId(3), -- shoulder
    getEquippedItemId(10), -- hand
    getEquippedItemId(1), -- head
  }

  local neededPieceCount = 4

  for _, setItems in pairs(PRIEST_T10_SETS) do
    local count = 0

    for i = 1, #setItems, 1 do
      if equippedItems[i] == setItems[i] then
        count = count + 1
      end
    end

    if count >= neededPieceCount then
      return true
    end
  end

  return false
end

local onLevelUp = function(newLevel)
  playerLevel = newLevel
end

local checkTooltipsHelper = function(dataTable)
  for i = 1, #dataTable do
    local spellId = dataTable[i].spellId
    local sourceId = dataTable[i].sourceId

    if IsSpellKnown(spellId) or IsSpellKnown(spellId, true) or (sourceId and IsSpellKnown(sourceId)) then
      local text = GetSpellDescription(spellId)
      local firstNumber = string.match(text, '%d+')
  
      dataTable[i].current = tonumber(firstNumber)
    end
  end
end

local calculateAmountPwsOther = function(_, buffEntry, _, baseAmount)
  if baseAmount then -- Only in Cataclysm
    return baseAmount
  end

  return playerLevel == maxLevel and buffEntry.amountMax or buffEntry.amount
end

local calculateAmountPwsPriest = function(selfCastHelper)
  return function(dataTable, buffEntry, sourceName)
    if sourceName == playerName then
      return selfCastHelper(dataTable, buffEntry)
    else
      return calculateAmountPwsOther(dataTable, buffEntry)
    end
  end
end

-- If the player is at max level, all spell ranks are scaled to their amountMax.
-- If the player is not at max level but is casting a downranked spell, check if they are high level enough
-- to learn the next rank in which case the downranked spell would be scaled to its amountMax.
-- Otherwise default to amount where we might return a slightly lower value since we can't easily account for the
-- spell scaling between player levels.
local getSelfcastApproximateAmount = function(dataTable, buffEntry)
  if playerLevel == maxLevel or (buffEntry.rank ~= #dataTable and playerLevel >= dataTable[buffEntry.rank + 1].level) then
    return buffEntry.amountMax
  end
  
  return buffEntry.amount
end

local selfcastHelperPwsExpansion = function(dataTable, buffEntry)
  local baseAmount = getSelfcastApproximateAmount(dataTable, buffEntry)

  local coefficient = spellpowerCoefficientPWS + talentCoefficientBonusBT

  local finalAmount = (baseAmount + (spellpower * coefficient)) * talentModifierIPWS * setBonusModifierPWS
  return math.ceil(finalAmount)
end

local checkTalentIpws = function(columnIndex)
  local _, _, _, _, ipwsRank = GetTalentInfo(1, columnIndex)
  talentModifierIPWS = 1 + (ipwsRank * 0.05)
end

local checkItemBonusesPriestPreWotlk = function()
  spellpower = GetSpellBonusHealing() or 0
end

local adjustPriest = function()
  if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
    local selfCastHelper = function(_, buffEntry)
      -- talentModifierIPWS is baked into buffEntry.current
      local baseAmount = buffEntry.current or buffEntry.amount -- Have a fallback
      return math.ceil(baseAmount + (spellpower * spellpowerCoefficientPWS))
    end

    DATA_PWS.calculateAmount = calculateAmountPwsPriest(selfCastHelper)

    checkTooltips = function()
      checkTooltipsHelper(DATA_PWS)
    end

    checkTalents = function()
      checkTalentIpws(5)
    end

    checkItemBonuses = checkItemBonusesPriestPreWotlk
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
    DATA_PWS.calculateAmount = calculateAmountPwsPriest(selfcastHelperPwsExpansion)

    checkTalents = function()
      checkTalentIpws(5)
    end

    checkItemBonuses = checkItemBonusesPriestPreWotlk
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
    DATA_PWS.calculateAmount = calculateAmountPwsPriest(selfcastHelperPwsExpansion)

    checkTalents = function()
      checkTalentIpws(9)

      local _, _, _, _, btRank = GetTalentInfo(1, 27)
      talentCoefficientBonusBT = btRank * 0.08
    end

    checkItemBonuses = function()
      spellpower = GetSpellBonusDamage(2) or 0
      setBonusModifierPWS = hasT10Bonus() and 1.05 or 1
    end
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CATACLYSM then
    DATA_PWS.calculateAmount = function(dataTable, buffEntry, sourceName, baseAmount)
      if sourceName == playerName then
        return buffEntry.current
      else
        return calculateAmountPwsOther(dataTable, buffEntry, sourceName, baseAmount)
      end
    end

    checkTooltips = function()
      checkTooltipsHelper(DATA_PWS)
    end
  end
end

local checkTooltipsWarlockExpansion = function()
  checkTooltipsHelper(DATA_SACRIFICE)
end

local adjustWarlock = function()
  DATA_SACRIFICE.calculateAmount = function(_, buffEntry)
    --talentModifierSacrifice is baked into buffEntry.current
    return math.ceil(buffEntry.current or buffEntry.amount) -- Have a fallback
  end

  if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
    DATA_SPELLSTONE.calculateAmount = function(_, buffEntry)
      --talentModifierSpellstone is baked into buffEntry.current
      return math.ceil(buffEntry.current or buffEntry.amount) -- Have a fallback
    end

    checkTooltips = function()
      checkTooltipsHelper(DATA_SACRIFICE)
      checkTooltipsHelper(DATA_SPELLSTONE)
    end
  elseif LE_EXPANSION_LEVEL_CURRENT <= LE_EXPANSION_CATACLYSM then
    checkTooltips = checkTooltipsWarlockExpansion
  end
end

local addLookupEntries = function(dataTable, timerCallback)
  if not dataTable or not dataTable[1] then
    return
  end

  spellLookup.activeTables[#spellLookup.activeTables + 1] = dataTable

  -- We'll need to reference the data tables too. Use the spell name for that.
  local spellName = GetSpellInfo(dataTable[1].spellId)
  spellLookup[spellName] = dataTable
  dataTable.spellName = spellName

  -- Set up callbacks for the timers so we don't have to keep creating new functions
  dataTable.backupTimerCallback = function()
    timerCallback(dataTable)
  end

  for _, entry in ipairs(dataTable) do
    spellLookup[entry.spellId] = entry

    local currentSpellName = GetSpellInfo(entry.spellId)
    if currentSpellName ~= spellName then -- For spells that have different names per rank
      spellLookup[currentSpellName] = dataTable
    end
  end
end

local AdjustShieldSpellData = function(name, playerClass, timerCallback)
  playerName = name
  playerLevel = UnitLevel('player')

  adjustDataForExpansion()

  if playerClass == 'WARLOCK' then
    DATA_PWS.calculateAmount = calculateAmountPwsOther

    adjustWarlock()
  elseif playerClass == 'PRIEST' then
    DATA_SACRIFICE = nil
    DATA_SPELLSTONE = nil

    adjustPriest()
  else
    DATA_PWS.calculateAmount = calculateAmountPwsOther
    DATA_SACRIFICE = nil
    DATA_SPELLSTONE = nil
  end

  -- Setup the spell lookups
  spellLookup = {}
  spellLookup.activeTables = {}

  addLookupEntries(DATA_PWS, timerCallback)
  addLookupEntries(DATA_SACRIFICE, timerCallback)
  addLookupEntries(DATA_SPELLSTONE, timerCallback)

  return spellLookup, checkTooltips, checkTalents, checkItemBonuses, onLevelUp
end

addonTable.AdjustShieldSpellData = AdjustShieldSpellData
