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

local WEAKENED_SOUL = GetSpellInfo(6788)

local SHIELD_COLOR = {1, 1, 0.353, 1}

local SHIELD_COLOR_EXPENDED = {1, 1, 0.353, 0.5}

-- When the spellsource is another player we cannot get the real shield amount and therefore
-- are unable to account for extra shielding that comes from talents or spell power .If we happen
-- to have absorbs above the base amount, we'll display that fact instead of a numeric amount.
local SHIELD_COLOR_RESIDUAL = {1, 0.386, 0.2, 1}

local SPELL_SHIELD_COLOR = {0, 0, 1, 1}

local SPELL_SHIELD_COLOR_EXPENDED = {0, 0, 1, 0.5}

-- Sometimes the aura_removed event for PWS isn't sent. We'll run a timer as a backup to remove the shield display.
local TIMER_INTERVAL_PWS = 17 -- Seconds
local TIMER_INTERVAL_SACRIFICE = 32 -- Seconds
local TIMER_INTERVAL_SPELLSTONE = 62 -- Seconds
local BASE_OFFSET_Y = 150
local SHIELD_WIDTH_MAX = 120
local SHIELD_WIDTH_RESIDUAL = 12

local playerName, playerClass
local mainFrame, shieldFrame, spellShieldFrame, shields, backupTimer, adjuster

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
  clearBuff(adjuster.DATA_PWS, 1)
end

local clearSacrifice = function()
  clearBuff(adjuster.DATA_SACRIFICE, 2)
end

local clearSpellstone = function()
  clearBuff(adjuster.DATA_SPELLSTONE, 3)
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

-- The info has variable number of values based on melee / spell damage absorbed
local handleAbsorb = function(destName, info)
  local spellOrCasterName = info[13]

  local spellName, amount

  -- Sacrifice is different than the others
  if destName == playerName then
    if adjuster.spellLookup[info[17]] then
      spellName = info[17]
      amount = info[19]
    elseif adjuster.spellLookup[info[20]] then
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

  if spellName and amount and adjuster.spellLookup[spellName] then
    local shieldIndex = adjuster.spellLookup[spellName].index

    shields[shieldIndex].left = shields[shieldIndex].left - amount
  
    updateDisplay()
  end
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
  local dataTable = adjuster.spellLookup[spellName]

  -- If PWS is reapplied with the same rank before it falls off, we won't get an
  -- aura_applied event for PWS but we do get it for weakened soul
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
  if dataTable == adjuster.DATA_SACRIFICE then
    C_Timer.NewTicker(TIMER_INTERVAL_SACRIFICE, clearSacrifice, 1)
  elseif dataTable == adjuster.DATA_SPELLSTONE then
    C_Timer.NewTicker(TIMER_INTERVAL_SPELLSTONE, clearSpellstone, 1)
  end

  updateDisplay()
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

local EVENTS = {}
EVENTS['COMBAT_LOG_EVENT_UNFILTERED'] = onCLEU

EVENTS['PLAYER_LEVEL_UP'] = function(level)
  adjuster.OnLevelUp(level)
  adjuster.CheckTooltips()
end

EVENTS['SPELLS_CHANGED'] = function()
  adjuster.CheckTooltips()
end

EVENTS['UNIT_PET'] = function(unitTarget)
  if unitTarget == 'player' then
    adjuster.CheckTooltips()
  end
end

EVENTS['PLAYER_TALENT_UPDATE'] = function()
  adjuster.CheckTooltips()
  adjuster.CheckTalents()
end

EVENTS['CHARACTER_POINTS_CHANGED'] = function()
  adjuster.CheckTooltips()
  adjuster.CheckTalents()
end

EVENTS['PLAYER_EQUIPMENT_CHANGED'] = function()
  adjuster.CheckItemBonuses()
end

local AbsorbDisplay = {}

AbsorbDisplay.Initialize = function()
  playerName = UnitName('player')
  playerClass = select(2, UnitClass('player'))

  adjuster = addonTable.Adjuster.new(playerName, playerClass)

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
  adjuster.CheckTooltips()
  adjuster.CheckTalents()
  adjuster.CheckItemBonuses()

  -- If the player is already shielded
  local buffEntry = findShieldBuffEntry(adjuster.DATA_PWS)
  if buffEntry then
    -- Show residual since we can't know how much of the shield is still intact
    updateDisplayHelper(1, -1, shieldFrame, SHIELD_COLOR) 
  end

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
