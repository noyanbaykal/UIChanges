--[[
UIChanges

Copyright (C) 2019 - 2022 Melik Noyan Baykal

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

local mainFrame

local EVENTS = {}
EVENTS['PARTY_MEMBER_ENABLE'] = function(...)
  -- TODO
end

local setPetFramesCVar = function(value)
  local success = false

  if not InCombatLockdown() then
    success = C_CVar.SetCVar('showPartyPets', value)
  end

  if not success then
    local isCVarSet = 1 == tonumber(GetCVar('showPartyPets'))
    local message = L.CANT_CHANGE_IN_COMBAT..' '..L.CURRENT_CVAR_VALUE(isCVarSet)
    DEFAULT_CHAT_FRAME:AddMessage(message)
  end

  return success
end

PartyPetFrames = {}

PartyPetFrames.Initialize = function()
  mainFrame = CreateFrame('Frame', 'UIC_PartyPetFrames', UIParent)
  mainFrame:Hide()

  mainFrame:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)
end

PartyPetFrames.Enable = function()
  local cVarSet = setPetFramesCVar(true)

  if cVarSet then
    C.REGISTER_EVENTS(mainFrame, EVENTS)
  end
end

PartyPetFrames.Disable = function()
  local cVarSet = setPetFramesCVar(false)

  if cVarSet then
    C.UNREGISTER_EVENTS(mainFrame, EVENTS)
  end
end

return PartyPetFrames
