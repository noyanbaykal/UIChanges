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

local settingsTable = C.SETTINGS_TABLE -- We'll be able to reference entries by their keys through the settingsTable

local gameFontColor = {} -- Yellow. Module checkboxes will override checkbox text color.
gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4] = _G['GameFontNormal']:GetTextColor()

local disabledFontColor = {} -- Gray. This is used for disabled options
disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4] = _G['GameFontDisable']:GetTextColor()

local whiteFontColor = {1, 1, 1, gameFontColor[4]}

local BUTTON_WIDTH = 135

local scrollChild -- All frames that need to scroll have to be parented to this frame
local lastFrameTop -- A rolling reference to the frame that upcoming frames should be vertically anchored to
local tooltipFrame -- A shared frame to show tooltips for buttons and dropdowns

local setFrameState = function(frame, isSet)
  frame:SetEnabled(isSet)

  local r, g, b, a

  if isSet then
    r, g, b, a = whiteFontColor[1], whiteFontColor[2], whiteFontColor[3], whiteFontColor[4]
  else
    r, g, b, a = disabledFontColor[1], disabledFontColor[2], disabledFontColor[3], disabledFontColor[4]
  end

  frame.Text:SetTextColor(r, g, b, a)
end

-- To handle non-boolean subsetting values
local isValueTruthy = function(value)
  if type(value) == 'number' then
    return value == 1 -- The first value of enums should correspond to off or the default value
  end

  return value
end

-- This supports module & subsetting entries.
local subframesSetEnable = function(entry, value)
  local isSet = isValueTruthy(value)

  if entry.subsettings and entry.subsettings.entries then -- Subsetttings
    local dependees = {}

    for _, subEntry in ipairs(entry.subsettings.entries) do
      local subKey = subEntry['entryKey']
      local frame = settingsTable[subKey]['frame']

      setFrameState(frame, isSet)

      -- If a module is active but this subsetting is disabled, it's dependents should be disabled
      local isSubsettingEnabled = isValueTruthy(UIChanges_Profile[subKey])

      if isSet and not isSubsettingEnabled and subEntry['dependents'] then
        dependees[#dependees + 1] = subEntry
      end
    end

    -- A second pass is needed for dependent subsettings whose dependees are not enabled
    for _, subEntry in ipairs(dependees) do
      for _, dependentKey in ipairs(subEntry['dependents']) do
        local frame = settingsTable[dependentKey]['frame']

        setFrameState(frame, false)
      end
    end
  end

  if entry.dependents then -- Dependents
    for _, subKey in ipairs(entry.dependents) do
      local frame = settingsTable[subKey]['frame']
      
      setFrameState(frame, isSet)
    end
  end
end

local applyChange = function(key, newValue)
  local entry = settingsTable[key]

  local consoleVariable = entry['consoleVariableName']

  if consoleVariable then
    local success = false

    if not InCombatLockdown() then
      success = SetCVar(consoleVariable, newValue)
    end

    if not success then
      DEFAULT_CHAT_FRAME:AddMessage(L.CANT_CHANGE_IN_COMBAT, 1, 0.3, 0.3)
      return
    else
      DEFAULT_CHAT_FRAME:AddMessage(L.CVAR_CHANGED, 1, 0.501, 0)
    end
  end

  UIChanges_Profile[key] = newValue

  if entry['updateCallback'] then
    entry['updateCallback'](newValue)
  end

  subframesSetEnable(entry, newValue) -- Enable/Disable subframes
end

-- The sound files refer to checkbox but the frame type is actually CheckButton
local createCheckBox = function(frameName, text, key, tooltipText, isSubsetting)
  local checkbox = CreateFrame('CheckButton', frameName, scrollChild, 'InterfaceOptionsCheckButtonTemplate')
  checkbox:SetChecked(UIChanges_Profile[key])
  checkbox:SetScript('OnClick', function(self, button, down)
    local newValue = self:GetChecked()

    applyChange(key, newValue)

    if newValue then
      PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    else
      PlaySound(857) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF
    end
  end)

  checkbox['SetValue'] = function(self, newValue)
    checkbox:SetChecked(newValue)
  end

  -- Subsetting checkboxes should not become wider than buttons or dropdowns
  local maxTextWidth = BUTTON_WIDTH - checkbox:GetWidth()

  checkbox.Text:SetText(text)

  if isSubsetting then
    checkbox.Text:SetWidth(maxTextWidth)
    checkbox.Text:SetNonSpaceWrap(true)
    checkbox.Text:SetWordWrap(true)
    checkbox.Text:SetMaxLines(2)

    -- Not using the built-in tooltipText attribute because that gets truncated too if the text
    -- is too long and doesn't support this case here
    if checkbox.Text:IsTruncated() and not tooltipText then
      tooltipText = ''
    end
  end

  if tooltipText then
    checkbox:HookScript('OnEnter', function(self)
      addonTable.ShowTooltipFrame(self.Text, self.Text, -5, text, tooltipText)
    end)
    
    checkbox:HookScript('OnLeave', function(self)
      addonTable.HideTooltipFrame()
    end)
  end

  return checkbox
end

local createButton = function(frameName, text, key, tooltipText)
  local yellowText = '|cFFFFD100'..text

  local button = CreateFrame('Button', frameName, scrollChild, 'UIPanelButtonTemplate')
  button:SetWidth(BUTTON_WIDTH)
  button:SetScript('OnClick', function()
    PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
    settingsTable[key]['updateCallback']() -- Unlike other widgets, buttons don't call applyChange
  end)

  button.Text:SetText(yellowText)
  button.Text:SetTextScale(0.9)
  button.Text:SetWidth(BUTTON_WIDTH - 10)

  if button.Text:IsTruncated() and not tooltipText then
    tooltipText = ''
  end

  -- Have the text be white when hovered over and add tooltip support
  button:HookScript('OnEnter', function(self)
    self:SetText(text)

    if tooltipText then
      addonTable.ShowTooltipFrame(self, self, math.ceil(self:GetWidth() / 8), text, tooltipText)
    end
  end)

  button:HookScript('OnLeave', function(self)
    self:SetText(yellowText)

    if tooltipText then
      addonTable.HideTooltipFrame()
    end
  end)

  -- Buttons don't need a SetValue function but they will have a dummy function assigned to keep things consistent
  button.SetValue = C.DUMMY_FUNCTION

  return button
end

local createSubsettingFrame = function(entry)
  local key = entry['entryKey']
  local entryType = entry['entryType']
  local title = entry['title']
  local tooltipText = entry['tooltipText']
  local frameName = entry['frameName']

  local frame

  -- We want each entry type to occupy the same amount of space so each entry type needs different offsets for
  -- fine tuning and each entry type may have a different part that should be used as an anchor by nearby frames.
  if entryType == 'dropdown' then
    frame = addonTable.CreateDropdown(scrollChild, frameName, title, key, tooltipText, BUTTON_WIDTH, applyChange)
    frame.nextLeftAnchor = frame.Button
    frame.nextTopAnchor = frame.Button
    frame.subOffsetX = 0
    frame.subOffsetY = 1
  elseif entryType == 'button' then
    frame = createButton(frameName, title, key, tooltipText)
    frame.nextLeftAnchor = frame
    frame.nextTopAnchor = frame
    frame.subOffsetX = 1
    frame.subOffsetY = -4
  else
    frame = createCheckBox(frameName, title, key, tooltipText, true)
    frame.nextLeftAnchor = frame.Text
    frame.nextTopAnchor = frame
    frame.subOffsetX = -1
    frame.subOffsetY = -1
  end

  frame.entryType = entryType

  settingsTable[key]['frame'] = frame
end

local anchorSubsettings = function(entries, initialLeftAnchor, rowSize, groupOffsetX, groupOffsetY)
  for i = 1, #entries do
    local frame = entries[i].frame
    
    local columnIndex = i % rowSize
    if columnIndex == 0 then
      columnIndex = rowSize
    end

    local rowIndex = math.ceil(i / rowSize)

    -- Need to watch for the anchor reference when anchoring to our own subsetting frames.
    local leftAnchor = columnIndex <= 1 and initialLeftAnchor or entries[i - 1].frame.nextLeftAnchor
    local topAnchor = i <= rowSize and lastFrameTop or entries[i - rowSize].frame.nextTopAnchor

    local offsetX = frame.subOffsetX
    if columnIndex ~= 1 then
      offsetX = offsetX + groupOffsetX
    end
    
    frame:SetPoint('LEFT', leftAnchor, 'RIGHT', offsetX, 0)
    frame:SetPoint('TOP', topAnchor, 'BOTTOM', 0, groupOffsetY + frame.subOffsetY)
  end
end

local drawSeparator = function(entries, separatorInfo)
  if separatorInfo == nil then
    return
  end

  local topFrame = entries[separatorInfo['topFrame']]['frame']
  local bottomFrame = entries[separatorInfo['bottomFrame']]['frame']

  if not topFrame or not bottomFrame then
    return
  end

  local line = scrollChild:CreateLine()
  line:SetColorTexture(0.8, 0.8, 0.8)
  line:SetThickness(1.5)
  line:SetStartPoint('TOPLEFT', topFrame, -12, -4)
  line:SetEndPoint('BOTTOMLEFT', bottomFrame, -12, 4)
end

-- Initialize all the frames without anchoring them first and then anchor them all evenly in a grid
-- per row and column. The module definitons have the fine tuning parameters.
local createSubsettingOptions = function(initialLeftAnchor, subsettings)
  if subsettings and subsettings['entries'] then
    local entries = subsettings['entries']
    local offsetX = subsettings['offsetX'] or 10
    local offsetY = subsettings['offsetY'] or -10
    local rowSize = subsettings['rowSize'] or math.min(4, #entries)
    local separator = subsettings['separator']

    for i = 1, #entries do
      createSubsettingFrame(entries[i])
    end

    anchorSubsettings(entries, initialLeftAnchor, rowSize, offsetX, offsetY)

    drawSeparator(entries, separator)

    lastFrameTop = entries[#entries]['frame']
  end
end

local createModuleOptions = function(moduleEntry)
  local key = moduleEntry['moduleKey']
  local frameName = moduleEntry['frameName']
  local title = moduleEntry['title']
  local description = moduleEntry['description']
  local subsettings = moduleEntry['subsettings']

  -- If the base options are missing and this will be the first entry
  local isFirstEntry = lastFrameTop:GetName() and lastFrameTop:GetName():match('ScrollFrame') ~= nil
  local offsetY = isFirstEntry and 0 or -12

  local moduleCheckbox = createCheckBox('UIC_Options_CB_'..frameName, title, key)
  moduleCheckbox:SetPoint('LEFT', scrollChild, 'LEFT', 0, 0)
  moduleCheckbox:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, offsetY)
  moduleCheckbox.Text:SetTextColor(gameFontColor[1], gameFontColor[2], gameFontColor[3], gameFontColor[4])

  settingsTable[key]['frame'] = moduleCheckbox

  -- Module description
  local textWidth = scrollChild:GetWidth() - math.floor(moduleCheckbox:GetSize())
  local extraTextOffsetY = -16

  for i = 1, #description do
    local descriptionText = moduleCheckbox:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
    descriptionText:SetTextColor(1, 1, 1)
    descriptionText:SetFormattedText(description[i])
    descriptionText:SetPoint('LEFT', moduleCheckbox.Text, 'LEFT', 0, 0)
    descriptionText:SetPoint('TOP', moduleCheckbox, 'BOTTOM', 0, (i - 1) * extraTextOffsetY)
    descriptionText:SetJustifyH('LEFT')
    descriptionText:SetWidth(textWidth)

    lastFrameTop = descriptionText
  end

  createSubsettingOptions(moduleCheckbox, subsettings)
end

-- These base module cannot be toggled and only has subsettings.
local createBaseOptions = function(moduleEntry)
  local frameName = moduleEntry['frameName']
  local subsettings = moduleEntry['subsettings']

  local anchorFrame = CreateFrame('Frame', 'UIC_'..frameName, scrollChild)
  anchorFrame:SetPoint('LEFT', scrollChild, 'LEFT', 0, 0)
  anchorFrame:SetPoint('TOP', lastFrameTop, 'BOTTOM', 0, 10) -- There is already a gap above us, shorten it a bit
  anchorFrame:SetWidth(1)
  anchorFrame:SetHeight(1)

  lastFrameTop = anchorFrame

  createSubsettingOptions(anchorFrame, subsettings)
end

-- Show & HideTooltipFrame functions will be in the addonTable
addonTable.HideTooltipFrame = function()
  tooltipFrame:Hide()
end

addonTable.ShowTooltipFrame = function(leftAnchor, topAnchor, offsetX, title, text)
  tooltipFrame:SetPoint('LEFT', leftAnchor, 'LEFT', offsetX, 0);
  tooltipFrame:SetPoint('BOTTOM', topAnchor, 'TOP', 0, 0);

  tooltipFrame.Title:SetText(title)
  tooltipFrame.Text:SetText(text)

  -- Set the width and make sure we are not out of bounds
  local widthAvailable = math.floor(addonTable.SCREEN_WIDTH - tooltipFrame:GetBoundsRect())
  local maxFrameWidth = math.min(widthAvailable, 450) -- In case we have less than the target width available

  local stringWidth = math.ceil(math.max(tooltipFrame.Title:GetUnboundedStringWidth(), tooltipFrame.Text:GetUnboundedStringWidth()))
  stringWidth = stringWidth + tooltipFrame.rightPadding -- Have to account for the right padding when considering short strings

  local frameWidth = math.min(stringWidth, maxFrameWidth) -- Use the target width unless the text is shorter

  tooltipFrame:SetWidth(frameWidth)
  tooltipFrame.Title:SetWidth(frameWidth - tooltipFrame.rightPadding)
  tooltipFrame.Text:SetWidth(frameWidth - tooltipFrame.rightPadding)

  -- Now set the height
  local stringHeight = math.ceil(tooltipFrame.Title:GetHeight() + tooltipFrame.Text:GetHeight())
  local bottomPadding = text == '' and tooltipFrame.bottomPaddingTitle or tooltipFrame.bottomPaddingFull
  tooltipFrame:SetHeight(stringHeight + bottomPadding)

  tooltipFrame:Show()
end

local createTooltipFrame = function(parentFrame)
  tooltipFrame = CreateFrame('Frame', 'UIC_Options_Tooltip', parentFrame, 'BackdropTemplate')
  tooltipFrame:SetBackdrop(C.BACKDROP_INFO(18, 4, true))
  tooltipFrame:Hide()

  -- The default frame level clashes with the scrollbar frames which are sibling frames
  tooltipFrame:SetFrameLevel(tooltipFrame:GetFrameLevel() + 5)

  -- Using small offsets for fine tuning and need to account for them when showing the tooltip frame
  local leftOffsetX = 8
  tooltipFrame.rightPadding = 18

  local topOffsetY = -8
  local middleOffsetY = -6
  tooltipFrame.bottomPaddingTitle = -1 * (topOffsetY + middleOffsetY) + 2
  tooltipFrame.bottomPaddingFull = tooltipFrame.bottomPaddingTitle + 8

  tooltipFrame.Title = tooltipFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  tooltipFrame.Title:SetPoint('TOPLEFT', tooltipFrame, leftOffsetX, topOffsetY)
  tooltipFrame.Title:SetNonSpaceWrap(true)
  tooltipFrame.Title:SetJustifyH('LEFT')
  tooltipFrame.Title:SetSpacing(2)

  tooltipFrame.Text = tooltipFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  tooltipFrame.Text:SetTextColor(whiteFontColor[1], whiteFontColor[2], whiteFontColor[3], whiteFontColor[4])
  tooltipFrame.Text:SetPoint('TOPLEFT', tooltipFrame.Title, 'BOTTOMLEFT', 0, middleOffsetY)
  tooltipFrame.Text:SetJustifyH('LEFT')
  tooltipFrame.Text:SetSpacing(2)
end

local setupOptionsPanel = function()
  local optionsPanel = CreateFrame('Frame', 'UIC_Options', _G['InterfaceOptionsFramePanelContainer'].NineSlice)
  optionsPanel.name = 'UIChanges'
  optionsPanel:Hide()

  optionsPanel:SetScript('OnShow', function()
    for _, moduleEntry in ipairs(C.MODULES) do
      local moduleKey = moduleEntry['moduleKey']

      if moduleKey then
        local isModuleEnabled = UIChanges_Profile[moduleKey]

        moduleEntry['frame']:SetValue(isModuleEnabled)

        -- This makes the subsettings display the correct information
        if moduleEntry.subsettings and moduleEntry.subsettings.entries then
          for _, subEntry in ipairs(moduleEntry['subsettings']['entries']) do
            local subKey = subEntry['entryKey']
            local currentValue = UIChanges_Profile[subKey]

            subEntry['frame']:SetValue(currentValue)
          end
        end

        subframesSetEnable(moduleEntry, isModuleEnabled) -- This sets whether the subsettings are accepting user input
      end
    end
  end)

  local outerPanelWidth = _G['InterfaceOptionsFramePanelContainer']:GetWidth() - 20

  -- Header text
  local headerText = optionsPanel:CreateFontString(nil, 'ARTWORK', 'GameFontNormalLarge')
  headerText:SetText('UIChanges')
  headerText:SetPoint('TOPLEFT', optionsPanel, 12, -16)

  -- Informational text
  local infoText = optionsPanel:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  infoText:SetWidth(outerPanelWidth)
  infoText:SetJustifyH('LEFT')
  infoText:SetSpacing(2)
  infoText:SetText(L.OPTIONS_INFO)
  infoText:SetPoint('TOPLEFT', headerText, 7, -24)

  -- All the options will be within a scrollFrame
  local scrollFrame = CreateFrame('ScrollFrame', 'UIC_Options_ScrollFrame', optionsPanel, 'UIPanelScrollFrameTemplate')
  scrollFrame:SetPoint('TOPLEFT', infoText, 'BOTTOMLEFT', 0, -14) -- Y offset is needed so the scrolling elements won't touch the infoText
  scrollFrame:SetPoint('BOTTOMRIGHT', -27, 4)

  local scrollBar = scrollFrame.ScrollBar
  scrollBar.texture = scrollBar:CreateTexture(scrollBar:GetName()..'_Texture', 'ARTWORK')
  scrollBar.texture:SetTexture('Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew')
  scrollBar.texture:SetAllPoints()
  scrollBar.texture:SetColorTexture(0, 0, 0, 0.35)

  scrollChild = CreateFrame('Frame', 'UIC_Options_ScrollFrameChild', scrollFrame) -- This frame will be the one scrolling
  scrollChild:SetWidth(outerPanelWidth)
  scrollChild:SetHeight(1) -- Absolutely necessary

  scrollFrame:SetScrollChild(scrollChild)
  
  lastFrameTop = scrollChild

  createTooltipFrame(scrollFrame)

  return optionsPanel
end

local storeScreenSize = function()
  local screenWidth, screenHeight = GetPhysicalScreenSize()

  addonTable.SCREEN_WIDTH = math.floor(screenWidth)
  addonTable.SCREEN_HEIGHT = math.floor(screenHeight)
end

local EVENTS = {}
EVENTS['DISPLAY_SIZE_CHANGED'] = function()
  storeScreenSize()
end
EVENTS['UI_SCALE_CHANGED'] = function()
  storeScreenSize()
end

local UIC_Options = {}

UIC_Options.Initialize = function()
  local optionsPanel = setupOptionsPanel()

  -- Need to keep track of the screen size to prevent the tooltipFrame from getting out of bounds
  storeScreenSize()

  optionsPanel:SetScript('OnEvent', function(self, event, ...)
    EVENTS[event](...)
  end)

  C.REGISTER_EVENTS(optionsPanel, EVENTS)

  for _, moduleEntry in ipairs(C.MODULES) do
    if not moduleEntry['moduleKey'] then
      createBaseOptions(moduleEntry)
    else
      createModuleOptions(moduleEntry)
    end
  end

  InterfaceOptions_AddCategory(optionsPanel)
end

addonTable.UIC_Options = UIC_Options
