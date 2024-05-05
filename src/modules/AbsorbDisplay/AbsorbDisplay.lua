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

local L = addonTable.L
local C = addonTable.C

-- Spells scale with the caster's level, resulting in a range of amount to amountMax. There isn't a
-- clean way of accounting for this except when the player is the one casting.
-- In that case, in vanilla, we can read the spell tooltip which includes the correct base value, including
-- any talent modifiers. Spell power from gear will be added on top of this base value.
-- In TBC or WOTLK the PWS shield amount formula is different and I can't test them at this time so we'll
-- read PWS tooltips only in vanilla for now.
-- As an approximation, spells cast by others will default to amount, unless the player is at max level.
-- The data & lookup tables may be altered in adjustDataTables based on expansion.
-- Data read from tooltips will be stored here with the 'current' key.
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
-- Set up lookups
DATA_PWS[17] = DATA_PWS[1]
DATA_PWS[592] = DATA_PWS[2]
DATA_PWS[600] = DATA_PWS[3]
DATA_PWS[3747] = DATA_PWS[4]
DATA_PWS[6065] = DATA_PWS[5]
DATA_PWS[6066] = DATA_PWS[6]
DATA_PWS[10898] = DATA_PWS[7]
DATA_PWS[10899] = DATA_PWS[8]
DATA_PWS[10900] = DATA_PWS[9]
DATA_PWS[10901] = DATA_PWS[10]
DATA_PWS[25217] = DATA_PWS[11]
DATA_PWS[25218] = DATA_PWS[12]
DATA_PWS[48065] = DATA_PWS[13]
DATA_PWS[48066] = DATA_PWS[14]
DATA_PWS.index = 1

-- Voidwalker ability. It scales with player level but does not benefit from spell power.
-- Downranking is not possible here and there will only be one rank present at any time (or none).
-- In vanilla we'll store the current values from tooltips.
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
-- Set up lookups
DATA_SACRIFICE[7812] = DATA_SACRIFICE[1]
DATA_SACRIFICE[19438] = DATA_SACRIFICE[2]
DATA_SACRIFICE[19440] = DATA_SACRIFICE[3]
DATA_SACRIFICE[19441] = DATA_SACRIFICE[4]
DATA_SACRIFICE[19442] = DATA_SACRIFICE[5]
DATA_SACRIFICE[19443] = DATA_SACRIFICE[6]
DATA_SACRIFICE[27273] = DATA_SACRIFICE[7]
DATA_SACRIFICE[47985] = DATA_SACRIFICE[8]
DATA_SACRIFICE[47986] = DATA_SACRIFICE[9]
DATA_SACRIFICE.index = 2

-- This selfcast effect is present only in vanilla. It doesn't scale with player level or benefit from spell power.
-- The spellIds refer to the spells for conjuring the spellstones. The effectIds will show up in the combat log.
-- We'll update the current amounts from the tooltips.
local DATA_SPELLSTONE = {
  {level = 31, rank = 1, spellId = 2362,  effectId = 128,   amount = 400},
  {level = 43, rank = 2, spellId = 17727, effectId = 17729, amount = 650},
  {level = 55, rank = 3, spellId = 17728, effectId = 17730, amount = 900},
}
-- Set up lookups for the spellIds & effectIds
DATA_SPELLSTONE[2362] = DATA_SPELLSTONE[1]
DATA_SPELLSTONE[128] = DATA_SPELLSTONE[1]
DATA_SPELLSTONE[17727] = DATA_SPELLSTONE[2]
DATA_SPELLSTONE[17729] = DATA_SPELLSTONE[2]
DATA_SPELLSTONE[17728] = DATA_SPELLSTONE[3]
DATA_SPELLSTONE[17730] = DATA_SPELLSTONE[3]
DATA_SPELLSTONE.index = 3

local WEAKENED_SOUL = GetSpellInfo(6788)

local SHIELD_COLOR = {1, 1, 0.353, 1}

local SHIELD_COLOR_EXPENDED = {1, 1, 0.353, 0.5}

-- When the spellsource is another player we cannot get the real shield amount and therefore
-- are unable to account for extra shielding that comes from talents or spell power .If we happen
-- to have absorbs above the base amount, we'll display that fact instead of a numeric amount.
local SHIELD_COLOR_RESIDUAL = {1, 0.386, 0.2, 1}

local SPELL_SHIELD_COLOR = {0, 0, 1, 1}

local SPELL_SHIELD_COLOR_EXPENDED = {0, 0, 1, 0.5}

local ITEM_SET_249 = {51262, 51263, 51264, 51260, 51261}-- https://www.wowhead.com/wotlk/item-set=-249/sanctified-crimson-acolytes-raiment
local ITEM_SET_230 = {51177, 51176, 51175, 51179, 51178} -- https://www.wowhead.com/wotlk/item-set=-230/sanctified-crimson-acolytes-raiment
local ITEM_SET_841 = {50769, 50768, 50767, 50766, 50765} -- https://www.wowhead.com/wotlk/item-set=-841/crimson-acolytes-raiment
local ITEM_SET_885 = {51732, 51733, 51734, 51735, 51736} -- https://www.wowhead.com/wotlk/item-set=885/crimson-acolytes-raiment

-- https://www.wowhead.com/wotlk/spell=70798/item-priest-t10-healer-4p-bonus
local PRIEST_T10_SETS = {ITEM_SET_249, ITEM_SET_230, ITEM_SET_841, ITEM_SET_885}

-- Sometimes the aura_removed event for pws isn't sent. We'll run a timer as a backup to remove the shield display.
local TIMER_INTERVAL_PWS = 17 -- Seconds
local TIMER_INTERVAL_SACRIFICE = 32 -- Seconds
local TIMER_INTERVAL_SPELLSTONE = 62 -- Seconds
local BASE_OFFSET_Y = 150
local SHIELD_WIDTH_MAX = 120
local SHIELD_WIDTH_RESIDUAL = 12

local playerName, playerClass, playerLevel
local mainFrame, shieldFrame, spellShieldFrame, shields, backupTimer, spellLookup

local maxLevel = 80 -- May be adjusted in adjustDataForExpansion
local spellpowerCoefficientPWS = 0.1 -- May be adjusted in adjustDataForExpansion

local setBonusModifierPWS = 1 -- Item - Priest T10 Healer 4P Bonus, 70798, only in WOTLK
local talentModifierIPWS = 1 -- Improved Power Word: Shield
local talentCoefficientBonusBT = 0 -- Borrowed Time, only in WOTLK
local talentModifierSacrifice = 1
local talentModifierSpellstone = 1

local spellpower = 0

-- These will get set differently based on expansion
local calculateAmountSelfcastPws = C.DUMMY_FUNCTION
local checkTooltips = C.DUMMY_FUNCTION
local checkTalents = C.DUMMY_FUNCTION
local checkItemBonuses = C.DUMMY_FUNCTION

local adjustDataForExpansion = function()
  if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
    maxLevel = 60

    DATA_PWS[10].amountMax = DATA_PWS[10].amount

    DATA_PWS[11] = nil
    DATA_PWS[12] = nil
    DATA_PWS[13] = nil
    DATA_PWS[14] = nil

    DATA_PWS[25217] = nil
    DATA_PWS[25218] = nil
    DATA_PWS[48065] = nil
    DATA_PWS[48066] = nil

    DATA_SACRIFICE[7] = nil
    DATA_SACRIFICE[8] = nil
    DATA_SACRIFICE[9] = nil

    DATA_SACRIFICE[27273] = nil
    DATA_SACRIFICE[47985] = nil
    DATA_SACRIFICE[47986] = nil

    spellpowerCoefficientPWS = 0.1
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
    maxLevel = 70

    DATA_PWS[12].amountMax = DATA_PWS[12].amount

    DATA_PWS[13] = nil
    DATA_PWS[14] = nil

    DATA_PWS[48065] = nil
    DATA_PWS[48066] = nil

    DATA_SACRIFICE[8] = nil
    DATA_SACRIFICE[9] = nil

    DATA_SACRIFICE[47985] = nil
    DATA_SACRIFICE[47986] = nil

    spellpowerCoefficientPWS = 0.3
  elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
    maxLevel = 80

    spellpowerCoefficientPWS = 0.8068
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

local checkTooltipsHelper = function(dataTable)
  for i = 1, #dataTable do
    local spellId = dataTable[i].spellId

    if not IsSpellKnown(spellId) then
      break
    end

    local text = GetSpellDescription(spellId)
    local firstNumber = string.match(text, '%d+')

    dataTable[spellId].current = firstNumber
  end
end

-- TODO: this could use a refactoring to introduce the maxlevel parameter!
local calculateAmountSelfcastPwsExpansion = function(dataTable, buffEntry)
  local baseAmount

  if playerLevel == maxLevel or buffEntry.rank == #dataTable or playerLevel >= dataTable[buffEntry.rank + 1].level then
    baseAmount = buffEntry.amountMax
  else
    baseAmount = buffEntry.amount
  end

  local coefficient = spellpowerCoefficientPWS + talentCoefficientBonusBT

  local finalAmount = (baseAmount + (spellpower * coefficient)) * talentModifierIPWS * setBonusModifierPWS
  return math.floor(finalAmount)
end


-- Vanilla coefficients: https://www.reddit.com/r/classicwow/comments/95abc8/list_of_spellcoefficients_1121/
-- TBC coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient?oldid=1492745
-- WOTLK coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient
local adjustFunctionsForExpansion = function()
  -- This is a lookup table for the shield spells we are interested in.
  -- Have to pick the right table based on localized spell name.
  spellLookup = {}

  local namePws = GetSpellInfo(17)
  spellLookup[namePws] = DATA_PWS

  DATA_PWS.calculateAmount = function(dataTable, buffEntry, sourceName)
    if sourceName == playerName then
      return calculateAmountSelfcastPws(dataTable, buffEntry)
    else
      return playerLevel == maxLevel and buffEntry.amountMax or buffEntry.amount
    end
  end


  if playerClass == 'PRIEST' then
    if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
      calculateAmountSelfcastPws = function(_, buffEntry)
        return math.floor(buffEntry.current or buffEntry.amount) -- Have a fallback
      end

      checkTooltips = function()
        checkTooltipsHelper(DATA_PWS)
      end

      checkTalents = function()
        local _, _, _, _, ipwsRank = GetTalentInfo(1, 5)
        talentModifierIPWS = 1 + (ipwsRank * 0.05)
      end

      checkItemBonuses = function()
        spellpower = GetSpellBonusHealing() or 0
      end
    elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
      calculateAmountSelfcastPws = calculateAmountSelfcastPwsExpansion

      checkTalents = function()
        local _, _, _, _, ipwsRank = GetTalentInfo(1, 5)
        talentModifierIPWS = 1 + (ipwsRank * 0.05)
      end

      checkItemBonuses = function()
        spellpower = GetSpellBonusHealing() or 0
      end
    elseif LE_EXPANSION_LEVEL_CURRENT < LE_EXPANSION_WRATH_OF_THE_LICH_KING then
      calculateAmountSelfcastPws = calculateAmountSelfcastPwsExpansion

      checkTalents = function()
        local _, _, _, _, ipwsRank = GetTalentInfo(1, 9)
        talentModifierIPWS = 1 + (ipwsRank * 0.05)

        local _, _, _, _, btRank = GetTalentInfo(1, 27)
        talentCoefficientBonusBT = btRank * 0.08
      end

      checkItemBonuses = function()
        spellpower = GetSpellBonusDamage(2) or 0
        setBonusModifierPWS = hasT10Bonus() and 1.05 or 1
      end
    end
  end

  if playerClass == 'WARLOCK' then
    local nameSacrifice = GetSpellInfo(7812)
    spellLookup[nameSacrifice] = DATA_SACRIFICE

    if LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC then
      checkTooltips = function()
        checkTooltipsHelper(DATA_SACRIFICE)
        checkTooltipsHelper(DATA_SPELLSTONE)
      end

      DATA_SACRIFICE.calculateAmount = function(_, buffEntry)
        return math.floor(buffEntry.current or buffEntry.amount) -- Have a fallback
      end

      DATA_SPELLSTONE.calculateAmount = function(_, buffEntry)
        return math.floor(buffEntry.current or buffEntry.amount) -- Have a fallback
      end

      local nameSpellstone = GetSpellInfo(128)
      local nameSpellstoneGreater = GetSpellInfo(17729)
      local nameSpellstoneMajor = GetSpellInfo(17730)

      spellLookup[nameSpellstone] = DATA_SPELLSTONE
      spellLookup[nameSpellstoneGreater] = DATA_SPELLSTONE
      spellLookup[nameSpellstoneMajor] = DATA_SPELLSTONE

      checkTalents = function()
        local _, _, _, _, sacrificeRank = GetTalentInfo(2, 5)
        talentModifierSacrifice = 1 + (sacrificeRank * 0.1)
  
        local _, _, _, _, spellstoneRank = GetTalentInfo(2, 17)
        talentModifierSpellstone = 1 + (spellstoneRank * 0.15)
      end
    elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_BURNING_CRUSADE then
      DATA_SACRIFICE.calculateAmount = function(dataTable, buffEntry)
        local amount
      
        if playerLevel == maxLevel or (buffEntry.rank ~= #dataTable and playerLevel >= dataTable[buffEntry.rank + 1].level) then
          amount = buffEntry.amountMax
        else
          amount = buffEntry.amount
        end
      
        return math.floor(amount * talentModifierSacrifice)
      end

      checkTalents = function()
        local _, _, _, _, sacrificeRank = GetTalentInfo(2, 5)
        talentModifierSacrifice = 1 + (sacrificeRank * 0.1)
      end
    elseif LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_WRATH_OF_THE_LICH_KING then
      DATA_SACRIFICE.calculateAmount = function(dataTable, buffEntry)
        local amount
      
        if playerLevel == maxLevel or (buffEntry.rank ~= #dataTable and playerLevel >= dataTable[buffEntry.rank + 1].level) then
          amount = buffEntry.amountMax
        else
          amount = buffEntry.amount
        end
      
        return math.floor(amount * talentModifierSacrifice)
      end

      checkTalents = function()
        local _, _, _, _, sacrificeRank = GetTalentInfo(2, 6)
        talentModifierSacrifice = 1 + (sacrificeRank * 0.1)
      end
    end
  end
end

local resetShields = function()
  shields[1].max = 0
  shields[1].left = 0
  shields[2].max = 0
  shields[2].left = 0
  shields[3].max = 0
  shields[3].left = 0
end

local getDrawWidth = function(max,  current)
  if max == nil or max <= 0 or current == nil then
    return 0, 0
  end

  local percentage = current * 100 / max
  if percentage <= 0 then
    percentage = 1
  elseif percentage > 100 then
    percentage = 100
  else
    percentage = math.max(math.floor(percentage), 1)
  end

  local width = math.max(C.RoundToPixelCount(SHIELD_WIDTH_MAX * percentage / 100), 3)

  return percentage, width
end

local updateDisplayHelper = function(max, left, frame, color)
  if left == 0 then
    frame:Hide()
  elseif left < 0 then  -- Depleted the base amount, must have extra
    frame.remaining:SetBackdropColor(unpack(SHIELD_COLOR_RESIDUAL))
    frame.remaining:SetSize(SHIELD_WIDTH_RESIDUAL, 25)

    frame.value:Hide()
    frame.percentage:Hide()
    frame.warning:Show()
    frame:Show()
  else
    local percentage, width = getDrawWidth(max, left)

    frame.value:SetText(left)
    frame.percentage:SetText(percentage..'%')

    frame.remaining:SetBackdropColor(unpack(color))
    frame.remaining:SetSize(width, 25)

    frame.value:Show()
    frame.percentage:Show()
    frame.warning:Hide()
    frame:Show()
  end
end

local updateDisplay = function()
  local absorbMax = shields[1].max + shields[2].max
  local absorbLeft = shields[1].left + shields[2].left

  if shields[1].left < 0 and shields[2].left > 0 then
    absorbLeft = shields[2].left
  elseif shields[1].left > 0 and shields[2].left < 0 then
    absorbLeft = shields[1].left
  end

  local spellAbsorbMax = shields[3].max
  local spellAbsorbLeft = shields[3].left

  updateDisplayHelper(absorbMax, absorbLeft, shieldFrame, SHIELD_COLOR)
  updateDisplayHelper(spellAbsorbMax, spellAbsorbLeft, spellShieldFrame, SPELL_SHIELD_COLOR)
end

-- Have to check all active buffs to find the one present in the passed in table
local findShieldBuffEntry = function(dataTable)
  local isDone = false
  local i = 1

  while isDone == false do
    local buffInfo = {UnitBuff('player', i, 'CANCELABLE')}

    if (buffInfo[1] == nil) then
      isDone = true
    else
      local spellId = buffInfo[10]

      if dataTable[spellId] then
        return dataTable[spellId]
      end
    end

    i = i + 1
  end

  return nil
end

local clearBuff = function(dataTable, index)
  local buffEntry = findShieldBuffEntry(dataTable)

  if buffEntry == nil then
    shields[index].max = 0
    shields[index].left = 0

    updateDisplay()
  end
end

local clearPws = function()
  clearBuff(DATA_PWS, 1)
end

local clearSacrifice = function()
  clearBuff(DATA_SACRIFICE, 2)
end

local clearSpellstone = function()
  clearBuff(DATA_SPELLSTONE, 3)
end

local checkReapplication = function(isApplied, spellName)
  if spellName == WEAKENED_SOUL then
    if backupTimer and backupTimer:IsCancelled() ~= true then
      backupTimer:Cancel()
    end

    if isApplied then
      shields[1].left = shields[1].max
    else
      backupTimer = C_Timer.NewTicker(TIMER_INTERVAL_PWS, clearPws, 1)
    end
  end
end

local handleAuraChange = function(isApplied, sourceName, spellName)
  local dataTable = spellLookup[spellName]

  -- If pws is reapplied before the first one falls off, we won't get an aura_applied event for pws
  -- but we do get it for weakened soul
  if not dataTable then
    checkReapplication(isApplied, spellName)
    updateDisplay()
    return
  end

  local index = dataTable.index

  if isApplied == false then
    shields[index].max = 0
    shields[index].left = 0

    updateDisplay()
    return
  end

  local buffEntry = findShieldBuffEntry(dataTable)
  if not buffEntry then
    checkReapplication(isApplied, spellName)
    updateDisplay()
    return
  end

  local amount = dataTable.calculateAmount(dataTable, buffEntry, sourceName)

  shields[index].max = amount
  shields[index].left = amount

  -- Start a ticker as a backup to update the display
  if dataTable == DATA_SACRIFICE then
    C_Timer.NewTicker(TIMER_INTERVAL_SACRIFICE, clearSacrifice, 1)
  elseif dataTable == DATA_SPELLSTONE then
    C_Timer.NewTicker(TIMER_INTERVAL_SPELLSTONE, clearSpellstone, 1)
  end

  updateDisplay()
end

-- The info has variable number of values based on melee / spell damage absorbed
local handleAbsorb = function(destName, info)
  local spellOrCasterName = info[13]

  local spellName, amount

  -- Sacrifice is different than the others
  if destName == playerName then
    if spellLookup[info[17]] then
      spellName = info[17]
      amount = info[19]
    elseif spellLookup[info[20]] then
      spellName = info[20]
      amount = info[22]
    end
  end

  if spellOrCasterName == playerName then
    spellName = info[17]
    amount = info[19]
  elseif info[16] == playerName then
    spellName = info[20]
    amount = info[22]
  end

  if spellName and amount and spellLookup[spellName] then
    local shieldIndex = spellLookup[spellName].index

    shields[shieldIndex].left = shields[shieldIndex].left - amount
  
    updateDisplay()
  end
end

local onCLEU = function()
  local info = {CombatLogGetCurrentEventInfo()}

  -- All types of info have the same 11 base values and then a variable number of extra values in different orderings
  local subevent = info[2]
  local destName = info[9]

  if subevent == 'SPELL_ABSORBED' then
    handleAbsorb(destName, info)
  end

  if destName == playerName and (subevent == 'SPELL_AURA_APPLIED' or subevent == 'SPELL_AURA_REMOVED') then
    local isApplied = subevent == 'SPELL_AURA_APPLIED'
    local sourceName = info[5]
    local spellName = info[13]

    handleAuraChange(isApplied, sourceName, spellName)
  end
end

local resetDisplayLocation = function()
  UIChanges_Profile['UIC_AD_FrameInfo'] = {}

  shieldFrame:SetUserPlaced(false)
  shieldFrame:ClearAllPoints()
  shieldFrame:SetPoint('CENTER', _G['CastingBarFrame'], 'CENTER', 0, BASE_OFFSET_Y)
end

local initializeSecondaryFrames = function(parentFrame, parentName, shieldColor)
  parentFrame.remaining = CreateFrame('Frame', 'UIC_AD_'..parentName..'FrameRemaining', parentFrame, 'BackdropTemplate')
  parentFrame.remaining:SetPoint('CENTER', parentFrame, 'CENTER', 0, 0)
  parentFrame.remaining:SetBackdrop(C.BACKDROP_INFO(2, 1))
  parentFrame.remaining:SetBackdropColor(unpack(shieldColor))
  parentFrame.remaining:SetSize(SHIELD_WIDTH_MAX, 25)
  parentFrame.remaining:Show()

  parentFrame.value = parentFrame.remaining:CreateFontString('UIC_AD_'..parentName..'Value', 'OVERLAY', 'TextStatusBarText')
  parentFrame.value:SetPoint('RIGHT', parentFrame, -4, 0)
  parentFrame.value:SetJustifyH('CENTER')
  parentFrame.value:SetTextColor(1, 1, 1)
  parentFrame.value:Show()

  parentFrame.percentage = parentFrame.remaining:CreateFontString('UIC_AD_'..parentName..'Percentage', 'OVERLAY', 'TextStatusBarText')
  parentFrame.percentage:SetPoint('LEFT', parentFrame, 4, 0)
  parentFrame.percentage:SetJustifyH('CENTER')
  parentFrame.percentage:SetTextColor(1, 1, 1)
  parentFrame.percentage:Show()

  parentFrame.warning = parentFrame.remaining:CreateFontString('UIC_AD_'..parentName..'Warning', 'OVERLAY', 'TextStatusBarText')
  parentFrame.warning:SetPoint('CENTER', 0, 0)
  parentFrame.warning:SetJustifyH('CENTER')
  parentFrame.warning:SetTextColor(1, 1, 1)
  parentFrame.warning:SetText('!')
  parentFrame.warning:Hide()
end

local initializeSpellShieldFrame = function()
  spellShieldFrame = CreateFrame('Frame', 'UIC_AD_SpellShield_Frame', UIParent, 'BackdropTemplate')
  spellShieldFrame:SetPoint('TOPLEFT', shieldFrame, 'BOTTOMLEFT', 0, 0)
  spellShieldFrame:SetBackdrop(C.BACKDROP_INFO(2, 1))
  spellShieldFrame:SetBackdropColor(unpack(SPELL_SHIELD_COLOR_EXPENDED))
  spellShieldFrame:SetSize(SHIELD_WIDTH_MAX, 25)
  spellShieldFrame:Hide()

  initializeSecondaryFrames(spellShieldFrame, 'SpellShield', SPELL_SHIELD_COLOR)
end

local anchorToCastingBarFrame = function()
  shieldFrame:SetPoint('CENTER', _G['CastingBarFrame'], 'CENTER', 0, BASE_OFFSET_Y)
end

local initializeShieldFrame = function()
  shieldFrame = CreateFrame('Frame', 'UIC_AD_Shield_Frame', UIParent, 'BackdropTemplate')
  shieldFrame:EnableMouse(true)
  shieldFrame:SetMovable(true)
  shieldFrame:SetClampedToScreen(true)
  shieldFrame:Hide()

  local frameInfo = UIChanges_Profile['UIC_AD_FrameInfo']

  if frameInfo and frameInfo.point ~= nil then
    local point = frameInfo.point
    local relativeTo = frameInfo.relativeTo
    local relativePoint = frameInfo.relativePoint
    local offsetX = frameInfo.offsetX
    local offsetY = frameInfo.offsetY

    local status, _ = pcall(function () shieldFrame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end)
    if status == false then
      UIChanges_Profile['UIC_AD_FrameInfo'] = {}

      anchorToCastingBarFrame()
    end
  else
    anchorToCastingBarFrame()
  end

  shieldFrame:SetBackdrop(C.BACKDROP_INFO(2, 1))
  shieldFrame:SetBackdropColor(unpack(SHIELD_COLOR_EXPENDED))
  shieldFrame:SetSize(SHIELD_WIDTH_MAX, 25)
  shieldFrame:SetScript('OnMouseDown', function(frame)
    if IsControlKeyDown() == true then
      frame:StartMoving()
    end
  end)

  shieldFrame:SetScript('OnMouseUp', function(frame)
    frame:StopMovingOrSizing()

    local point, relativeTo, relativePoint, offsetX, offsetY = frame:GetPoint()

    UIChanges_Profile['UIC_AD_FrameInfo'] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      offsetX = math.floor(offsetX),
      offsetY = math.floor(offsetY),
    }
  end)

  initializeSecondaryFrames(shieldFrame, 'Shield', SHIELD_COLOR)
end

local initializeFrames = function()
  mainFrame = CreateFrame('Frame', 'UIC_AbsorbDisplay', UIParent)
  mainFrame:Hide()

  initializeShieldFrame()
  initializeSpellShieldFrame()
end

local EVENTS = {}
EVENTS['COMBAT_LOG_EVENT_UNFILTERED'] = onCLEU

EVENTS['PLAYER_LEVEL_UP'] = function(level)
  playerLevel = level
  checkTooltips()
end

EVENTS['SPELLS_CHANGED'] = checkTooltips

EVENTS['UNIT_PET'] = function(unitTarget)
  if unitTarget == 'player' then
    checkTooltips()
  end
end

EVENTS['SPELL_DATA_LOAD_RESULT'] = function(spellID)
  if DATA_SACRIFICE[spellID] then
    checkTooltips()
  end
end

EVENTS['PLAYER_TALENT_UPDATE'] = checkTalents

EVENTS['CHARACTER_POINTS_CHANGED'] = checkTalents

EVENTS['PLAYER_EQUIPMENT_CHANGED'] = checkItemBonuses

local AbsorbDisplay = {}

AbsorbDisplay.Initialize = function()
  playerName = UnitName('player')
  playerClass = select(2, UnitClass('player'))
  playerLevel = UnitLevel('player')

  adjustDataForExpansion()
  adjustFunctionsForExpansion()

  initializeFrames()

  shields = {
    [1] = {
      max = 0,
      left = 0,
    },
    [2] = {
      max = 0,
      left = 0,
    },
    [3] = {
      max = 0,
      left = 0,
    },
  }

  if playerClass ~= 'PRIEST' then
    EVENTS['PLAYER_EQUIPMENT_CHANGED'] = nil
  end

  if playerClass ~= 'WARLOCK' then
    EVENTS['UNIT_PET'] = nil
    EVENTS['SPELL_DATA_LOAD_RESULT'] = nil
  end

  if playerClass ~= 'PRIEST' and playerClass ~= 'WARLOCK' then
    EVENTS['SPELLS_CHANGED'] = nil
    EVENTS['PLAYER_TALENT_UPDATE'] = nil
    EVENTS['CHARACTER_POINTS_CHANGED'] = nil
  end

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AbsorbDisplay.Enable = function()
  checkTooltips()
  checkTalents()
  checkItemBonuses()

  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AbsorbDisplay.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)

  resetShields()
  updateDisplay()
end

AbsorbDisplay.ResetDisplayLocation = function()
  resetDisplayLocation()
end

addonTable.AbsorbDisplay = AbsorbDisplay
