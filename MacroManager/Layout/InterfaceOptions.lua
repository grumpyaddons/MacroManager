local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local InterfaceOptions_AddCategory, CreateFrame, CloseWindows = InterfaceOptions_AddCategory, CreateFrame, CloseWindows;

local panel = CreateFrame("Frame");
panel.name = "MacroManager";

if InterfaceOptions_AddCategory then
   InterfaceOptions_AddCategory(panel);
else
   local category, layout = _G.Settings.RegisterCanvasLayoutCategory(panel, panel.name)
   _G.Settings.RegisterAddOnCategory(category)
end

local title = panel:CreateFontString("ARTWORK", nil, "GameFontNormalLarge");
title:SetPoint("TOPLEFT", 10, -15);
title:SetText("MacroManager");

local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
button:SetText("Open MacroManager");
button:SetPoint("TOPLEFT", title, 5, -25);
button:SetSize(150, 28)
button:SetScript("OnClick", function()
   while CloseWindows() do end;
   Private.main.ToggleWindow();
end)

local instructions = panel:CreateFontString("ARTWORK", nil, "GameFontWhite");
instructions:SetJustifyH("LEFT");
instructions:SetJustifyV("TOP");
instructions:SetPoint("TOPLEFT", button, 5, -35);
instructions:SetText([[
Type `/mm` or `/macromanager` to open the MacroManager UI.

Built by Grrumpy <Coldblooded> - Faerlina (US)
]]);