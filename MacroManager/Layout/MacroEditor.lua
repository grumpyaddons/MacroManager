local _, Private = ...;

-- Contain accessing undefined variables to one place to remove linter warnings.
local GetMacroInfo, CreateMacro, EditMacro, DeleteMacro, PickupMacro, GetNumMacros = GetMacroInfo, CreateMacro, EditMacro, DeleteMacro, PickupMacro, GetNumMacros;
local LoadAddOn, EnableAddOn, StaticPopup_Show, StaticPopupDialogs = LoadAddOn, EnableAddOn, StaticPopup_Show, StaticPopupDialogs;
local GameFontNormalSmall = GameFontNormalSmall;
local LibStub = LibStub;
local UIParent = UIParent;

if C_AddOns.LoadAddOn then
    LoadAddOn = C_AddOns.LoadAddOn
end

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
    macroSaveWidget = nil,
    discardWidget = nil,
    saveButtonGroupWidget = nil,
    macroDeleteWidget = nil,
    changeIconWidget = nil,
    resetIconWidget = nil,
    readOnlyNoticeWidget = nil,

    -- Snapshot of the macro as last loaded/saved/discarded. Save/Discard are only
    -- enabled when the live widgets have drifted from this baseline.
    originalMacro = nil,

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

-- "readonly" mode is used for browsing another character's macro snapshot. There's
-- no live macro slot backing it, just the name/icon/body captured the last time
-- that character logged in, so editing isn't possible.
function MacroEditor.SetReadOnlyMode(characterName, macroName, macroIcon, macroBody)
    MacroEditor.mode = "readonly";
    MacroEditor.selectedMacro = {
        index = nil,
        type = "character",
        name = macroName,
        icon = macroIcon,
        body = macroBody,
        iconModified = false,
        snapshotCharacterName = characterName
    };
    MacroEditor.RefreshWidgets();
end

function MacroEditor.RefreshWidgets()
    if MacroEditor.selectedMacro.icon then
        MacroEditor.macroIconWidget:SetImage(MacroEditor.selectedMacro.icon);
    else
        MacroEditor.macroIconWidget:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    end

    local isReadOnly = MacroEditor.mode == "readonly";

    -- Snapshot the freshly (re)loaded macro as the "clean" baseline that Save/Discard
    -- compare future edits against. Must happen before the widgets below are
    -- populated, since populating them fires OnTextChanged, which checks dirty state.
    MacroEditor.originalMacro = {
        name = MacroEditor.selectedMacro.name,
        icon = MacroEditor.selectedMacro.icon,
        body = MacroEditor.selectedMacro.body,
        type = MacroEditor.selectedMacro.type
    };

    local isAccountMacro = MacroEditor.selectedMacro.type == "account";
    MacroEditor.macroTypeRadioButtons.accountMacroRadioButton:SetValue(isAccountMacro);
    MacroEditor.macroTypeRadioButtons.characterMacroRadioButton:SetValue(not isAccountMacro);
    MacroEditor.macroTypeRadioButtons.accountMacroRadioButton:SetDisabled(isReadOnly);
    MacroEditor.macroTypeRadioButtons.characterMacroRadioButton:SetDisabled(isReadOnly);

    -- Set edit box value and force OnTextChanged to update label with character count
    MacroEditor.macroNameWidget:SetText(MacroEditor.selectedMacro.name);
    MacroEditor.macroNameWidget:Fire("OnTextChanged");
    MacroEditor.macroNameWidget:SetDisabled(isReadOnly);

    local macroBody = MacroEditor.selectedMacro.body;
    if not macroBody then
        -- Can't SetText with a nil value
        macroBody = "";
    end

    -- Same as name widget update
    MacroEditor.macroBodyWidget:SetText(macroBody);
    MacroEditor.macroBodyWidget:Fire("OnTextChanged");
    MacroEditor.macroBodyWidget:SetDisabled(isReadOnly);

    if isReadOnly then
        MacroEditor.readOnlyNoticeWidget:SetText(
            "Read-only copy of a macro from "..MacroEditor.selectedMacro.snapshotCharacterName..
            ", captured the last time that character logged in."
        );
    else
        -- Clear the text so the (hidden) label collapses back down to AceGUI's
        -- minimal label height instead of leaving a gap sized for whatever
        -- read-only message was shown last.
        MacroEditor.readOnlyNoticeWidget:SetText("");
    end

    MacroEditor.RefreshVisibility();
    MacroEditor.RefreshDirtyState();
end

-- Whether the live widgets have drifted from MacroEditor.originalMacro, i.e. whether
-- there's anything for Save/Discard to act on.
function MacroEditor.IsDirty()
    if MacroEditor.mode == "readonly" then
        return false;
    end

    local original = MacroEditor.originalMacro;
    if not original then
        return false;
    end

    if MacroEditor.selectedMacro.iconModified then
        return true;
    end

    if MacroEditor.selectedMacro.type ~= original.type then
        return true;
    end

    if MacroEditor.macroNameWidget:GetText() ~= (original.name or "") then
        return true;
    end

    if MacroEditor.macroBodyWidget:GetText() ~= (original.body or "") then
        return true;
    end

    return false;
end

-- Called after anything that could change dirty state: every keystroke in the name/body
-- boxes, macro type toggles, and icon changes.
function MacroEditor.RefreshDirtyState()
    local isDirty = MacroEditor.IsDirty();
    MacroEditor.macroSaveWidget:SetDisabled(not isDirty);
    MacroEditor.discardWidget:SetDisabled(not isDirty);
end

-- Reverts the form back to MacroEditor.originalMacro, discarding any unsaved edits.
function MacroEditor.DiscardChanges()
    local original = MacroEditor.originalMacro;
    MacroEditor.selectedMacro.name = original.name;
    MacroEditor.selectedMacro.icon = original.icon;
    MacroEditor.selectedMacro.body = original.body;
    MacroEditor.selectedMacro.type = original.type;
    MacroEditor.selectedMacro.iconModified = false;
    MacroEditor.RefreshWidgets();
end

-- AceGUI's List/Flow layouts reserve height for every child regardless of Show/Hide
-- state, so merely hiding a button still leaves a gap where it used to be. Collapse
-- it to zero height instead, and restore `widget.naturalHeight` (captured once, right
-- after the widget's initial layout in Create(), before it's ever hidden) when shown.
local function SetShown(widget, shown)
    if shown then
        widget.frame:Show();
        widget:SetHeight(widget.naturalHeight);
    else
        widget.frame:Hide();
        -- Not an exact 0: AceGUI's own Label widget explicitly avoids that ("avoid
        -- zero-height labels, since they can [be] used as spacers" - see
        -- AceGUIWidget-Label.lua's UpdateImageAnchor) because a frame with truly
        -- zero height breaks position/anchor resolution for whatever the "List"
        -- layout anchors below it (confirmed live: the macro body box, anchored
        -- transitively to one of these buttons, silently failed to render - shown,
        -- visible, correct width/height, but GetTop()/GetLeft() both nil - only
        -- when one of these buttons was collapsed to exactly 0).
        widget:SetHeight(0.01);
    end
end

-- AceGUI's "List" layout (used by MacroEditor.container) unconditionally shows every
-- child's frame whenever it lays out, which happens any time the window is resized.
-- That would undo the SetShown() calls below, so this is re-run after every layout
-- pass (see the LayoutFinished hook in Create()) instead of only from RefreshWidgets.
function MacroEditor.RefreshVisibility()
    local isReadOnly = MacroEditor.mode == "readonly";

    SetShown(MacroEditor.saveButtonGroupWidget, not isReadOnly);
    SetShown(MacroEditor.changeIconWidget, not isReadOnly);
    SetShown(MacroEditor.resetIconWidget, not isReadOnly);
    SetShown(MacroEditor.macroDeleteWidget, MacroEditor.mode == "edit");

    if isReadOnly then
        MacroEditor.readOnlyNoticeWidget.frame:Show();
    else
        MacroEditor.readOnlyNoticeWidget.frame:Hide();
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
        MacroEditor.RefreshDirtyState();
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
        MacroEditor.RefreshDirtyState();
    end)

    macroTypeGroup:AddChild(macroTypeRadioButtons.characterMacroRadioButton);
    macroTypeGroup:AddChild(macroTypeRadioButtons.accountMacroRadioButton);

    local macroNameEditBox = AceGUI:Create("EditBox");
    macroNameEditBox:SetLabel("Macro Name (0/16)");
    macroNameEditBox:SetWidth(200);
    macroNameEditBox:DisableButton(true);
    macroNameEditBox:SetMaxLetters(16);
    macroNameEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Name ("..macroNameEditBox.editbox:GetNumLetters().."/16)");
        MacroEditor.RefreshDirtyState();
    end);

    local macroBodyEditBox = AceGUI:Create("MacroManagerMultiLineEditBox");
    macroBodyEditBox:SetLabel("Macro Body (0/255)");
    macroBodyEditBox:SetRelativeWidth(1);
    macroBodyEditBox:DisableButton(true);
    macroBodyEditBox:SetMaxLetters(255);
    macroBodyEditBox:SetNumLines(10);
    macroBodyEditBox.editBox:SetCountInvisibleLetters(true);
    macroBodyEditBox:SetCallback("OnTextChanged", function(self)
        self:SetLabel("Macro Body ("..macroBodyEditBox.editBox:GetNumLetters().."/255)");
        MacroEditor.RefreshDirtyState();
    end);

    local macroIcon = AceGUI:Create("Icon");
    macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
    macroIcon:SetImageSize(48, 48);
    macroIcon:SetCallback("OnClick", function()
        if MacroEditor.mode == "edit" then
            PickupMacro(MacroEditor.selectedMacro.index);
        end;
    end);
    macroIcon.frame:RegisterForDrag("LeftButton")
    macroIcon.frame:SetScript("OnDragStart", function()
        if MacroEditor.mode == "edit" then
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
    changeIconButton.naturalHeight = changeIconButton.frame:GetHeight();
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
            MacroEditor.RefreshDirtyState();
        end);
        MacroEditor.iconPicker:ClearAllPoints();
        MacroEditor.iconPicker:SetPoint("TOP", Private.Layout.Window.container.frame, "TOP");
        MacroEditor.iconPicker:SetPoint("LEFT", Private.Layout.Window.container.frame, "RIGHT");
        MacroEditor.iconPicker:Show();
    end);

    local useQuestionMarkIconButton = AceGUI:Create("Button");
    useQuestionMarkIconButton:SetText("Reset Icon (?)");
    useQuestionMarkIconButton:SetWidth(125);
    useQuestionMarkIconButton.naturalHeight = useQuestionMarkIconButton.frame:GetHeight();
    useQuestionMarkIconButton:SetCallback("OnClick", function()
        macroIcon:SetImage("INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK");
        MacroEditor.selectedMacro.iconModified = true;
        MacroEditor.RefreshDirtyState();
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

    local discardButton = AceGUI:Create("Button");
    discardButton:SetText("Discard");
    discardButton:SetWidth(100);
    discardButton:SetCallback("OnClick", function()
        MacroEditor.DiscardChanges();
    end);

    local saveButtonGroup = AceGUI:Create("SimpleGroup");
    saveButtonGroup:SetLayout("Flow");
    saveButtonGroup:AddChild(saveButton);
    saveButtonGroup:AddChild(discardButton);
    -- Not full-width: that would flag it as a "fill" child, which makes the outer
    -- List layout re-trigger this group's own layout (and its auto-height-from-
    -- content) on every resize, fighting the SetShown() height override below.
    -- The default SimpleGroup width comfortably fits the two 100px buttons anyway.
    saveButtonGroup.naturalHeight = saveButtonGroup.frame:GetHeight();
    -- SimpleGroup is a container, so its .content frame gets a native OnSizeChanged
    -- hook (see ContentResize/RegisterAsContainer in AceGUI-3.0.lua) that re-runs this
    -- group's own Flow layout any time .content's real size changes -- including the
    -- change caused by SetShown()'s SetHeight(0) below. That re-layout's LayoutFinished
    -- unconditionally calls SetHeight(<natural height>) again (see AceGUIContainer-
    -- SimpleGroup.lua), silently reverting our collapse a moment later. Disabling
    -- auto-height stops that fight; must come *after* the natural height above is
    -- captured, since that capture relies on the auto-height Flow computed for us.
    saveButtonGroup:SetAutoAdjustHeight(false);

    local deleteButton = AceGUI:Create("Button");
    deleteButton:SetText("Delete");
    deleteButton:SetWidth(100);
    deleteButton.naturalHeight = deleteButton.frame:GetHeight();
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

    local readOnlyNoticeLabel = AceGUI:Create("Label");
    readOnlyNoticeLabel:SetFullWidth(true);
    readOnlyNoticeLabel:SetColor(1, 0.82, 0);
    readOnlyNoticeLabel:SetText("");

    local scroll = AceGUI:Create("ScrollFrame");
    scroll:SetLayout("List");
    scroll:SetFullWidth(true);
    scroll:SetFullHeight(true);
    scroll:SetStatusTable(MacroEditor.statusTable);

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
    scroll:AddChild(saveButtonGroup);
    scroll:AddChild(MacroEditor.CreateSeparatorLabel());
    scroll:AddChild(deleteButton);
    scroll:AddChild(readOnlyNoticeLabel);

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
    MacroEditor.macroSaveWidget = saveButton;
    MacroEditor.discardWidget = discardButton;
    MacroEditor.saveButtonGroupWidget = saveButtonGroup;
    MacroEditor.macroDeleteWidget = deleteButton;
    MacroEditor.changeIconWidget = changeIconButton;
    MacroEditor.resetIconWidget = useQuestionMarkIconButton;
    MacroEditor.readOnlyNoticeWidget = readOnlyNoticeLabel;

    -- Re-apply widget visibility after every layout pass (e.g. window resize), since
    -- AceGUI's List layout unconditionally re-shows every child frame. Wrap rather than
    -- replace: the ScrollFrame widget's own LayoutFinished fixes up the scroll height.
    local scrollLayoutFinished = scroll.LayoutFinished;
    scroll.LayoutFinished = function(self, width, height)
        scrollLayoutFinished(self, width, height);
        MacroEditor.RefreshVisibility();
    end

    MacroEditor.container = scroll;
end

Private.Layout.MacroEditor = MacroEditor;