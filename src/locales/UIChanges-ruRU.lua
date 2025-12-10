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

local locale = {}

-- Translator: ZamestoTV
addonTable.ruRU = locale

locale.OPTIONS_INFO_1 = 'Настройки, изменяющие переменные консоли, должны быть включены вне боя и требуют перезагрузки интерфейса для вступления в силу. Затем необходимо выйти из игры, чтобы сохранить измененные переменные консоли.'
locale.FIRST_TIME = 'UI Changes обнаружил новые переменные для этого персонажа! Пожалуйста, посетите страницу Interface Options/AddOns/UIChanges, чтобы ознакомиться с доступными опциями.'
locale.CVAR_CHANGED = 'UI Changes: Переменная консоли изменена, пожалуйста, перезагрузите интерфейс!'
locale.CANT_CHANGE_IN_COMBAT = 'UI Changes: Невозможно изменить настройки во время боя! Пожалуйста, проверьте страницу настроек снова после боя.'
locale.PLAY_SOUND = 'Воспроизвести '..SOUND..' для'
locale.INCOMPATIBLE_MODULES_TEXT = 'Модули, несовместимые с этой версией игры и текущим персонажем:'

locale.ANCHOR_TOPLEFT = 'Верхний левый'
locale.ANCHOR_TOP = 'Верх'
locale.ANCHOR_TOPRIGHT = 'Верхний правый'
locale.ANCHOR_RIGHT = 'Правый'
locale.ANCHOR_BOTTOMRIGHT = 'Нижний правый'
locale.ANCHOR_BOTTOM = 'Низ'
locale.ANCHOR_BOTTOMLEFT = 'Нижний левый'
locale.ANCHOR_LEFT = 'Левый'

-- Base Options
locale.MINIMAP_QUICK_ZOOM = 'Быстрое масштабирование миникарты'
locale.TOOLTIP_MINIMAP_QUICK_ZOOM = 'Shift-клик по кнопкам + / - на миникарте для максимального увеличения/уменьшения.'
-- ~Base Options

-- AbsorbDisplay
locale.ABSORB_DISPLAY_1 = 'Отображает приблизительное поглощение, предоставляемое '
locale.ABSORB_DISPLAY_2 = 'Вы можете перетаскивать отображение, удерживая CTRL.'
-- ~AbsorbDisplay

-- AHTools
locale.AHT = {
  'Предоставляет простой калькулятор стоимости стаков и отображает предупреждение о возможных мошенничествах.',
  'Также позволяет кликнуть средней кнопкой мыши на предмет в сумках, чтобы начать поиск по имени предмета.'
}
-- ~AHTools

-- BagUtilities
locale.BU = {'Открывает сумки и моллюсков после их поднятия.'}
-- ~BagUtilities

-- CriticalReminders
locale.CR = {
  'Делает выбранные предупреждения более заметными, отображая иконку ошибки и, при желании, воспроизводя звук.',
  'Когда опция привязки установлена в "Выкл.", отображение можно перетаскивать, удерживая CTRL, или сбросить с помощью кнопки.'
}

locale.ERROR_FRAME_ANCHOR_DROPDOWN = 'Привязка к рамке цели'

locale.CR_SUBSETTING_STRINGS = {
  ['BREATH_WARNING']      = 'Предупреждение о дыхании',
  ['COMBAT_WARNING']      = 'Предупреждение о бое',
  ['GATHERING_FAILURE']   = 'Неудача при сборе',
  ['COMBAT_LOS']          = 'Потеря видимости в бою',
  ['COMBAT_DIRECTION']    = 'Направление в бою',
  ['COMBAT_RANGE']        = 'Дальность в бою',
  ['COMBAT_INTERRUPTED']  = 'Прерывание в бою',
  ['COMBAT_COOLDOWN']     = 'Перезарядка в бою',
  ['COMBAT_NO_RESOURCE']  = 'Отсутствие ресурса в бою',
  ['INTERACTION_RANGE']   = 'Дальность взаимодействия',
}
-- ~CriticalReminders

-- DruidManaBar
locale.DMB = {'Показывает панель маны, когда персонаж находится в форме друида, не использующей ману.'}
-- ~DruidManaBar

-- PartyPetFrames
locale.PPF_1 = 'Восстанавливает скрытые рамки питомцев и добавляет отсутствующие панели энергии при использовании стандартных групповых рамок.'
locale.PPF_2 = 'Это изменяет переменную консоли! Если вы собираетесь удалить аддон, сначала отключите эту опцию и выйдите из игры.'
-- ~PartyPetFrames

-- PingAnnouncer
locale.PA = {
  'Отправляет сообщение в группу, когда вы кликаете на объект миникарты, чтобы уведомить членов группы.',
  'Удерживайте CTRL при клике, чтобы отправить сообщение всем членам рейда или поля боя.'
}

locale.PINGED = 'Пинг'
locale.NEARBY = 'поблизости!'
locale.DIRECTION = 'на'

locale.EAST = 'Восток'
locale.WEST = 'Запад'
locale.NORTH = 'Север'
locale.SOUTH = 'Юг'
-- ~PingAnnouncer

-- SpellTargetDisplay
locale.STD = {'Отображает имя цели под полосой заклинания при произнесении заклинания. '..locale.ABSORB_DISPLAY_2}
-- ~SpellTargetDisplay
