local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local GetMacroInfo, GetNumMacros, PickupMacro = GetMacroInfo, GetNumMacros, PickupMacro;
local GetTime, GetCurrentKeyBoardFocus, IsShiftKeyDown = GetTime, GetCurrentKeyBoardFocus, IsShiftKeyDown;
local LibStub, strsplit = LibStub, strsplit;
local RAID_CLASS_COLORS = RAID_CLASS_COLORS;
local MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS;

local AceGUI = LibStub("AceGUI-3.0");

local MacroTree = {
    container = nil,
    statusTable = {},
    onSelectedCallback = nil,
    filterString = nil
};

function MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(uniqueValue)
    local parts = { strsplit("\001", uniqueValue) };
    local macroType = parts[1];

    -- Snapshot values are 3 parts: "snapshot", the character name, then the macro's
    -- index within that character's stored snapshot.
    if macroType == "snapshot" then
        return macroType, tonumber(parts[3]), parts[2];
    end

    return macroType, tonumber(parts[2]);
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
        local macroType, macroId, characterName = MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(MacroTree.statusTable.selected);

        return macroType, macroId, characterName;
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
        -- Character macro IDs start right after the account macros.
        if (macroId - MAX_ACCOUNT_MACROS) > characterMacroCount then
            idToSelect = characterMacroCount + MAX_ACCOUNT_MACROS;
        end
    elseif macroId > accountMacroCount then
        idToSelect = accountMacroCount
    end

    local path = macroType .. "\001" .. idToSelect;

    MacroTree.container:SelectByValue(path);
end

-- This is our 'search' function - it will return a boolean value indicating whether the element matches
--   our search query or not. This is where you'd want to add extra conditions or checks if extending this code
local function MatchesQuery(element, query)
    element = element:lower() -- ensure case-insensitive comparison, remove these two lines if this is undesirable
    query = query:lower()

    local initPos = 1 -- controls the position from which we begin the string comparison. 1 is the first character
    local noPatternMatch = true -- disables lua pattern matching on the string.find call
    return string.find(element, query, initPos, noPatternMatch) ~= nil
end

local function isempty(s)
    return s == nil or s == ''
end

-- Colors a tree row by the character's class, matching how class colors are
-- used elsewhere in WoW's UI (friends list, guild roster, etc). Falls back to
-- nil (default header color) if the class isn't known yet, e.g. an old
-- snapshot captured before class tracking was added.
local function ClassColorStr(characterName)
    local classToken = Private.CharacterSnapshots.GetClass(characterName);
    local color = classToken and RAID_CLASS_COLORS[classToken];
    return color and color.colorStr;
end

function MacroTree.GenerateMacroTree()
    -- Keep this character's read-only snapshot fresh any time we look at the tree,
    -- not just at login.
    Private.CharacterSnapshots.CaptureCurrentCharacter();

    local characterMacros = {};
    local accountMacros = {};
    local accountMacroCount, characterMacroCount = GetNumMacros();

    local accountMacrosVisible = 0;
    -- Account macros occupy indices 1 through MAX_ACCOUNT_MACROS
    for i=1, accountMacroCount do
        local name, texture, _ = GetMacroInfo(i);
        local data = {
            value = i,
            text = name,
            icon = texture,
            visible = isempty(MacroTree.filterString) or MatchesQuery(name, MacroTree.filterString)
        };
        table.insert(accountMacros, data);
        if data.visible == true then
            accountMacrosVisible = accountMacrosVisible + 1
        end
    end

    local characterMacrosVisible = 0;
    -- Character macros start right after the account macros
    for i=MAX_ACCOUNT_MACROS + 1, characterMacroCount + MAX_ACCOUNT_MACROS do
        local name, texture, _ = GetMacroInfo(i);
        local data = {
            value = i,
            text = name,
            icon = texture,
            visible = isempty(MacroTree.filterString) or MatchesQuery(name, MacroTree.filterString)
        };
        table.insert(characterMacros, data);
        if data.visible == true then
            characterMacrosVisible = characterMacrosVisible + 1
        end
    end

    local noMacrosLabel = {
        value = -1,
        text = "None",
        visible = true,
        disabled = true
    };

    if accountMacrosVisible == 0 then
        table.insert(accountMacros, noMacrosLabel);
    end

    if characterMacrosVisible == 0 then
        table.insert(characterMacros, noMacrosLabel);
    end

    -- Read-only snapshots of every other character's character-specific macros,
    -- captured the last time each of them logged in. The current character is
    -- excluded since their live macros are already shown above.
    local currentCharacterName = Private.CharacterSnapshots.GetFullCharacterName();
    local snapshots = Private.CharacterSnapshots.GetAll();

    local snapshotCharacterNames = {};
    for characterName in pairs(snapshots) do
        if characterName ~= currentCharacterName then
            table.insert(snapshotCharacterNames, characterName);
        end
    end
    table.sort(snapshotCharacterNames);

    local snapshotGroups = {};
    for _, characterName in ipairs(snapshotCharacterNames) do
        local macros = Private.CharacterSnapshots.GetMacros(characterName);
        local children = {};
        local visibleCount = 0;

        for index, macro in ipairs(macros) do
            local data = {
                value = index,
                text = macro.name,
                icon = macro.icon,
                visible = isempty(MacroTree.filterString) or MatchesQuery(macro.name, MacroTree.filterString)
            };
            table.insert(children, data);
            if data.visible == true then
                visibleCount = visibleCount + 1
            end
        end

        if visibleCount == 0 then
            table.insert(children, noMacrosLabel);
        end

        table.insert(snapshotGroups, {
            value = characterName,
            text = characterName.." ("..#macros.."/"..MAX_CHARACTER_MACROS..")",
            font = "GameFontHighlightSmall",
            classColor = ClassColorStr(characterName),
            -- Only the name itself (the first `nameLength` characters of `text`)
            -- gets class-colored; the "(x/y)" count stays the default header gold.
            nameLength = #characterName,
            disabled = true,
            visible = true,
            children = children
        });
    end

    if #snapshotGroups == 0 then
        table.insert(snapshotGroups, noMacrosLabel);
    end

    local tree = {
        {
            value = "new",
            text = "+ New Macro"
        },
        {
            value = "character",
            text = currentCharacterName.." ("..characterMacroCount.."/"..MAX_CHARACTER_MACROS..")",
            font = "GameFontHighlightSmall",
            classColor = ClassColorStr(currentCharacterName),
            -- Only the name itself (the first `nameLength` characters of `text`)
            -- gets class-colored; the "(x/y)" count stays the default header gold.
            nameLength = #currentCharacterName,
            disabled = true,
            visible = true,
            children = characterMacros
        },
        {
            value = "account",
            text = "Account Macros ("..accountMacroCount.."/"..MAX_ACCOUNT_MACROS..")",
            font = "GameFontHighlightSmall",
            disabled = true,
            visible = true,
            children = accountMacros
        },
        {
            value = "snapshot",
            text = "Character Snapshots",
            font = "GameFontHighlightSmall",
            disabled = true,
            visible = true,
            children = snapshotGroups
        },
    };

    -- Have to set this to true so the `visible` property works on the tree elements
    local filterFlag = true;
    MacroTree.container:SetTree(tree, filterFlag);
    MacroTree.container:SetFullWidth(true);
    if not MacroTree.statusTable.selected then
        MacroTree.container:SelectByValue("new");
    end

    -- Override the OnClick of buttons to support shift-clicking
    local buttonCount = table.getn(MacroTree.container.buttons)

    for i=1, buttonCount do
        local previousOnClick = MacroTree.container.buttons[i]:GetScript("OnClick");

        MacroTree.container.buttons[i]:RegisterForDrag("LeftButton")
        MacroTree.container.buttons[i]:SetScript("OnDragStart", function(self)
            -- Snapshot entries aren't real macro slots on this character, and header
            -- rows (group/character labels, now clickable to expand/collapse) have no
            -- macroId at all, so there's nothing valid to pick up for either.
            local macroType, macroId = MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(self.uniquevalue);
            if macroId ~= nil and (macroType == "account" or macroType == "character") then
                PickupMacro(macroId);
            end
        end);

        MacroTree.container.buttons[i]:SetScript("OnClick", function(self)
            local macroType, macroId, characterName = MacroTree.GetMacroTypeAndMacroIdFromUniqueValue(self.uniquevalue);
            if (IsShiftKeyDown()) and macroId ~= nil and (macroType == "account" or macroType == "character" or macroType == "snapshot") then
                local macroName, snapshot;

                if macroType == "snapshot" then
                    local macro = Private.CharacterSnapshots.GetMacro(characterName, macroId);
                    if not macro then
                        return
                    end
                    macroName = macro.name;
                    -- Since the snapshot owner may not even be online, we serve this
                    -- share request ourselves from our cached copy rather than asking
                    -- them to fulfill it live.
                    snapshot = { characterName = characterName, index = macroId };
                else
                    macroName = GetMacroInfo(macroId);
                end

                local editbox = GetCurrentKeyBoardFocus();
                if(editbox) then
                    local fullName = Private.CharacterSnapshots.GetFullCharacterName();

                    editbox:Insert("[MacroManager: "..fullName.." - "..macroName.."]");
                    Private.linked = Private.linked or {}
                    Private.linked[macroName] = { time = GetTime(), snapshot = snapshot };
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

function MacroTree.SetFilterString(value)
    MacroTree.filterString = value;
end

function MacroTree.Create()
    local macroTree = AceGUI:Create("MacroManagerTreeGroup");
    macroTree:SetLayout("List");
    macroTree:SetFullHeight(true);

    -- Back this with the saved-variable table (instead of the transient default
    -- assigned above) so expand/collapse, search, and selection survive relogs.
    MacroTree.statusTable = MacroManagerSaved.MacroManagerWindow.macroTreeStatusTable;

    -- Expand groups by default. Only takes effect the first time this ever runs,
    -- since after that `.groups` is already populated (and persisted).
    if not MacroTree.statusTable.groups then
        MacroTree.statusTable.groups = {};
        MacroTree.statusTable.groups["character"] = true;
        MacroTree.statusTable.groups["account"] = true;
        -- Expand one level so the list of characters is visible; each
        -- character's own macros still start collapsed.
        MacroTree.statusTable.groups["snapshot"] = true;
    end
    macroTree:SetStatusTable(MacroTree.statusTable);

    if not MacroTree.statusTable.selected then
        macroTree:SelectByValue("new");
    end

    macroTree:SetCallback("OnGroupSelected", function()
        if MacroTree.onSelectedCallback then
            local macroType, macroId, characterName = MacroTree.GetSelectedMacroTypeAndId();
            MacroTree.onSelectedCallback(macroType, macroId, characterName);
        end
    end);

    MacroTree.container = macroTree;
end

Private.Layout.MacroTree = MacroTree;