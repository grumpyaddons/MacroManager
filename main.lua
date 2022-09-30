local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local SlashCmdList = SlashCmdList;

local main = {}

SLASH_MACROMICRO1 = "/macromanager";
SLASH_MACROMICRO2 = "/mm";
SlashCmdList["MACROMICRO"] = function()
    main.ToggleWindow()
end

Private.Layout = Private.Layout or {};

function main.ToggleWindow()
    if not Private.Layout.Window.container then
        -- Addon hasn't been run yet, run it once.
        main.WireUpWidgets();
    else
        if Private.Layout.Window.container.frame:IsVisible() then
            Private.Layout.Window.container.frame:Hide();
        else
            Private.Layout.Window.container.frame:Show();
            -- Refresh macros in case they were changed in the default macro UI
            Private.Layout.MacroTree.GenerateMacroTree();
        end
    end
end

function main.ShowWindow()
    if not Private.Layout.Window.container.frame:IsVisible() then
        Private.Layout.Window.container.frame:Show();
        -- Refresh macros in case they were changed in the default macro UI
        Private.Layout.MacroTree.GenerateMacroTree();
    end
end

function main.WireUpWidgets()
    Private.Layout.Window.CreateIfNotCreated();
    Private.Layout.MacroEditor.CreateIfNotCreated();
    Private.Layout.MacroTree.CreateIfNotCreated();

    Private.Layout.MacroTree.SetOnSelectedCallback(function(macroType, macroId)
        if macroType == "new" then
            Private.Layout.MacroEditor.SetNewMode()
        else
            Private.Layout.MacroEditor.SetEditModeByMacroId(macroId);
        end
    end);
    Private.Layout.MacroEditor.SetOnMacroSaveCallback(function(macroType, macroId)
        Private.Layout.MacroTree.GenerateMacroTree();
        Private.Layout.MacroTree.SelectMacro(macroType, macroId);
    end);

    Private.Layout.MacroEditor.SetOnMacroDeleteCallback(function(macroType, macroId)
        Private.Layout.MacroTree.GenerateMacroTree();
        Private.Layout.MacroTree.SelectMacro(macroType, macroId);
    end);

    Private.Layout.MacroTree.container:AddChild(Private.Layout.MacroEditor.container);
    Private.Layout.Window.container:AddChild(Private.Layout.MacroTree.container);

    -- Have to do this because the buttons in the tree are not generated until after
    -- the widgets are shown by being attached to the main Window. We need the buttons
    -- generated because this function loops over them and gives them a new onClick
    -- handle to support shift-clicking the macros for sharing.
    Private.Layout.MacroTree.GenerateMacroTree();
end

function main.OpenSharedMacroWithData(data)
    Private.Layout.MacroTree.SelectNewMacro();
    Private.Layout.MacroEditor.SetNewMode(data.macroName, data.macroIcon, data.macroBody);
end

Private.main = main;