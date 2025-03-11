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

local C = addonTable.C

local REF_PARTY = {
	['party1'] = 1,
	['party2'] = 2,
	['party3'] = 3,
	['party4'] = 4,
	['partypet1'] = 1,
	['partypet2'] = 2,
	['partypet3'] = 3,
	['partypet4'] = 4,
}

local mainFrame, petFrames

local onUpdate = function(unitTarget)
  local index = REF_PARTY[unitTarget]
  if index ~= nil and petFrames[index]['frame']:IsVisible() then
    petFrames[index]['powerBar']:Update()
  end
end

local onUpdateAll = function()
  for i = 1, #petFrames do
    if petFrames[i]['frame']:IsVisible() then
      petFrames[i]['powerBar']:Update()
    end
  end
end

local EVENTS = {}
EVENTS['GROUP_FORMED'] = onUpdateAll

EVENTS['GROUP_JOINED'] = onUpdateAll

EVENTS['GROUP_ROSTER_UPDATE'] = onUpdateAll

EVENTS['INSTANCE_GROUP_SIZE_CHANGED'] = onUpdateAll

EVENTS['UPDATE_ACTIVE_BATTLEFIELD'] = onUpdateAll

EVENTS['GROUP_LEFT'] = onUpdateAll

EVENTS['PLAYER_ENTERING_WORLD'] = onUpdateAll

EVENTS['PORTRAITS_UPDATED'] = onUpdateAll

EVENTS['LOCALPLAYER_PET_RENAMED'] = onUpdateAll

EVENTS['PARTY_MEMBER_DISABLE'] = onUpdate

EVENTS['PARTY_MEMBER_ENABLE'] = onUpdate

EVENTS['UNIT_OTHER_PARTY_CHANGED'] = onUpdate

EVENTS['UNIT_PORTRAIT_UPDATE'] = onUpdate

EVENTS['UNIT_MODEL_CHANGED'] = onUpdate

EVENTS['UNIT_PET'] = onUpdate

EVENTS['UNIT_PHASE'] = onUpdate

EVENTS['UNIT_POWER_UPDATE'] = onUpdate

EVENTS['UNIT_MAXPOWER'] = onUpdate

local PartyPetFrames = {}

PartyPetFrames.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PartyPetFrames', UIParent)
  mainFrame:Hide()

  petFrames = {}
  for i = 1, 4 do
    local petFrame = _G['PartyMemberFrame'..i..'PetFrame']
    local petPowerBar = addonTable.PetPowerBar.new(i)

    petFrames[i] = {
      ['frame'] = petFrame,
      ['powerBar'] = petPowerBar,
    }
  end

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

PartyPetFrames.Enable = function()
  C.REGISTER_EVENTS(mainFrame, EVENTS)
end

PartyPetFrames.Disable = function()
  C.UNREGISTER_EVENTS(mainFrame, EVENTS)
end

addonTable.PartyPetFrames = PartyPetFrames
