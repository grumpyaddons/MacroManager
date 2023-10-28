local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local GetMacroInfo, CreateMacro, EditMacro, DeleteMacro, PickupMacro, GetNumMacros = GetMacroInfo, CreateMacro, EditMacro, DeleteMacro, PickupMacro, GetNumMacros;
local LoadAddOn, EnableAddOn, StaticPopup_Show, StaticPopupDialogs = LoadAddOn, EnableAddOn, StaticPopup_Show, StaticPopupDialogs;
local GameFontNormalSmall = GameFontNormalSmall;
local LibStub = LibStub;
local UIParent = UIParent;

local AceGUI = LibStub("AceGUI-3.0");

local MacroEditor = {
    container = nil,
    mode = "new",
    statusTable = {},

    selectedMacro = {
        index = nil,
        type = nil,
        name = nil,
        icon = nil,
        body = nil
    },

    macroTypeRadioButtons = {
        characterMacroRadioButton = nil,
        accountMacroRadioButton = nil
    },
    macroIconWidget = nil,
    macroNameWidget = nil,
    macroBodyWidget = nil,
    macroDeleteWidget = nil,

    iconPicker = nil,

    OnMacroSaveCallback = nil,
    OnMacroDeleteCallback = nil
};

StaticPopupDialogs["DELETE_MACRO"] = {
    text = "Do you want to delete the macro '%s'?",
    button1 = "Delete Macro",
    button2 = "Cancel",
    OnAccept = function(self)
        DeleteMacro(self.macroId);
        MacroEditor.OnMacroDeleteCallback(self.macroType, self.macroId);
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 5
};

StaticPopupDialogs["MACRO_SAVE_ERROR"] = {
    text = "Couldn't save macro. %s",
    button1 = "Okay",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
};

function MacroEditor.SetOnMacroSaveCallback(OnMacroSaveCallback)
    MacroEditor.OnMacroSaveCallback = OnMacroSaveCallback;
end

function MacroEditor.SetOnMacroDeleteCallback(OnMacroDeleteCallback)
    MacroEditor.OnMacroDeleteCallback = OnMacroDeleteCallback;
end

function MacroEditor.SetEditModeByMacroId(macroId)
    local macroName, macroIcon, macroBody = GetMacroInfo(macroId);
    MacroEditor.SetEditMode(macroId, macroName, macroIcon, macroBody);
end

function MacroEditor.SetEditMode(macroId, macroName, macroIcon, macroBody)
    MacroEditor.mode = "edit";
    MacroEditor.selectedMacro = {
        index = macroId,
        type = Private.Helpers.MacroTypeBasedOnIndex(macroId),
        name = macroName,
        icon = macroIcon,
        body = macroBody,
        iconModified = false
    };

    MacroEditor.RefreshWidgets();
end

-- "new" mode is used when creating a new macro or importing a shared macro
function MacroEditor.SetNewMode(macroName, macroIcon, macroBody)
    MacroEditor.mode = "new";
    MacroEditor.selectedMacro = {
        index = nil,
        type = "character",
        name = macroName,
        icon = macroIcon,
        body = macroBody,
        iconModified = false
    };
    MacroEditor.RefreshWidgets();
end

function MacroEditor.RefreshWidgets()
    if MacroEditor.selectedMacro.icon then
        MacroEditor.macroIconWidget:SetImage(MacroEditor.selectedMacro.icon);
    else
        MacroEditor.macroIconWidget:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    end

    local isAccountMacro = MacroEditor.selectedMacro.type == "account";
    MacroEditor.macroTypeRadioButtons.accountMacroRadioButton:SetValue(isAccountMacro);
    MacroEditor.macroTypeRadioButtons.characterMacroRadioButton:SetValue(not isAccountMacro);

    -- Set edit box value and force OnTextChanged to update label with character count
    MacroEditor.macroNameWidget:SetText(MacroEditor.selectedMacro.name);
    MacroEditor.macroNameWidget:Fire("OnTextChanged");

    local macroBody = MacroEditor.selectedMacro.body;
    if not macroBody then
        -- Can't SetText with a nil value
        macroBody = "";
    end

    -- Same as name widget update
    MacroEditor.macroBodyWidget:SetText(macroBody);
    MacroEditor.macroBodyWidget:Fire("OnTextChanged");

    if MacroEditor.mode == "new" then
        MacroEditor.macroDeleteWidget.frame:Hide();
    else
        MacroEditor.macroDeleteWidget.frame:Show();
    end
end

function MacroEditor.LoadIconPickerData()
    -- save memory by only loading FileData when needed
    local addon = "MacroManagerData";
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
        Private.FileData = Private.Addon.IsRetail() and fd:GetFileDataRetail() or fd:GetFileDataClassic()
    end
end

function MacroEditor.CreateSeparatorLabel()
    local label = AceGUI:Create("Label");
    label:SetText(" ");
    return label;
end

function MacroEditor.CreateIfNotCreated()
    if not MacroEditor.container then
        MacroEditor.Create();
        MacroEditor.SetNewMode();
    end
end

function MacroEditor.Create()
    local macroTypeRadioButtons = {};
    macroTypeRadioButtons.characterMacroRadioButton = nil;
    macroTypeRadioButtons.accountMacroRadioButton = nil;
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
        macroTypeRadioButtons.accountMacroRadioButton:SetValue(not self:GetValue());
        local macroType;
        if self:GetValue() then
            macroType = "character";
        else
            macroType = "account";
        end;
        MacroEditor.selectedMacro.type = macroType;
    end)

    macroTypeRadioButtons.accountMacroRadioButton = AceGUI:Create("CheckBox");
    macroTypeRadioButtons.accountMacroRadioButton:SetLabel("Account Macro");
    macroTypeRadioButtons.accountMacroRadioButton:SetType("radio");
    macroTypeRadioButtons.accountMacroRadioButton:SetCallback("OnValueChanged", function(self)
        macroTypeRadioButtons.characterMacroRadioButton:SetValue(not self:GetValue());
        local macroType;
        if self:GetValue() then
            macroType = "account";
        else
            macroType = "character";
        end;
        MacroEditor.selectedMacro.type = macroType;
    end)

    macroTypeGroup:AddChild(macroTypeRadioButtons.characterMacroRadioButton);
    macroTypeGroup:AddChild(macroTypeRadioButtons.accountMacroRadioButton);

    local macroNameEditBox = AceGUI:Create("EditBox");
    macroNameEditBox:SetLabel("Macro Name (0/16)");
    macroNameEditBox:SetWidth(200);
    macroNameEditBox:DisableButton(true);
    macroNameEditBox:SetMaxLetters(16);
    macroNameEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Name ("..string.len(macroNameEditBox:GetText()).."/16)");
    end);

    local macroBodyEditBox = AceGUI:Create("MacroManagerMultiLineEditBox");
    macroBodyEditBox:SetLabel("Macro Body (0/255)");
    macroBodyEditBox:SetRelativeWidth(1);
    macroBodyEditBox:DisableButton(true);
    macroBodyEditBox:SetMaxLetters(255);
    macroBodyEditBox:SetNumLines(10);
    macroBodyEditBox.editBox:SetCountInvisibleLetters(true);
    macroBodyEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Body ("..string.len(macroBodyEditBox:GetText()).."/255)");
    end);

    local macroIcon = AceGUI:Create("Icon");
    macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    macroIcon:SetImageSize(48, 48);
    macroIcon:SetCallback("OnClick", function()
        if MacroEditor.mode ~= "new" then
            PickupMacro(MacroEditor.selectedMacro.index);
        end;
    end);
    macroIcon.frame:RegisterForDrag("LeftButton")
    macroIcon.frame:SetScript("OnDragStart", function()
        if MacroEditor.mode ~= "new" then
            PickupMacro(MacroEditor.selectedMacro.index);
        end;
    end);

    local iconLabel = AceGUI:Create("Label");
    iconLabel:SetText("Macro Icon");
    -- Make label match the edit box labels. Taken from AceGUI source
    iconLabel:SetColor(1,.82,0);
    iconLabel:SetFontObject(GameFontNormalSmall);

    local changeIconButton = AceGUI:Create("Button");
    changeIconButton:SetText("Select Icon");
    changeIconButton:SetWidth(125);
    changeIconButton:SetCallback("OnClick", function()
        MacroEditor.LoadIconPickerData();
        local lib = LibStub("LibAdvancedIconSelector-1.0-LMIS")    -- (ideally, this would be loaded on-demand)
        local options = {
            okayCancel = false,
            keywordAddonName = "MacroManagerData"
         };
        if not MacroEditor.iconPicker then
            MacroEditor.iconPicker = lib:CreateIconSelectorWindow("MacroManagerIconPicker", UIParent, options);
        end
        MacroEditor.iconPicker.iconsFrame:SetScript("OnSelectedIconChanged", function()
            macroIcon:SetImage("Interface\\Icons\\" .. MacroEditor.iconPicker.iconsFrame.selectedButton.texture);
            MacroEditor.selectedMacro.iconModified = true;
        end);
        MacroEditor.iconPicker:ClearAllPoints();
        MacroEditor.iconPicker:SetPoint("TOP", Private.Layout.Window.container.frame, "TOP");
        MacroEditor.iconPicker:SetPoint("LEFT", Private.Layout.Window.container.frame, "RIGHT");
        MacroEditor.iconPicker:Show();
    end);

    local useQuestionMarkIconButton = AceGUI:Create("Button");
    useQuestionMarkIconButton:SetText("Reset Icon (?)");
    useQuestionMarkIconButton:SetWidth(125);
    useQuestionMarkIconButton:SetCallback("OnClick", function()
        macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
        MacroEditor.selectedMacro.iconModified = true;
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

        local accountMacroCount, characterMacroCount = GetNumMacros();

        local newBody = macroBodyEditBox:GetText();
        local newIcon = macroIcon.image:GetTexture();

        -- 134400 is the ID for the question mark icon. But the macro API
        -- will only support #showtooltip if you save the macro with this string value
        if newIcon == 134400 then
            newIcon = "INV_MISC_QUESTIONMARK";
        end

        -- Stay a while and listen.
        -- This if statement is needed for a convoluted reason.
        -- By convention if you pass "INV_MISC_QUESTIONMARK" to the EditMacro command,
        -- the server will automatically assume the correct icon based on the spell or
        -- if the macro has "#showtooltip" in it.
        -- Now, if for some reason you modified the macro icon to something custom,
        -- you will not be able to use "#showtooltip" in that same macro and instead
        -- you need to recreate the macro. I don't know if people deal with this a lot,
        -- but this if statement basically fixes that scenario by allowing you to use
        -- "#showtooltip" again. Overall an improvement albeit a simple one.
        -- HOWEVER, I survyed like 10 people and that didn't seem like much of an issue
        -- and if I modified the behavior from the default macro UI, people might be confused.
        -- Therefore, I'm going to comment this out for now but keep it because I spent
        -- too much time figuring it out and I might bring it back.
        --
        -- if string.find(newBody, "#showtooltip") then
        --     newIcon = "INV_MISC_QUESTIONMARK";
        -- end

        local newMacroId;
        if MacroEditor.mode == "new" then
            if MacroEditor.selectedMacro.type == "character" and characterMacroCount == 18 then
                StaticPopup_Show(
                    "MACRO_SAVE_ERROR",
                    "You can only have 18 character macros. Delete one before creating a new one."
                );
                return
            elseif MacroEditor.selectedMacro.type == "account" and accountMacroCount == 120 then
                StaticPopup_Show(
                    "MACRO_SAVE_ERROR",
                    "You can only have 120 account macros. Delete one before creating a new one."
                );
                return
            end
            local isCharacterMacro = MacroEditor.selectedMacro.type == "character";
            newMacroId = CreateMacro(newName, newIcon, newBody, isCharacterMacro);
            MacroEditor.SetEditMode(newMacroId, newName, newIcon, newBody);
        else
            -- Was the macro type changed from the original value?
            if MacroEditor.selectedMacro.type == Private.Helpers.MacroTypeBasedOnIndex(MacroEditor.selectedMacro.index)
            then
                -- Only use the selected icon image if the icon was modified.
                -- Otherwise set the new icon to nil so that it doesn't override the existing icon of the macro.
                if not MacroEditor.selectedMacro.iconModified then
                    newIcon = nil;
                end

                -- Macro type hasn't changed, just do an edit macro
                newMacroId = EditMacro(MacroEditor.selectedMacro.index, newName, newIcon, newBody);
            else
                -- Macro type changed, delete and add new macro because macro API
                -- doesn't support editing macro type.
                -- But first, check to make sure you can create new macros of tha type.
                if MacroEditor.selectedMacro.type == "character" and characterMacroCount == 18 then
                    StaticPopup_Show(
                        "MACRO_SAVE_ERROR",
                        "You can only have 18 character macros. Delete one before creating a new one."
                    );
                    return
                elseif MacroEditor.selectedMacro.type == "account" and accountMacroCount == 120 then
                    StaticPopup_Show(
                        "MACRO_SAVE_ERROR",
                        "You can only have 120 account macros. Delete one before creating a new one."
                    );
                    return
                end

                local isCharacterMacro = MacroEditor.selectedMacro.type == "character";
                newMacroId = CreateMacro(newName, newIcon, newBody, isCharacterMacro);
                -- Do a create THEN a delete so that if the create fails we don't delete
                -- the macro. If we do a delete first then a create and the create fails
                -- we lose the macro.
                DeleteMacro(MacroEditor.selectedMacro.index);
            end
            MacroEditor.SetEditMode(newMacroId, newName, newIcon, newBody);
        end

        MacroEditor.OnMacroSaveCallback(MacroEditor.selectedMacro.type, newMacroId);
    end);

    local deleteButton = AceGUI:Create("Button");
    deleteButton:SetText("Delete");
    deleteButton:SetWidth(100);
    deleteButton:SetCallback("OnClick", function()
        if MacroEditor.mode == "new" then
            -- Creating a new macro, can't delete it.
            -- I tried hiding this button when in "new" mode but it is still
            -- visible the first time you open the window.
            return
        end

        local currentMacroName, _, _ = GetMacroInfo(MacroEditor.selectedMacro.index);
        local dialog = StaticPopup_Show("DELETE_MACRO", currentMacroName);
        if (dialog) then
            dialog.macroId = MacroEditor.selectedMacro.index;
            dialog.macroType = Private.Helpers.MacroTypeBasedOnIndex(MacroEditor.selectedMacro.index)
        end
    end);

    local scrollcontainer = AceGUI:Create("SimpleGroup");
    scrollcontainer:SetFullWidth(true);
    scrollcontainer:SetFullHeight(true); -- probably?
    scrollcontainer:SetLayout("Fill"); -- important!

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetStatusTable(MacroEditor.statusTable);
    scrollcontainer:AddChild(scroll)

    scroll:AddChild(macroTypeLabel);
    scroll:AddChild(macroTypeGroup);
    -- Don't need a seperator here because the inline group has a buffer.
    scroll:AddChild(macroNameEditBox);
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(iconLabel);
    scroll:AddChild(macroIcon);
    scroll:AddChild(changeIconButton);
    scroll:AddChild(useQuestionMarkIconButton);
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(macroBodyEditBox);
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(saveButton);
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(deleteButton);

    local shareInfoLabel = AceGUI:Create("Label");
    shareInfoLabel:SetFullWidth(true);
    shareInfoLabel:SetText(
        "To share a macro, shift-click it in the left menu while your chat box is open. " ..
        "Similar to how WeakAuras are shared.\n\nBoth users must have MacroManager installed for sharing to work."
    );
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(shareInfoLabel);

    MacroEditor.macroTypeRadioButtons = macroTypeRadioButtons
    MacroEditor.macroIconWidget = macroIcon;
    MacroEditor.macroNameWidget = macroNameEditBox;
    MacroEditor.macroBodyWidget = macroBodyEditBox;
    MacroEditor.macroDeleteWidget = deleteButton;

    MacroEditor.container = scrollcontainer;
end

Private.Layout.MacroEditor = MacroEditor;