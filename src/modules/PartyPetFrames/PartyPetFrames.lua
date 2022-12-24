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
EVENTS['GROUP_FORMED'] = function()
  onUpdateAll()
end

EVENTS['GROUP_JOINED'] = function()
  onUpdateAll()
end

EVENTS['GROUP_ROSTER_UPDATE'] = function()
  onUpdateAll()
end

EVENTS['INSTANCE_GROUP_SIZE_CHANGED'] = function()
  onUpdateAll()
end

EVENTS['UPDATE_ACTIVE_BATTLEFIELD'] = function()
  onUpdateAll()
end

EVENTS['GROUP_LEFT'] = function()
  onUpdateAll()
end

EVENTS['PLAYER_ENTERING_WORLD'] = function()
  onUpdateAll()
end

EVENTS['PORTRAITS_UPDATED'] = function()
  onUpdateAll()
end

EVENTS['PARTY_MEMBER_DISABLE'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['PARTY_MEMBER_ENABLE'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_OTHER_PARTY_CHANGED'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_PORTRAIT_UPDATE'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_MODEL_CHANGED'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_PET'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_PHASE'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['LOCALPLAYER_PET_RENAMED'] = function(unitTarget)
  onUpdate(unitTarget)
end

EVENTS['UNIT_POWER_UPDATE'] = function(unitTarget, powerType)
  onUpdate(unitTarget)
end

EVENTS['UNIT_MAXPOWER'] = function(unitTarget, powerType)
  onUpdate(unitTarget)
end

PartyPetFrames = {}

PartyPetFrames.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PartyPetFrames', UIParent)
  mainFrame:Hide()

  petFrames = {}
  for i = 1, 4 do
    local petFrame = _G['PartyMemberFrame'..i..'PetFrame']
    local petPowerBar = PetPowerBar.new(i)

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

return PartyPetFrames
