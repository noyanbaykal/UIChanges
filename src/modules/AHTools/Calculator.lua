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

local _, sharedTable = ...

local C = sharedTable.C

local calculatorFrame, inputFrame, multiplierFrame, resultFrame

local updateResult = function()
  local newResult = 0
  local g = 0
  local b = 0

  if MoneyInputFrame_GetCopper(inputFrame) ~= 0 and multiplierFrame:GetNumber() ~= 0 then
    newResult = MoneyInputFrame_GetCopper(inputFrame) * multiplierFrame:GetNumber()
    g = 1
    b = 1
  end

  calculatorFrame.timesFrame:SetTextColor(1, g, b, 1)
  calculatorFrame.equalsFrame:SetTextColor(1, g, b, 1)

  if newResult == 0 then
    resultFrame:Hide()
  else
    MoneyInputFrame_SetCopper(resultFrame, newResult)
    resultFrame:Show()
  end
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
  calculatorFrame:SetSize(275, 50)

  inputFrame = CreateFrame('Frame', 'UIC_AHT_Mini_Calculator_Input', calculatorFrame, 'MoneyInputFrameTemplate')
  inputFrame:SetPoint('LEFT', calculatorFrame, 'LEFT', 10, 0)
  inputFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, -6)
  inputFrame:SetScale(0.9)

  calculatorFrame.timesFrame = calculatorFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
  calculatorFrame.timesFrame:SetPoint('LEFT', inputFrame, 'RIGHT', 0, 0)
  calculatorFrame.timesFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, -7)
  calculatorFrame.timesFrame:SetTextColor(1, 1, 1, 1)
  calculatorFrame.timesFrame:SetScale(1.2)
  calculatorFrame.timesFrame:SetText('X')

  multiplierFrame = CreateFrame('EditBox', 'UIC_AHT_Mini_Calculator_Multiplier', calculatorFrame, 'InputBoxTemplate')
  multiplierFrame:SetScale(0.9)
  multiplierFrame:SetWidth(50)
  multiplierFrame:SetPoint('LEFT', calculatorFrame.timesFrame, 'RIGHT', 15, 0)
  multiplierFrame:SetPoint('TOP', calculatorFrame, 'TOP', 0, 0)
  multiplierFrame:SetAutoFocus(false)
  multiplierFrame:SetNumeric(true);
  multiplierFrame:SetMaxLetters(3)

  calculatorFrame.equalsFrame = calculatorFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  calculatorFrame.equalsFrame:SetPoint('LEFT', multiplierFrame, 'RIGHT', 8, 0)
  calculatorFrame.equalsFrame:SetTextColor(1, 1, 1, 1)
  calculatorFrame.equalsFrame:SetScale(1.5)
  calculatorFrame.equalsFrame:SetText('=')

  local resultFrameName = 'UIC_AHT_Mini_Calculator_Result'
  resultFrame = CreateFrame('Frame', resultFrameName, calculatorFrame, 'MoneyInputFrameTemplate')
  resultFrame:SetPoint('LEFT', calculatorFrame, 'LEFT', 10, 0)
  resultFrame:SetPoint('TOP', inputFrame, 'BOTTOM', 0, -6)
  resultFrame:SetScale(0.9)

  _G[resultFrameName..'Gold']:SetEnabled(false)
  _G[resultFrameName..'Silver']:SetEnabled(false)
  _G[resultFrameName..'Copper']:SetEnabled(false)

  calculatorFrame:Hide()

  hookFrameScripts()
end

Calculator = {}

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

return Calculator
