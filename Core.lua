local AddonName, Private = ...

local AceGUI = LibStub("AceGUI-3.0");

local frame = nil;
local iconPicker = nil;

local sharedMacroLabel = nil;

local scrollStatusTable = {
    scrollvalue = 0,
    offset = 0
};

local frameStatusTable = {};
local iconPickerFrameStatusTable = {};

local macroTree = nil;
local macroTreeStatusTable = {};

local macroIcon = nil;
local macroBodyEditBox = nil;
local macroNameEditBox = nil;

local macroTypeRadioButtons = {};
macroTypeRadioButtons.characterMacroRadioButton = nil;
macroTypeRadioButtons.accountMacroRadioButton = nil;

function SetMacroTypeRadioButtons(macroIndexOrType)
    if macroIndexOrType == nil or macroIndexOrType == -1 then
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(false);
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(true);
    elseif macroIndexOrType == "account" then
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(true);
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(false);
    elseif macroIndexOrType == "character" then
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(false);
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(true);
    else
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(macroIndexOrType < 121)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(macroIndexOrType >= 121)
    end
end

function GetMacroTypeSelected()
    if macroTypeRadioButtons.accountMacroRadioButton:GetValue() then
        return "account";
    else
        return "character";
    end
end

function MacroTypeBasedOnIndex(macroIndex)
    if macroIndex < 121 then
        return "account"
    else
        return "character"
    end
end

StaticPopupDialogs["DELETE_MACRO"] = {
    text = "Do you want to delete the macro '%s'?",
    button1 = "Delete Macro",
    button2 = "Cancel",
    OnAccept = function(self, macroId)
        DeleteMacro(self.macroId);
        macroTree:SelectByValue("new");
        ShowMacroMicro();
        RefreshMacroFormBasedonSelectedTreeItem();
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 5
  }

  StaticPopupDialogs["MACRO_SAVE_ERROR"] = {
    text = "Couldn't save macro. %s",
    button1 = "Okay",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }

function Private.OpenSharedMacroWithData(data)
    ShowMacroMicro()
    macroTree:SelectByValue("new");
    Private.OpenSharedMacro(sharedMacroLabel, data);
end

function Private.OpenSharedMacro(label, data)
    local macroName, macroTexture, macroBody = "", "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK", ""
    if data then
        macroName = data.macroName;
        macroTexture = data.macroTexture;
        macroBody = data.macroBody;
    end
    macroIcon:SetImage(macroTexture);
    macroBodyEditBox:SetText(macroBody);

    macroNameEditBox:SetText(macroName);
    macroNameEditBox:SetFocus();
    SetMacroTypeRadioButtons();
end

local tree = { 
    {
        value = "new",
        text = "+ New Macro"
    },
    {
      value = "character",
      text = "Character Macros",
      disabled = true,
      children = {}
    },
    { 
      value = "account", 
      text = "Account Macros",
      disabled = true,
      children = {}
    },
  };

function GetSelectedMacroTypeAndId()
    -- Couldn't figure out how to get the actual value selected.
    -- Looked into the source code of TreeGroup and it delimits paths
    -- with "\001", so we can split on that and get the last value to
    -- get the macro index.
    if macroTreeStatusTable and macroTreeStatusTable.selected then
        if macroTreeStatusTable.selected == "new" then
            return "new", nil;
        end
        local macroType, macroIndex = GetMacroTypeAndMacroIdFromUniqueValue(macroTreeStatusTable.selected);

        return macroType, macroIndex;
    end
    -- Default to the new macro tab if nothing is selected.
    return "new", nil;
end

function GetMacroTypeAndMacroIdFromUniqueValue(uniqueValue)
    local macroType, macroIndexString = ("\001"):split(uniqueValue);
    return macroType, tonumber(macroIndexString)
end


function CreateSeparatorLabel()
    local label = AceGUI:Create("Label");
    label:SetText(" ");
    return label;
end

function CreateSeparatorLabel()
    local label = AceGUI:Create("Label");
    label:SetText(" ");
    return label
end

function GenerateMacroTree()
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

    return characterMacros, accountMacros;
end

function RefreshMacroFormBasedonSelectedTreeItem()
    local macroType, macroIndex = GetSelectedMacroTypeAndId();

    if macroType == "new" then
        RefreshMacroForm();
        return
    end

    local macroName, icon, macroBody = GetMacroInfo(macroIndex);
    RefreshMacroForm(macroIndex, macroName, icon, macroBody);
end

function RefreshMacroForm(macroType, macroName, icon, macroBody)
    if icon then
        macroIcon:SetImage(icon);
    else
        macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    end
    if not macroBody then
        -- Can't SetText with a nil value
        macroBody = "";
    end
    macroBodyEditBox:SetText(macroBody);
    macroBodyEditBox:Fire("OnTextChanged");
    macroNameEditBox:SetText(macroName);
    macroNameEditBox:Fire("OnTextChanged");
    SetMacroTypeRadioButtons(macroType);
end

function Show_Options()
    frame = AceGUI:Create("Window");
    -- Couldn't figure out how to set the default height/width
    frameStatusTable.height = frameStatusTable.height or 600;
    frameStatusTable.width = frameStatusTable.width or 500;
    frame:SetStatusTable(frameStatusTable);
    -- Setting the frame to high as it was above the delete macro dialog box
    frame.frame:SetFrameStrata("HIGH");
    frame:SetTitle("MacroMicro");
    frame:SetCallback("OnClose", function(widget)
        if iconPicker then
            iconPicker:Hide();
        end
        AceGUI:Release(widget);
    end);
    frame:SetLayout("Fill");

    -- Close on escape taken from https://stackoverflow.com/a/61215014
    -- Add the frame as a global variable under the name `MyGlobalFrameName`
    _G["MacroMicroFrame"] = frame.frame
    -- Register the global variable `MyGlobalFrameName` as a "special frame"
    -- so that it is closed when the escape key is pressed.
    tinsert(UISpecialFrames, "MacroMicroFrame")

    local macroTreeContainer = AceGUI:Create("SimpleGroup");
    macroTreeContainer:SetWidth(500);
    macroTreeContainer:SetLayout("Fill");
    macroTreeContainer:SetFullHeight(true); -- probably?
    frame:AddChild(macroTreeContainer)

    macroTree = AceGUI:Create("TreeGroup");
    macroTree:SetLayout("Flow");
    
    -- Expand groups by default
    if not macroTreeStatusTable.groups then
        macroTreeStatusTable.groups = {};
        macroTreeStatusTable.groups["character"] = true;
        macroTreeStatusTable.groups["account"] = true;
    end
    macroTree:SetStatusTable(macroTreeStatusTable);
    
    local characterMacros, accountMacros = GenerateMacroTree();
    tree[2].children = characterMacros;
    tree[3].children = accountMacros;
    macroTree:SetTree(tree);
    macroTree:SetFullWidth(true);
    if not macroTreeStatusTable.selected then
        macroTree:SelectByValue("new");
    end
    macroTreeContainer:SetFullWidth(true);
    macroTreeContainer:AddChild(macroTree);

    local macroTypeGroup = AceGUI:Create("SimpleGroup");
    macroTypeGroup:SetLayout("Flow");

    local macroTypeLabel = AceGUI:Create("Label");
    macroTypeLabel:SetText("Macro Type");
    -- Make label match the edit box labels. Taken from AceGUI source
    macroTypeLabel:SetColor(1,.82,0);
    macroTypeLabel:SetFontObject(GameFontNormalSmall);

    macroTypeRadioButtons.characterMacroRadioButton = AceGUI:Create("CheckBox");
    macroTypeRadioButtons.characterMacroRadioButton:SetLabel("Character Macro");
    macroTypeRadioButtons.characterMacroRadioButton:SetType("radio");
    macroTypeRadioButtons.characterMacroRadioButton:SetCallback("OnValueChanged", function(self)
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(not self:GetValue())
    end)

    macroTypeRadioButtons.accountMacroRadioButton = AceGUI:Create("CheckBox");
    macroTypeRadioButtons.accountMacroRadioButton:SetLabel("Account Macro");
    macroTypeRadioButtons.accountMacroRadioButton:SetType("radio");
    macroTypeRadioButtons.accountMacroRadioButton:SetCallback("OnValueChanged", function(self)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(not self:GetValue())
    end)

    macroTypeGroup:AddChild(macroTypeRadioButtons.characterMacroRadioButton);
    macroTypeGroup:AddChild(macroTypeRadioButtons.accountMacroRadioButton);

    macroNameEditBox = AceGUI:Create("EditBox");
    macroNameEditBox:SetLabel("Macro Name (0/16)");
    macroNameEditBox:SetWidth(200);
    macroNameEditBox:DisableButton(true);
    macroNameEditBox:SetMaxLetters(16);
    macroNameEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Name ("..string.len(macroNameEditBox:GetText()).."/16)");
    end);

    macroBodyEditBox = AceGUI:Create("MacroMicroMultiLineEditBox");
    macroBodyEditBox:SetLabel("Macro Body (0/255)");
    macroBodyEditBox:SetRelativeWidth(1);
    macroBodyEditBox:DisableButton(true);
    macroBodyEditBox:SetMaxLetters(255);
    macroBodyEditBox:SetNumLines(10);
    macroBodyEditBox.editBox:SetCountInvisibleLetters(true);
    macroBodyEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Body ("..string.len(macroBodyEditBox:GetText()).."/255)");
    end);

    macroIcon = AceGUI:Create("Icon");
    macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    macroIcon:SetImageSize(48, 48);
    macroIcon:SetCallback("OnClick", function(self)
        local macroType, macroIndex = GetSelectedMacroTypeAndId();
        if macroType ~= "new" then
            PickupMacro(macroIndex);
        end;
    end);
    macroIcon.frame:RegisterForDrag("LeftButton")
    macroIcon.frame:SetScript("OnDragStart", function(self)
        local macroType, macroIndex = GetSelectedMacroTypeAndId();
        if macroType ~= "new" then
            PickupMacro(macroIndex);
        end;
    end);

    local iconLabel = AceGUI:Create("Label");
    iconLabel:SetText("Macro Icon");
    -- Make label match the edit box labels. Taken from AceGUI source
    iconLabel:SetColor(1,.82,0);
    iconLabel:SetFontObject(GameFontNormalSmall);

    local changeIconButton = AceGUI:Create("Button");
    changeIconButton:SetText("Change");
    changeIconButton:SetWidth(100);
    changeIconButton:SetCallback("OnClick", function()
        LoadFileData();
        local lib = LibStub("LibAdvancedIconSelector-1.0-LMIS")    -- (ideally, this would be loaded on-demand)
        local options = {
            okayCancel = false
         };
        iconPicker = lib:CreateIconSelectorWindow("MacroMicroIconPicker", UIParent, options);
        iconPicker.iconsFrame:SetScript("OnSelectedIconChanged", function()
            macroIcon:SetImage("Interface\\Icons\\" .. iconPicker.iconsFrame.selectedButton.texture);
        end);
        iconPicker:SetPoint("TOP", frame.frame, "TOP");
        iconPicker:SetPoint("LEFT", frame.frame, "RIGHT");
        iconPicker:Show();
    end);

    local saveButton = AceGUI:Create("Button");
    saveButton:SetText("Save");
    saveButton:SetWidth(100);
    saveButton:SetCallback("OnClick", function()
        local newName = macroNameEditBox:GetText();

        if string.len(newName) == 0 then
            StaticPopup_Show("MACRO_SAVE_ERROR", "Macro name can't be empty.");
            return
        end

        local editorMacroType = GetMacroTypeSelected();

        local accountMacroCount, characterMacroCount = GetNumMacros();

        local newBody = macroBodyEditBox:GetText();
        local newIcon = macroIcon.image:GetTexture();

        -- Stay a while and listen.
        -- This if statement is needed for a convoluted reason.
        -- By convention if you pass "INV_MISC_QUESTIONMARK" to the EditMacro command,
        -- the server will automatically assume the correct icon based on the spell or
        -- if the macro has "#showtooltip" in it.
        -- Now, if for some reason you modified the macro icon to something custom,
        -- you will not be able to use "#showtooltip" in that same macro and instead
        -- you need to recreate the macro. I don't know if people deal with this a lot,
        -- but this if statement basically fixes that scenario by allowing you to use
        -- "#showtooltip" again. Overall an improvement albiet simple one.
        -- HOWEVER, I survyed like 10 people and that didn't seem like much of an issue
        -- and if I modified the behavior from the default macro UI, people might be confused.
        -- Therefore, I'm going to comment this out for now but keep it because I spent
        -- too much time figuring it out and I might bring it back
        --
        -- if string.find(newBody, "#showtooltip") then
        --     newIcon = "INV_MISC_QUESTIONMARK";
        -- end

        local selectedMacroType, selectedMacroIndex = GetSelectedMacroTypeAndId();

        if selectedMacroType == "new" then
            if editorMacroType == "character" and characterMacroCount == 18 then
                StaticPopup_Show("MACRO_SAVE_ERROR", "You can only have 18 character macros. Delete one before creating a new one.");
                return
            elseif editorMacroType == "account" and accountMacroCount == 120 then
                StaticPopup_Show("MACRO_SAVE_ERROR", "You can only have 120 account macros. Delete one before creating a new one.");
                return
            end
            local isCharacterMacro = editorMacroType == "character";
            -- 134400 is the question mark icon
            local newMacroId = CreateMacro(newName, newIcon, newBody, isCharacterMacro);
            ShowMacroMicro();

            local path = editorMacroType .. "\001" .. newMacroId;
            macroTree:SelectByValue(path);
            RefreshMacroFormBasedonSelectedTreeItem();
        else
            local newMacroId;
            -- Was the macro type changed from account to character or vice versa?
            if editorMacroType == MacroTypeBasedOnIndex(selectedMacroIndex) then
                -- Macro type hasn't changed, just do an edit macro
                newMacroId = EditMacro(selectedMacroIndex, newName, newIcon, newBody);
            else
                -- Macro type changed, delete and add new macro
                DeleteMacro(selectedMacroIndex);
                local isCharacterMacro = editorMacroType == "character";
                newMacroId = CreateMacro(newName, newIcon, newBody, isCharacterMacro);
            end

            ShowMacroMicro();
            local newMacroType = "account";
            if newMacroId >= 121 then
                newMacroType = "character";
            end
            local path = newMacroType .. "\001" .. newMacroId;
            macroTree:SelectByValue(path);
            RefreshMacroFormBasedonSelectedTreeItem();
        end
    end);

    local deleteButton = AceGUI:Create("Button");
    deleteButton:SetText("Delete");
    deleteButton:SetWidth(100);
    deleteButton:SetCallback("OnClick", function()
        local macroType, macroIndex = GetSelectedMacroTypeAndId();

        if macroType == "new" then
            -- Creating a new macro, can't delete it. Should probably hide this button.
            return
        end

        local selectedMacroType, selectedMacroIndex = GetSelectedMacroTypeAndId()
        local currentMacroName, _, _ = GetMacroInfo(selectedMacroIndex);
        local dialog = StaticPopup_Show("DELETE_MACRO", currentMacroName);
        if (dialog) then
            dialog.macroId = selectedMacroIndex;
        end
    end)

    local scrollcontainer = AceGUI:Create("SimpleGroup");
    scrollcontainer:SetFullWidth(true);
    scrollcontainer:SetFullHeight(true); -- probably?
    scrollcontainer:SetLayout("Fill"); -- important!

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetStatusTable(scrollStatusTable);
    scrollcontainer:AddChild(scroll)

    scroll:AddChild(macroTypeLabel);
    scroll:AddChild(macroTypeGroup);
    -- Don't need a seperator here because the inline group has a buffer.
    scroll:AddChild(macroNameEditBox);
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(iconLabel);
    scroll:AddChild(macroIcon);
    scroll:AddChild(changeIconButton);
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(macroBodyEditBox);
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(saveButton);
    scroll:AddChild(deleteButton);

    local shareInfoLabel = AceGUI:Create("Label");
    shareInfoLabel:SetFullWidth(true);
    shareInfoLabel:SetText("To share a macro, shift-click it in the left menu while your chat box is open. Similar to how WeakAuras are shared.");
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(CreateSeparatorLabel());
    scroll:AddChild(shareInfoLabel);

    macroTree:AddChild(scroll);

    RefreshMacroFormBasedonSelectedTreeItem();

    -- Override the OnClick of buttons to support shift-clicking
    local buttonCount = table.getn(macroTree.buttons)
    for i=1, table.getn(macroTree.buttons) do
        local previousOnClick = macroTree.buttons[i]:GetScript("OnClick");

        macroTree.buttons[i]:SetScript("OnClick", function(self)
            if (IsShiftKeyDown()) then
                local macroType, macroIndex = GetMacroTypeAndMacroIdFromUniqueValue(self.uniquevalue);
                local macroName, icon, macroBody = GetMacroInfo(macroIndex);
                local editbox = GetCurrentKeyBoardFocus();
                local fullName;
                if(editbox) then
                    if (not fullName) then
                    local name, realm = UnitFullName("player")
                    if realm then
                        fullName = name.."-".. realm
                    else
                        fullName = name
                    end
                    end

                    editbox:Insert("[MacroMicro: "..fullName.." - "..macroName.."]");
                    Private.linked = Private.linked or {}
                    Private.linked[macroName] = GetTime()
                end
            else
                previousOnClick(self);
                local macroType, macroIndex = GetSelectedMacroTypeAndId();
                RefreshMacroFormBasedonSelectedTreeItem();
            end
        end);
    end
end

SlashCmdList["MACROMICRO"] = function()
    ShowMacroMicro()
end
SLASH_MACROMICRO1 = "/macromanager";
SLASH_MACROMICRO2 = "/macromicro";
SLASH_MACROMICRO2 = "/mm";

function ShowMacroMicro() 
    if frame and frame:IsVisible() then
        frame.frame:Hide();
    end
    Show_Options();
end

-- save memory by only loading FileData when needed
function LoadFileData()
    local addon = "MacroMicroData";
    if not Private.FileData then
        local loaded, reason = LoadAddOn(addon)
        if not loaded then
            if reason == "DISABLED" then
                EnableAddOn(addon, true)
                LoadAddOn(addon)
            else
                error(addon.." is "..reason)
            end
        end
        local fd = _G[addon]
        Private.FileData = MacroMicro.IsRetail() and fd:GetFileDataRetail() or fd:GetFileDataClassic()
    end
end


hooksecurefunc("ChatEdit_InsertLink", function(text)
    -- Code taken and modified from
    -- https://github.com/Gethe/wow-ui-source/blob/f43c2b83f700177e6a2a215f5d7d0c0825abd636/Interface/FrameXML/ChatFrame.lua#L4549
	if ( not text ) then
		return
	end
    if ( macroBodyEditBox and macroBodyEditBox.editBox:HasFocus() ) then
        local valueToInsert = text;

        local cursorPosition = macroBodyEditBox.editBox:GetCursorPosition();
        local isTheStartOfAnEmptyLine = cursorPosition == 0 or strsub(macroBodyEditBox.editBox:GetText(), cursorPosition, cursorPosition) == "\n";

        local isItem = strfind(text, "item:", 1, true);
        local isSpell = strfind(text, "spell:", 1, true);

        if isItem then
            local item = GetItemInfo(text);
            if isTheStartOfAnEmptyLine then
                if ( GetItemSpell(item) ) then
                    valueToInsert = "/use "..item.."\n";
                else
                    valueToInsert = "/equip "..item.."\n";
                end
            else
                valueToInsert = item
            end
        elseif isSpell then
            local _, _, spellId = string.find(text, "spell:(%d+):");
            local spellName = GetSpellInfo(tonumber(spellId));

            if isTheStartOfAnEmptyLine then
                valueToInsert = "/cast "..spellName.."\n";
            else
                valueToInsert = spellName;
            end
        end

        macroBodyEditBox.editBox:Insert(valueToInsert);
    end
end);