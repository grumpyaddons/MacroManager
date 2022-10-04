local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local GetMacroInfo, GetNumMacros = GetMacroInfo, GetNumMacros;
local GetTime, GetCurrentKeyBoardFocus, IsShiftKeyDown, UnitFullName = GetTime, GetCurrentKeyBoardFocus, IsShiftKeyDown, UnitFullName;
local LibStub = LibStub;

local AceGUI = LibStub("AceGUI-3.0");

local MacroTree = {
    container = nil,
    statusTable = {},
    onSelectedCallback = nil
};

function MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(uniqueValue)
    local macroType, macroIdString = ("\001"):split(uniqueValue);
    return macroType, tonumber(macroIdString)
end

function MacroTree.RefreshMacroFormBasedonSelectedTreeItem()
    local macroType, macroId = MacroTree.GetSelectedMacroTypeAndId();

    if macroType == "new" then
        Private.MacroEditor.RefreshMacroForm();
        return
    end

    local macroName, icon, macroBody = GetMacroInfo(macroId);
    Private.MacroEditor.RefreshMacroForm(macroId, macroName, icon, macroBody);
end

function MacroTree.GetSelectedMacroTypeAndId()
    -- Couldn't figure out how to get the actual value selected.
    -- Looked into the source code of TreeGroup and it delimits paths
    -- with "\001", so we can split on that and get the last value to
    -- get the macro index.
    if MacroTree.statusTable and MacroTree.statusTable.selected then
        if MacroTree.statusTable.selected == "new" then
            return "new", nil;
        end
        local macroType, macroId = MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(MacroTree.statusTable.selected);

        return macroType, macroId;
    end
    -- Default to the new macro tab if nothing is selected.
    return "new", nil;
end

function MacroTree.SelectNewMacro()
    MacroTree.container:SelectByValue("new");
end

function MacroTree.SelectMacro(macroType, macroId)
    local accountMacroCount, characterMacroCount = GetNumMacros();

    -- If there's no macros to select, go to the new macro tab.
    if (macroType == "character" and characterMacroCount == 0) or
        (macroType == "account" and accountMacroCount == 0) then
            MacroTree.container:SelectByValue("new");
            return
    end

    local idToSelect = macroId;

    -- Handle deleting the last macro in the character or account list.
    -- The behavior we expect is the selected item to be the previous one.
    if macroType == "character" then
        -- Offset character macros ID by 120 since that's the id they start at.
        if (macroId - 120) > characterMacroCount then
            idToSelect = characterMacroCount + 120;
        end
    elseif macroId > accountMacroCount then
        idToSelect = accountMacroCount
    end

    local path = macroType .. "\001" .. idToSelect;

    MacroTree.container:SelectByValue(path);
end

function MacroTree.GenerateMacroTree()
    local characterMacros = {};
    local accountMacros = {};
    local accountMacroCount, characterMacroCount = GetNumMacros();

    -- Account macros start at index 1 through 120
    for i=1, accountMacroCount do
        local name, texture, _ = GetMacroInfo(i);
        local data = {
            value = i,
            text = name,
            icon = texture
        };
        table.insert(accountMacros, data);
    end

    -- Character macros start at index 121 through 138
    for i=121, characterMacroCount + 120 do
        local name, texture, _ = GetMacroInfo(i);
        local data = {
            value = i,
            text = name,
            icon = texture
        };
        table.insert(characterMacros, data);
    end

    local tree = {
        {
            value = "new",
            text = "+ New Macro"
        },
        {
            value = "character",
            text = "Character Macros ("..characterMacroCount.."/18)",
            font = "GameFontHighlightSmall",
            disabled = true,
            children = characterMacros
        },
        {
            value = "account",
            text = "Account Macros ("..accountMacroCount.."/120)",
            font = "GameFontHighlightSmall",
            disabled = true,
            children = accountMacros
        },
    };

    MacroTree.container:SetTree(tree);
    MacroTree.container:SetFullWidth(true);
    if not MacroTree.statusTable.selected then
        MacroTree.container:SelectByValue("new");
    end

    -- Override the OnClick of buttons to support shift-clicking
    local buttonCount = table.getn(MacroTree.container.buttons)

    for i=1, buttonCount do
        local previousOnClick = MacroTree.container.buttons[i]:GetScript("OnClick");

        MacroTree.container.buttons[i]:SetScript("OnClick", function(self)
            if (IsShiftKeyDown()) then
                local _, macroId = MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(self.uniquevalue);
                local macroName, _, _ = GetMacroInfo(macroId);
                local editbox = GetCurrentKeyBoardFocus();
                local fullName = nil;
                if(editbox) then
                    if (not fullName) then
                        local name, realm = UnitFullName("player")
                        if realm then
                            fullName = name.."-".. realm
                        else
                            fullName = name
                        end
                    end

                    editbox:Insert("[MacroManager: "..fullName.." - "..macroName.."]");
                    Private.linked = Private.linked or {}
                    Private.linked[macroName] = GetTime()
                end
            else
                previousOnClick(self);
            end
        end);
    end
end

function MacroTree.CreateIfNotCreated()
    if not MacroTree.container then
        MacroTree.Create();
    end
end

function MacroTree.SetOnSelectedCallback(onSelectedCallback)
    MacroTree.onSelectedCallback = onSelectedCallback;
end

function MacroTree.Create()
    local macroTree = AceGUI:Create("MacroManagerTreeGroup");
    macroTree:SetLayout("Flow");

    -- Expand groups by default
    if not MacroTree.statusTable.groups then
        MacroTree.statusTable.groups = {};
        MacroTree.statusTable.groups["character"] = true;
        MacroTree.statusTable.groups["account"] = true;
    end
    macroTree:SetStatusTable(MacroTree.statusTable);

    if not MacroTree.statusTable.selected then
        macroTree:SelectByValue("new");
    end

    macroTree:SetCallback("OnGroupSelected", function()
        if MacroTree.onSelectedCallback then
            local macroType, macroId = MacroTree.GetSelectedMacroTypeAndId();
            MacroTree.onSelectedCallback(macroType, macroId);
        end
    end);

    MacroTree.container = macroTree;
end

Private.Layout.MacroTree = MacroTree;