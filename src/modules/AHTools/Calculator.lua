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

local calculatorFrame, equalsFrame, multiplierFrame, timesFrame, inputFrame, resultFrame

local setColor = function(frame, isValid)
  if isValid then
    frame:SetTextColor(1, 1, 1, 1)
  else
    frame:SetTextColor(1, 0, 0, 1)
  end
end

local updateResult = function()
  local input = MoneyInputFrame_GetCopper(inputFrame)
  local isValidInput = MoneyInputFrame_GetCopper(inputFrame) ~= 0

  local multiplier = multiplierFrame:GetNumber()
  local isValidMultiplier = multiplier > 0 and multiplier <= 200

  local showResult = isValidInput and isValidMultiplier

  setColor(multiplierFrame, isValidMultiplier)
  setColor(timesFrame, isValidInput)
  setColor(equalsFrame, showResult)

  if not showResult then
    resultFrame:Hide()
    return
  end

  local newResult = MoneyInputFrame_GetCopper(inputFrame) * multiplierFrame:GetNumber()

  MoneyInputFrame_SetCopper(resultFrame, newResult)

  resultFrame:Show()
end

local hookFrameScripts = function()
  MoneyInputFrame_SetPreviousFocus(inputFrame, multiplierFrame)
  MoneyInputFrame_SetNextFocus(inputFrame, multiplierFrame)

  multiplierFrame:HookScript('OnTabPressed', function(self)
    if not IsShiftKeyDown() then
      inputFrame.gold:SetFocus()
    else
      inputFrame.copper:SetFocus()
    end
  end)

  multiplierFrame:HookScript('OnEnterPressed', function(self)
    self:ClearFocus()
  end)

  inputFrame.gold:HookScript('OnTextChanged', function(self)
    updateResult()
  end)

  inputFrame.silver:HookScript('OnTextChanged', function(self)
    updateResult()
  end)

  inputFrame.copper:HookScript('OnTextChanged', function(self)
    updateResult()
  end)

  multiplierFrame:HookScript('OnTextChanged', function(self)
    updateResult()
  end)
end

local initializeFrames = function()
  calculatorFrame = CreateFrame('Frame', 'UIC_AHT_Mini_Calculator', _G['AuctionFrame'], 'BackdropTemplate')
  calculatorFrame:SetBackdrop(C.BACKDROP_INFO(8, 1))
  calculatorFrame:SetBackdropColor(0, 0, 0, 1)
  calculatorFrame:SetSize(265, 50)

  -- Start from right to left as we will need to alter the size of the gold related frames to accommodate larger amounts
  equalsFrame = calculatorFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  equalsFrame:SetPoint('RIGHT', calculatorFrame, 'RIGHT', -6, 0)
  equalsFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, -4)
  equalsFrame:SetTextColor(1, 1, 1, 1)
  equalsFrame:SetScale(1.5)
  equalsFrame:SetText('=')

  multiplierFrame = CreateFrame('EditBox', 'UIC_AHT_Mini_Calculator_Multiplier', calculatorFrame, 'InputBoxTemplate')
  multiplierFrame:SetScale(0.9)
  multiplierFrame:SetSize(35, 14)
  multiplierFrame:SetPoint('RIGHT', equalsFrame, 'LEFT', -6, 0)
  multiplierFrame:SetPoint('TOP', equalsFrame, 'TOP', 0, -2)
  multiplierFrame:SetAutoFocus(false)
  multiplierFrame:SetNumeric(true)
  multiplierFrame:SetMaxLetters(3)

  timesFrame = calculatorFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  timesFrame:SetPoint('RIGHT', multiplierFrame, 'LEFT', -8, 0)
  timesFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, -7)
  timesFrame:SetTextColor(1, 1, 1, 1)
  timesFrame:SetScale(1.2)
  timesFrame:SetText('X')

  inputFrame = CreateFrame('Frame', 'UIC_AHT_Mini_Calculator_Input', calculatorFrame, 'MoneyInputFrameTemplate')
  inputFrame:SetPoint('RIGHT', timesFrame, 'LEFT', -15, 0)
  inputFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, -6)
  inputFrame:SetScale(0.9)

  local x, y = inputFrame.gold:GetSize()
  inputFrame.gold:SetSize(x + 15, y)

  resultFrame = CreateFrame('Frame', 'UIC_AHT_Mini_Calculator_Result', calculatorFrame, 'MoneyInputFrameTemplate')
  resultFrame:SetPoint('RIGHT', inputFrame, 'RIGHT', 0, 0)
  resultFrame:SetPoint('TOP', inputFrame, 'BOTTOM', 0, -6)
  resultFrame:SetScale(0.9)

  x, y = resultFrame.gold:GetSize()
  resultFrame.gold:SetSize(x + 15, y)
  resultFrame.gold:SetMaxLetters(13)

  resultFrame.gold:SetEnabled(false)
  resultFrame.silver:SetEnabled(false)
  resultFrame.copper:SetEnabled(false)

  calculatorFrame:Hide()

  hookFrameScripts()
end

local Calculator = {}

Calculator.new = function()
  local self = {}

  initializeFrames()

  function self.LoadedAH()
    calculatorFrame:SetPoint('RIGHT', _G['AuctionFrame'], 'RIGHT', 0, 0)
    calculatorFrame:SetPoint('BOTTOM', _G['AuctionFrame'], 'TOP', 0, 0)
  end

  function self.Show()
    calculatorFrame:Show()
  end

  function self.Hide()
    calculatorFrame:Hide()
  end

  return self
end

addonTable.Calculator = Calculator
