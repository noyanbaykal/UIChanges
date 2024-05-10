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

local LibDD = LibStub:GetLibrary('LibUIDropDownMenu-4.0')

local _, addonTable = ...

local C = addonTable.C

local settingsTable = C.SETTINGS_TABLE

local paddingAdjustmentY = -2 -- To reduce the extra padding inherent to the dropdown

local createLibUIDropdown = function(parentFrame, frameName, text, key, tooltipText, width, onChange)
  local enumTable = settingsTable[key]['dropdownEnum']

  local dropdown = LibDD:Create_UIDropDownMenu(frameName..'_dd', parentFrame)

  LibDD:UIDropDownMenu_SetText(dropdown, text)

  -- This is called each time the downArrow button is clicked
  LibDD:UIDropDownMenu_Initialize(dropdown, function()
    local info = LibDD:UIDropDownMenu_CreateInfo()

    local selectedIndex = UIChanges_Profile[key]

    for i, enum in ipairs(enumTable) do
      local title = enum[1]

      info.text = title
      info.arg1 = key
      info.arg2 = i

      if i == selectedIndex then
        info.checked = true
      else
        info.checked = false
      end

      info.func = function(self, arg1, arg2)
        self.checked = true

        onChange(arg1, arg2)
      end

      LibDD:UIDropDownMenu_AddButton(info)
    end
  end)

  -- The frame structure of the LibUIDropDownMenu is rather complicated due to how the element is composed
  -- of 3 pieces and the outer pieces have larger-than-visible sizes to make the side textures fit.
  -- The situation creates an offset when trying to set the width of the dropdown and makes the size
  -- related queries return unexpected results.
  -- We'll do some setup here to have the dropdowns conform to the given width and override the GetSize
  -- function of the dropdown frame so it returns values matching what is visible.
  local dropdownSizeOffset = math.ceil(width * 0.133) -- Magic number to account for the offset

  -- Once this SetWidth function is called, dropdown.Middle:GetWidth() starts returning correct values
  LibDD:UIDropDownMenu_SetWidth(dropdown, width - dropdownSizeOffset)

  -- Have to fix the text frame size as well to get Text:IsTruncated() working
  local realTextFrameWidth = dropdown.Middle:GetWidth() - dropdown.Button:GetWidth() - 1
  dropdown.Text:SetWidth(realTextFrameWidth)
  
  dropdown.DefaultGetSize = dropdown.GetSize -- We'll hold on to the original function

  dropdown['GetSize'] = function()
    local middleWidth = math.ceil(dropdown.Middle:GetWidth())
    -- Roughly a third of the side frames' width is occupied by the visible textures, so we use another magic number.
    local sideWidth = math.ceil((dropdown.Left:GetWidth() + dropdown.Right:GetWidth()) / 3)

    local visibleWidth = middleWidth + sideWidth

    local _, height = dropdown:DefaultGetSize()
    height = height - paddingAdjustmentY

    return visibleWidth, height
  end

  -- Add tooltip support
  if dropdown.Text:IsTruncated() and not tooltipText then
    tooltipText = ''
  end

  if tooltipText then
    dropdown.Text:HookScript('OnEnter', function(_)
      addonTable.ShowTooltipFrame(dropdown.Text, dropdown.Button, 0, text, tooltipText)
    end)
    
    dropdown.Text:HookScript('OnLeave', function(_)
      addonTable.HideTooltipFrame()
    end)
  end

  -- Define functions for parity with the default frame types
  dropdown['SetValue'] = C.DUMMY_FUNCTION

  dropdown['SetEnabled'] = function(_, isSet)
    if isSet then
      LibDD:UIDropDownMenu_EnableDropDown(dropdown)
    else
      LibDD:UIDropDownMenu_DisableDropDown(dropdown)
    end
  end

  dropdown['IsEnabled'] = function()
    if not dropdown.dropDown then
      return false
    end

    return UIDropDownMenu_IsEnabled()
  end

  return dropdown
end

addonTable.CreateDropdown = function(parentFrame, frameName, text, key, tooltipText, width, onChange)
  -- The wrapper aligns with the visible parts of the dropdown and allows us to isolate
  -- all the dropdown setup into this file.
  local wrapper = CreateFrame('Frame', frameName, parentFrame)

  local dropdown = createLibUIDropdown(wrapper, frameName, text, key, tooltipText, width, onChange)

  wrapper:SetSize(width, select(2, dropdown:GetSize()))
  wrapper:Show()

  -- Another magic number to account for the side texture but with the dropshadow on the left
  local offsetX = -1 * math.ceil(dropdown.Left:GetWidth() * 0.625)
  
  dropdown:SetPoint('TOP', wrapper, 'TOP', 0, paddingAdjustmentY)
  dropdown:SetPoint('LEFT', wrapper, 'LEFT', offsetX, 0)

  -- Route the 'public' attributes to the dropdown
  wrapper.Text = dropdown.Text
  wrapper.Button = dropdown.Button
  wrapper['GetSize'] = dropdown['GetSize']
  wrapper['SetValue'] = dropdown['SetValue']
  wrapper['SetEnabled'] = dropdown['SetEnabled']
  wrapper['IsEnabled'] = dropdown['IsEnabled']

  return wrapper
end
