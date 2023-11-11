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

local C = UI_CHANGES_CONSTANTS
local L = UI_CHANGES_LOCALE

-- Spells scale with the caster's level. There isn't a clean way of accounting for this so we store
-- amount and maxAmount. We'll look at the player's level and use the maxAmount for lower level ranks.
-- Spells cast by others will default to amount, unless the player is at max level.
-- The data & lookup tables may be altered in adjustDataTables based on expansion
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

local PWS = {
  [17] = DATA_PWS[1],
  [592] = DATA_PWS[2],
  [600] = DATA_PWS[3],
  [3747] = DATA_PWS[4],
  [6065] = DATA_PWS[5],
  [6066] = DATA_PWS[6],
  [10898] = DATA_PWS[7],
  [10899] = DATA_PWS[8],
  [10900] = DATA_PWS[9],
  [10901] = DATA_PWS[10],
  [25217] = DATA_PWS[11],
  [25218] = DATA_PWS[12],
  [48065] = DATA_PWS[13],
  [48066] = DATA_PWS[14],
}

local DATA_SACRIFICE = { -- Voidwalker ability
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

local SACRIFICE = { -- Voidwalker ability
  [7812] = DATA_SACRIFICE[1],
  [19438] = DATA_SACRIFICE[2],
  [19440] = DATA_SACRIFICE[3],
  [19441] = DATA_SACRIFICE[4],
  [19442] = DATA_SACRIFICE[5],
  [19443] = DATA_SACRIFICE[6],
  [27273] = DATA_SACRIFICE[7],
  [47985] = DATA_SACRIFICE[8],
  [47986] = DATA_SACRIFICE[9],
}

local DATA_SPELLSTONE = {
  {level = 31, rank = 1,  spellId = 128,  amount = 400,   amountMax = 400},
  {level = 43, rank = 2,  spellId = 17729, amount = 650,   amountMax = 650},
  {level = 55, rank = 3,  spellId = 17730, amount = 900,   amountMax = 900},
}

-- This effect is present only in classic era and doesn't scale with player level
local SPELLSTONE = {
  [128] = DATA_SPELLSTONE[1],
  [17729] = DATA_SPELLSTONE[2],
  [17730] = DATA_SPELLSTONE[3],
}

local SHIELD_COLOR = {1, 1, 0.353, 1}

local SHIELD_COLOR_EXPENDED = {1, 1, 0.353, 0.5}

-- We cannot get the real shield amount and therefore are unable to account for extra shielding
-- that comes from talents or spell power when the spellsource is another player. If we happen
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

local spellpower = 0
local spellpowerCoefficientPWS = 0.1 -- Set for classic era, may be changed in adjustDataForExpansion
local setBonusModifierPWS = 1 -- Item - Priest T10 Healer 4P Bonus, 70798, only in WOTLK
local talentModifierIPWS = 1 -- Improved Power Word: Shield
local talentCoefficientBonusBT = 0 -- Borrowed Time, only in WOTLK
local talentModifierSacrifice = 1
local talentModifierSpellstone = 1

local MAX_LEVEL = 60 -- Set for classic era, may be changed in adjustDataForExpansion
local nameWeakenedSoul = GetSpellInfo(6788)
local mainFrame, shieldFrame, spellShieldFrame, playerName, playerClass, playerLevel
local spellNameLookup, shields, backupTimer, cachedHighestKnown

local adjustDataForExpansion = function()
  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    DATA_PWS[10].amountMax = DATA_PWS[10].amount
    DATA_SACRIFICE[6].amountMax = 1931

    DATA_PWS[11] = nil
    DATA_PWS[12] = nil
    DATA_PWS[13] = nil
    DATA_PWS[14] = nil

    PWS[25217] = nil
    PWS[25218] = nil
    PWS[48065] = nil
    PWS[48066] = nil

    DATA_SACRIFICE[7] = nil
    DATA_SACRIFICE[8] = nil
    DATA_SACRIFICE[9] = nil

    SACRIFICE[27273] = nil
    SACRIFICE[47985] = nil
    SACRIFICE[47986] = nil
  elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
    MAX_LEVEL = 70

    DATA_PWS[12].amountMax = DATA_PWS[12].amount

    DATA_PWS[13] = nil
    DATA_PWS[14] = nil

    PWS[48065] = nil
    PWS[48066] = nil

    DATA_SACRIFICE[8] = nil
    DATA_SACRIFICE[9] = nil

    SACRIFICE[47985] = nil
    SACRIFICE[47986] = nil

    spellpowerCoefficientPWS = 0.3
  elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    MAX_LEVEL = 80

    spellpowerCoefficientPWS = 0.8068
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
local getShieldBuffData = function(tableReference)
  local isDone = false
  local i = 1

  while isDone == false do
    local buffInfo = {UnitBuff('player', i, 'PLAYER | CANCELABLE')}

    if (buffInfo[1] == nil) then
      isDone = true
    else
      local spellId = buffInfo[10]

      if tableReference[spellId] then
        return tableReference[spellId]
      end
    end

    i = i + 1
  end

  return 0
end

local clearBuff = function(tableReference, index)
  local buffData = getShieldBuffData(tableReference)

  if buffData == nil then
    shields[index].max = 0
    shields[index].left = 0

    updateDisplay()
  end
end

local clearPws = function()
  clearBuff(PWS, 1)
end

local clearSacrifice = function()
  clearBuff(SACRIFICE, 2)
end

local clearSpellstone = function()
  clearBuff(SPELLSTONE, 3)
end

-- If pws is reapplied before the first one falls off, we won't get an aura_applied event for pws
-- but we do get it for weakened soul
local checkReapplication = function(isApplied, spellName)
  if spellName == nameWeakenedSoul then
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
  local lookup = spellNameLookup[spellName]
  if lookup == nil then
    return false
  end

  local index = lookup.index
  local dataTableReference = lookup.data
  local tableReference = lookup.table
  local calculateFinalAmount = lookup.calculateFinalAmount

  if (isApplied == false) then
    shields[index].max = 0
    shields[index].left = 0

    return true
  else
    local buffData = getShieldBuffData(tableReference)
    if buffData ~= nil then -- Shouldn't be necessary but better to be safe
      local amount = calculateFinalAmount(sourceName, dataTableReference, buffData)

      shields[index].max = amount
      shields[index].left = amount

      -- Start a ticker as a backup to update the display
      if tableReference == SACRIFICE then
        C_Timer.NewTicker(TIMER_INTERVAL_SACRIFICE, clearSacrifice, 1)
      elseif tableReference == SPELLSTONE then
        C_Timer.NewTicker(TIMER_INTERVAL_SPELLSTONE, clearSpellstone, 1)
      end

      return true
    else
      return false
    end
  end
end

local absorbEventParser = function(info)
  -- Sacrifice is different than the others
  if info[9] == playerName then
    if spellNameLookup[info[17]] then
      return info[17], info[19]
    elseif spellNameLookup[info[20]] then
      return info[20], info[22]
    else
      return nil, nil
    end
  end

  if info[13] == playerName then
    return info[17], info[19]
  elseif info[16] == playerName then
    return info[20], info[22]
  else
    return nil, nil
  end
end

-- This event returns variable number of values based on melee / spell damage absorbed
local handleAbsorb = function(info)
  local spellName, amount = absorbEventParser(info)

  if spellName == nil then
    return false
  end

  local lookup = spellNameLookup[spellName]
  if lookup == nil then
    return false
  end

  local shieldIndex = lookup.index

  shields[shieldIndex].left = shields[shieldIndex].left - amount

  return true
end

-- https://wowpedia.fandom.com/wiki/ItemLink
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

local checkT10Bonus = function(equippedItems)
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

local checkItemBonuses = function()
  if playerClass ~= 'PRIEST' then
    return
  end

  if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    spellpower = GetSpellBonusDamage(2) or 0

    local equippedItems = {
      getEquippedItemId(7), -- legs
      getEquippedItemId(5), -- chest
      getEquippedItemId(3), -- shoulder
      getEquippedItemId(10), -- hand
      getEquippedItemId(1), -- head
    }

    local hasT10Bonus = checkT10Bonus(equippedItems)

    if hasT10Bonus then
      setBonusModifierPWS = 1.05
    else
      setBonusModifierPWS = 1
    end
  else
    spellpower = GetSpellBonusHealing() or 0
  end
end

-- Era coefficients: https://www.reddit.com/r/classicwow/comments/95abc8/list_of_spellcoefficients_1121/
-- TBC coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient?oldid=1492745
-- WOTLK coefficients: https://wowwiki-archive.fandom.com/wiki/Spell_power_coefficient
local checkTalents = function()
  if playerClass == 'PRIEST' then
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
      local _, _, _, _, rank = GetTalentInfo(1, 5)
      talentModifierIPWS = 1 + (rank * 0.05)
    elseif WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
      local _, _, _, _, rank = GetTalentInfo(1, 5)
      talentModifierIPWS = 1 + (rank * 0.05)
    elseif WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
      local _, _, _, _, ipwsRank = GetTalentInfo(1, 9)
      talentModifierIPWS = 1 + (ipwsRank * 0.05)

      local _, _, _, _, btRank = GetTalentInfo(1, 27)
      talentCoefficientBonusBT = btRank * 0.08
    end
  end

  if playerClass == 'WARLOCK' then
    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
      local _, _, _, _, rank = GetTalentInfo(2, 5)
      talentModifierSacrifice = 1 + (rank * 0.1)
    else
      local _, _, _, _, rank = GetTalentInfo(2, 6)
      talentModifierSacrifice = 1 + (rank * 0.1)
    end

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
      local _, _, _, _, rank = GetTalentInfo(2, 17)

      talentModifierSpellstone = 1 + (rank * 0.15)
    end
  end
end

local cacheHighestKnownRanks = function()
  if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then
    return
  end

  cachedHighestKnown = {
    {rank = 0, amount = 0}, -- dummy data that shouldn't be unnecessary but better to be safe
  }

  for i = #DATA_PWS, 1, -1 do
    local levelRequired = DATA_PWS[i].level
    local spellId = DATA_PWS[i].spellId

    if playerLevel >= levelRequired and IsSpellKnown(spellId) then
      local text = GetSpellDescription(spellId)
      local firstNumber = string.match(text, '%d+')

      cachedHighestKnown[1].rank = i
      cachedHighestKnown[1].amount = firstNumber or DATA_PWS[i].amount
      break
    end
  end
end

local calculatorPwsEra = function(buffData)
  local baseAmount

  if cachedHighestKnown[1].rank == buffData.rank then
    baseAmount = cachedHighestKnown[1].amount
  else
    baseAmount = buffData.maxAmount * talentModifierIPWS
  end

  local finalAmount = baseAmount + (spellpower * spellpowerCoefficientPWS)
  return math.floor(finalAmount)
end

local calculatorPws = function(sourceName, dataTable, buffData)
  if sourceName ~= playerName or playerClass ~= 'PRIEST' then
    if playerLevel == MAX_LEVEL then
      return buffData.maxAmount
    else
      return buffData.amount
    end
  end

  if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    return calculatorPwsEra(buffData)
  end

  local amount

  if playerLevel == MAX_LEVEL or buffData.rank == #dataTable or playerLevel >= dataTable[buffData.rank + 1].level then
    amount = buffData.maxAmount
  else
    amount = buffData.amount
  end

  local coefficient = spellpowerCoefficientPWS + talentCoefficientBonusBT

  local finalAmount = (amount + (spellpower * coefficient)) * talentModifierIPWS * setBonusModifierPWS
  return math.floor(finalAmount)
end

local calculatorSacrifice = function(_, dataTable, buffData)
  local amount

  if playerLevel == MAX_LEVEL or (buffData.rank ~= #dataTable and playerLevel >= dataTable[buffData.rank + 1].level) then
    amount = buffData.maxAmount
  else
    amount = buffData.amount
  end

  return math.floor(amount * talentModifierSacrifice)
end

local calculatorSpellstone = function(_, _, buffData)
  return math.floor(buffData.amount * talentModifierSpellstone)
end

-- Have to pick the right table based on localized spell name
local initializeSpellLookup = function()
  local namePws = GetSpellInfo(17)
  local nameSacrifice = GetSpellInfo(7812)

  spellNameLookup = {
    [namePws] = {
      index = 1,
      data = DATA_PWS,
      table = PWS,
      calculateFinalAmount = calculatorPws,
    },
  }

  if playerClass == 'WARLOCK' then
    spellNameLookup[nameSacrifice] = {
      index = 2,
      data = DATA_SACRIFICE,
      table = SACRIFICE,
      calculateFinalAmount = calculatorSacrifice,
    }

    if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
      local nameSpellstone = GetSpellInfo(128)
      local nameSpellstoneGreater = GetSpellInfo(17729)
      local nameSpellstoneMajor = GetSpellInfo(17730)

      local spellstoneEntry = {
        index = 3,
        data = DATA_SPELLSTONE,
        table = SPELLSTONE,
        calculateFinalAmount = calculatorSpellstone,
      }

      spellNameLookup[nameSpellstone] = spellstoneEntry
      spellNameLookup[nameSpellstoneGreater] = spellstoneEntry
      spellNameLookup[nameSpellstoneMajor] = spellstoneEntry
    end
  end
end

local resetDisplayLocation = function()
  _G['UIC_AD_FrameInfo'] = nil

  shieldFrame:SetUserPlaced(false)
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

  if _G['UIC_AD_FrameInfo'] then
    local point = _G['UIC_AD_FrameInfo'].point
    local relativeTo = _G['UIC_AD_FrameInfo'].relativeTo
    local relativePoint = _G['UIC_AD_FrameInfo'].relativePoint
    local offsetX = _G['UIC_AD_FrameInfo'].offsetX
    local offsetY = _G['UIC_AD_FrameInfo'].offsetY

    local status, _ = pcall(function () shieldFrame:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY) end)
    if status == false then
      _G['UIC_AD_FrameInfo'] = nil

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

    _G['UIC_AD_FrameInfo'] = {
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
  mainFrame.ResetDisplayLocation = resetDisplayLocation
  mainFrame:Hide()

  initializeShieldFrame()
  initializeSpellShieldFrame()
end

local EVENTS = {}
EVENTS['COMBAT_LOG_EVENT_UNFILTERED'] = function()
  local info = {CombatLogGetCurrentEventInfo()}

  if info[2] == 'SPELL_ABSORBED' then
    local shouldUpdate = handleAbsorb(info)
    if shouldUpdate == false then
      return
    end
  elseif info[2] == 'SPELL_AURA_APPLIED' and info[9] == playerName then
    if handleAuraChange(true, info[5], info[13]) == false then
      checkReapplication(true, info[13])
    end
  elseif info[2] == 'SPELL_AURA_REMOVED' and info[9] == playerName then
    if handleAuraChange(false, info[5], info[13]) == false then
      checkReapplication(false, info[13])
    end
  else
    return
  end

  updateDisplay()
end
EVENTS['PLAYER_LEVEL_UP'] = function(level)
  playerLevel = level
  cacheHighestKnownRanks()
end
EVENTS['SPELLS_CHANGED'] = function()
  cacheHighestKnownRanks()
end
EVENTS['PLAYER_TALENT_UPDATE'] = function()
  checkTalents()
end
EVENTS['CHARACTER_POINTS_CHANGED'] = function()
  checkTalents()
end
EVENTS['PLAYER_EQUIPMENT_CHANGED'] = function()
  checkItemBonuses()
end

AbsorbDisplay = {}

AbsorbDisplay.Initialize = function()
  adjustDataForExpansion()
  initializeFrames()

  playerName = UnitName('player')
  playerClass = select(2, UnitClass('player'))
  playerLevel = UnitLevel('player')

  initializeSpellLookup()

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

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

AbsorbDisplay.Enable = function()
  cacheHighestKnownRanks()
  checkTalents()
  checkItemBonuses()

  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

AbsorbDisplay.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)

  resetShields()
  updateDisplay()
end

return AbsorbDisplay
