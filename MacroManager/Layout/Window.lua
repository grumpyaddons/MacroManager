local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local tinsert, UISpecialFrames = tinsert, UISpecialFrames;
local LibStub = LibStub;

local AceGUI = LibStub("AceGUI-3.0");

local MacroManagerWindow = {
    container = nil;
    statusTable = {}
};

function MacroManagerWindow.CreateIfNotCreated()
    if not MacroManagerWindow.container then
        MacroManagerWindow.Create();
    end
end

function MacroManagerWindow.Create()
    local windowWidget = AceGUI:Create("Window");
    -- Couldn't figure out how to set the default height/width
    MacroManagerWindow.statusTable.height = MacroManagerWindow.statusTable.height or 600;
    MacroManagerWindow.statusTable.width = MacroManagerWindow.statusTable.width or 500;
    windowWidget:SetStatusTable(MacroManagerWindow.statusTable);

    -- Setting the frame to high as it was above the delete macro dialog box
    windowWidget.frame:SetFrameStrata("HIGH");
    windowWidget:SetTitle("MacroManager");
    windowWidget:SetCallback("OnClose", function()
        if Private.Layout.MacroEditor.iconPicker then
            Private.Layout.MacroEditor.iconPicker:Hide();
        end
        --AceGUI:Release(widget);
    end);
    windowWidget:SetLayout("Fill");

    -- Close the window when escape is pressed.
    -- Taken from https://stackoverflow.com/a/61215014
    -- Add the frame as a global variable under the name `MyGlobalFrameName`
    _G["MacroManagerFrame"] = windowWidget.frame;
    -- Register the global variable `MacroManagerFrame` as a "special frame"
    -- so that it is closed when the escape key is pressed.
    tinsert(UISpecialFrames, "MacroManagerFrame");

    MacroManagerWindow.container = windowWidget;
end

Private.Layout.Window = MacroManagerWindow;