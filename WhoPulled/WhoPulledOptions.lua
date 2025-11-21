-- Создание кнопки у миникарты
local WhoPulledMinimapButton = CreateFrame("Button", "WhoPulledMinimapButton", Minimap)
WhoPulledMinimapButton:SetWidth(31)
WhoPulledMinimapButton:SetHeight(31)
WhoPulledMinimapButton:SetFrameStrata("MEDIUM")

-- Текстура кнопки (используем иконку слежения)
WhoPulledMinimapButton.icon = WhoPulledMinimapButton:CreateTexture(nil, "BACKGROUND")
WhoPulledMinimapButton.icon:SetWidth(20)
WhoPulledMinimapButton.icon:SetHeight(20)
WhoPulledMinimapButton.icon:SetPoint("CENTER")
WhoPulledMinimapButton.icon:SetTexture("Interface\\Icons\\Ability_Hunter_SniperShot")

-- Рамка кнопки
WhoPulledMinimapButton.overlay = WhoPulledMinimapButton:CreateTexture(nil, "OVERLAY")
WhoPulledMinimapButton.overlay:SetWidth(53)
WhoPulledMinimapButton.overlay:SetHeight(53)
WhoPulledMinimapButton.overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
WhoPulledMinimapButton.overlay:SetPoint("TOPLEFT")

-- Окно настроек
local WhoPulledConfigFrame = CreateFrame("Frame", "WhoPulledConfigFrame", UIParent)
WhoPulledConfigFrame:SetWidth(300)
WhoPulledConfigFrame:SetHeight(400)
WhoPulledConfigFrame:SetPoint("CENTER")
WhoPulledConfigFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
WhoPulledConfigFrame:SetBackdropColor(0,0,0,1)
WhoPulledConfigFrame:SetMovable(true)
WhoPulledConfigFrame:EnableMouse(true)
WhoPulledConfigFrame:RegisterForDrag("LeftButton")
WhoPulledConfigFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
WhoPulledConfigFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
WhoPulledConfigFrame:Hide()

-- Заголовок окна
local title = WhoPulledConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -15)
title:SetText("Who Pulled? - Настройки")

-- Чекбокс авто-крик при пуле боссов
local yonbossCheck = CreateFrame("CheckButton", "WhoPulledYonbossCheck", WhoPulledConfigFrame, "UICheckButtonTemplate")
yonbossCheck:SetPoint("TOPLEFT", 20, -50)
yonbossCheck.text = yonbossCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
yonbossCheck.text:SetPoint("LEFT", yonbossCheck, "RIGHT", 5, 0)
yonbossCheck.text:SetText("Авто-крик при пуле боссов")
yonbossCheck:SetChecked(WhoPulled_Settings["yonboss"])
yonbossCheck:SetScript("OnClick", function(self)
    WhoPulled_Settings["yonboss"] = self:GetChecked()
end)

-- Чекбокс предупреждение рейда
local rwonbossCheck = CreateFrame("CheckButton", "WhoPulledRwonbossCheck", WhoPulledConfigFrame, "UICheckButtonTemplate")
rwonbossCheck:SetPoint("TOPLEFT", 20, -80)
rwonbossCheck.text = rwonbossCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rwonbossCheck.text:SetPoint("LEFT", rwonbossCheck, "RIGHT", 5, 0)
rwonbossCheck.text:SetText("Предупреждение рейда вместо крика")
rwonbossCheck:SetChecked(WhoPulled_Settings["rwonboss"])
rwonbossCheck:SetScript("OnClick", function(self)
    WhoPulled_Settings["rwonboss"] = self:GetChecked()
end)

-- Чекбокс тихий режим
local silentCheck = CreateFrame("CheckButton", "WhoPulledSilentCheck", WhoPulledConfigFrame, "UICheckButtonTemplate")
silentCheck:SetPoint("TOPLEFT", 20, -110)
silentCheck.text = silentCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
silentCheck.text:SetPoint("LEFT", silentCheck, "RIGHT", 5, 0)
silentCheck.text:SetText("Тихий режим")
silentCheck:SetChecked(WhoPulled_Settings["silent"])
silentCheck:SetScript("OnClick", function(self)
    WhoPulled_Settings["silent"] = self:GetChecked()
end)

-- Поле для кастомного сообщения
local msgLabel = WhoPulledConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
msgLabel:SetPoint("TOPLEFT", 20, -150)
msgLabel:SetText("Сообщение:")

local msgEditBox = CreateFrame("EditBox", "WhoPulledMsgEditBox", WhoPulledConfigFrame, "InputBoxTemplate")
msgEditBox:SetWidth(250)
msgEditBox:SetHeight(20)
msgEditBox:SetPoint("TOPLEFT", 20, -170)
msgEditBox:SetAutoFocus(false)
msgEditBox:SetText(WhoPulled_Settings["msg"])
msgEditBox:SetScript("OnTextChanged", function(self)
    WhoPulled_Settings["msg"] = self:GetText()
end)

-- Подсказка для сообщения
local msgHint = WhoPulledConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
msgHint:SetPoint("TOPLEFT", 20, -195)
msgHint:SetText("%p - игрок, %e - враг")
msgHint:SetTextColor(0.8, 0.8, 0.8)

-- Поле для списка танков
local tanksLabel = WhoPulledConfigFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
tanksLabel:SetPoint("TOPLEFT", 20, -220)
tanksLabel:SetText("Танки (через запятую):")

local tanksEditBox = CreateFrame("EditBox", "WhoPulledTanksEditBox", WhoPulledConfigFrame, "InputBoxTemplate")
tanksEditBox:SetWidth(250)
tanksEditBox:SetHeight(20)
tanksEditBox:SetPoint("TOPLEFT", 20, -240)
tanksEditBox:SetAutoFocus(false)
tanksEditBox:SetText(WhoPulled_Tanks)
tanksEditBox:SetScript("OnTextChanged", function(self)
    WhoPulled_Tanks = " "..self:GetText().." "
    WhoPulled_Settings["tanks"] = self:GetText() -- Сохраняем в настройки
end)

-- Кнопка очистки пулов
local clearButton = CreateFrame("Button", "WhoPulledClearButton", WhoPulledConfigFrame, "UIPanelButtonTemplate")
clearButton:SetWidth(120)
clearButton:SetHeight(25)
clearButton:SetPoint("BOTTOMLEFT", 20, 20)
clearButton:SetText("Очистить пулы")
clearButton:SetScript("OnClick", function()
    WhoPulled_ClearPulledList()
    DEFAULT_CHAT_FRAME:AddMessage("Список пулов очищен")
end)

-- Кнопка закрытия
local closeButton = CreateFrame("Button", "WhoPulledCloseButton", WhoPulledConfigFrame, "UIPanelButtonTemplate")
closeButton:SetWidth(120)
closeButton:SetHeight(25)
closeButton:SetPoint("BOTTOMRIGHT", -20, 20)
closeButton:SetText("Закрыть")
closeButton:SetScript("OnClick", function()
    WhoPulledConfigFrame:Hide()
end)

-- Функции для кнопки миникарты
WhoPulledMinimapButton:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        if WhoPulledConfigFrame:IsShown() then
            WhoPulledConfigFrame:Hide()
        else
            -- Обновляем поля при открытии окна
            yonbossCheck:SetChecked(WhoPulled_Settings["yonboss"])
            rwonbossCheck:SetChecked(WhoPulled_Settings["rwonboss"])
            silentCheck:SetChecked(WhoPulled_Settings["silent"])
            msgEditBox:SetText(WhoPulled_Settings["msg"])
            tanksEditBox:SetText(WhoPulled_Tanks)
            WhoPulledConfigFrame:Show()
        end
    elseif button == "RightButton" then
        WhoPulled_ClearPulledList()
        DEFAULT_CHAT_FRAME:AddMessage("Список пулов очищен")
    end
end)

WhoPulledMinimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Who Pulled?")
    GameTooltip:AddLine("ЛКМ - Открыть настройки", 1, 1, 1)
    GameTooltip:AddLine("ПКМ - Очистить пулы", 1, 1, 1)
    GameTooltip:Show()
end)

WhoPulledMinimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Позиционирование кнопки у миникарты
WhoPulledMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 
    WhoPulled_Settings.minimapPos or -15, 
    WhoPulled_Settings.minimapPosY or -15)

-- Добавляем команду для открытия настроек
SlashCmdList["WHOPULLEDCONFIG"] = function() 
    -- Обновляем поля при открытии через команду
    yonbossCheck:SetChecked(WhoPulled_Settings["yonboss"])
    rwonbossCheck:SetChecked(WhoPulled_Settings["rwonboss"])
    silentCheck:SetChecked(WhoPulled_Settings["silent"])
    msgEditBox:SetText(WhoPulled_Settings["msg"])
    tanksEditBox:SetText(WhoPulled_Tanks)
    WhoPulledConfigFrame:Show() 
end
SLASH_WHOPULLEDCONFIG1 = "/wpconfig"