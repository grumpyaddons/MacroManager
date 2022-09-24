--[[-----------------------------------------------------------------------------
SecureActionButton
-------------------------------------------------------------------------------]]
local Type, Version = "SecureActionButton", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(24)
		self:SetWidth(24)
        self:SetTexture()
        self:SetMacroText()
    end,

    ["OnRelease"] = function(self)
        -- make sure to remove the cooldown if present, needed because frames are
        -- shared and reused. Else you'll see cooldowns on other frames also.
        if self.myCooldown then
            self.myCooldown:SetCooldown(0, 0)
        end
    end,

    ["SetTexture"] = function(self, key_data)
        local icon = nil
        if key_data and key_data.icon then
            icon = key_data.icon
        else
            -- default texture
            icon = "Interface\\Icons\\Inv_misc_questionmark"
        end

        -- create textzre
        local t = self.frame:CreateTexture(nil,"BACKGROUND",nil,-6)
        t:SetTexture(icon)
        t:SetAllPoints(self.frame) --make texture same size as button
        self.frame:SetNormalTexture(t)

        -- create cooldown if applicable
        if key_data then
            local start, duration = 0, 0

            if key_data.spell_name then
                start, duration = GetSpellCooldown(key_data.spell_name, "BOOKTYPE_SPELL")
            end

            if key_data.item_id then
                start, duration = GetItemCooldown(key_data.item_id)
            end

            if start > 0 then
                self.myCooldown = CreateFrame("Cooldown", "myCooldown", self.frame, "CooldownFrameTemplate")
                self.myCooldown:SetAllPoints()
                self.myCooldown:SetCooldown(start, duration)
            end
        end
    end,

    ["SetMacroText"] = function(self, macro_text)
        self.frame:SetAttribute("type1", "macro")
        self.frame:SetAttribute("macrotext1", macro_text)
    end,

}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
    local num = AceGUI:GetNextWidgetNum(Type)
    local frame = CreateFrame("Button", nil, UIParent, "SecureActionButtonTemplate")

	local widget = {
		frame = frame,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)