local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local tinsert, UISpecialFrames = tinsert, UISpecialFrames;
local LibStub = LibStub;

local AceGUI = LibStub("AceGUI-3.0");

local MacroManagerWindow = {
    container = nil;
};

function MacroManagerWindow.CreateIfNotCreated()
    if not MacroManagerWindow.container then
        MacroManagerWindow.Create();
    end
end

function MacroManagerWindow.Create()
    local windowWidget = AceGUI:Create("Window");
    local statusTable = MacroManagerSaved.MacroManagerWindow.statusTable;
    statusTable.height = statusTable.height or 600;
    statusTable.width = statusTable.width or 600;
    windowWidget:SetStatusTable(statusTable);

    -- Setting the frame to high as it was above the delete macro dialog box
    windowWidget.frame:SetFrameStrata("HIGH");
    windowWidget:SetTitle("MacroManager");
    windowWidget:SetCallback("OnClose", function()
        if Private.Layout.MacroEditor.iconPicker then
            Private.Layout.MacroEditor.iconPicker:Hide();
        end
        --AceGUI:Release(widget);
    end);
    windowWidget:SetLayout("Flow");

    -- Close the window when escape is pressed.
    -- Taken from https://stackoverflow.com/a/61215014
    -- Add the frame as a global variable under the name `MyGlobalFrameName`
    _G["MacroManagerFrame"] = windowWidget.frame;
    -- Register the global variable `MacroManagerFrame` as a "special frame"
    -- so that it is closed when the escape key is pressed.
    tinsert(UISpecialFrames, "MacroManagerFrame");

    -- Nested resizable children (the macro tree/editor divider's own StartSizing-based
    -- drag) don't track the mouse at all until this top-level frame has gone through one
    -- real StartMoving/StopMovingOrSizing cycle - confirmed by testing: on a fresh load,
    -- dragging the divider does nothing until the window itself is first moved or
    -- resized once. Simulate that cycle automatically instead of requiring the user to
    -- do it manually. Has to wait a frame - doing it immediately, before the window has
    -- ever been drawn, doesn't have the same effect (same reason MacroManagerTreeGroup's
    -- own FirstFrameUpdate exists).
    windowWidget.frame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil);
        self:StartMoving();
        self:StopMovingOrSizing();
    end);

    MacroManagerWindow.container = windowWidget;
end

Private.Layout.Window = MacroManagerWindow;