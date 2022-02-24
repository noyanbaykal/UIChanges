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

local optionsPanel = CreateFrame('Frame', 'UIC_Options', UIParent)
optionsPanel.name = 'UIChanges' -- TODO: read from constants
optionsPanel:Hide()

local headerText = optionsPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
headerText:SetText('UIChanges')
headerText:SetPoint("TOPLEFT", optionsPanel, 16, -16)
-- 

-- TODO: implement options!
InterfaceOptions_AddCategory(optionsPanel)
