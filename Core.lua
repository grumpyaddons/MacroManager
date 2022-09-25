local AddonName, Private = ...

local AceGUI = LibStub("AceGUI-3.0");

local AddonObject = LibStub("AceAddon-3.0"):NewAddon("MacroMicro", "AceConsole-3.0");

MacroMicro = {}

function MacroMicro.IsRetail()
    -- Hard coded for now. Used by SpellCache
    return false;
end

function AddonObject:OnInitialize()
    -- Code that you want to run when the addon is first loaded goes here.
  end

function AddonObject:OnEnable()
    MacroMicroSaved = MacroMicroSaved or {};
    MacroMicroSaved.spellCache = MacroMicroSaved.spellCache or {};
    MacroMicroSaved.dynamicIconCache = MacroMicroSaved.dynamicIconCache or {};

    MacroMicro.spellCache.Load(MacroMicroSaved);
end

function AddonObject:OnDisable()
    -- Called when the addon is disabled
end


local Predictor = {}
function Predictor:Initialize()
end
function Predictor:GetValues(text, values, max)
end
function Predictor:GetValue(text, key)
end
function Predictor:GetHyperlink(key)
end
LibStub("AceGUI-3.0-Search-EditBox"):Register("MacroPredictor", Predictor)

local frame = nil;
local iconPickerParent = nil;

local sharedMacroLabel = nil;

local scrollStatusTable = {
    scrollvalue = 0,
    offset = 0
};

local scrollStatusTable = {
    scrollvalue = 0,
    offset = 0
};

local fameStatusTable = {};

local macroTree = nil;
local macroTreeStatusTable = {};

local selectedMacroId = nil;
local selectedMacroLabel = nil;
local selectedMacroTexture = nil;

local macroIcon = nil;
local macroBodyEditBox = nil;
local macroNameEditBox = nil;
local macroIsAccountTypeRadioButton = nil;

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

function CreateMacroHeaderLabel(text)
    local label = AceGUI:Create("Label");
    label:SetFullWidth(true);
    label:SetText(text);
    local background = label.frame:CreateTexture(nil, "BACKGROUND");
    background:SetBlendMode("BLEND");
    background:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight");
    background:SetAllPoints(label.frame);
    label:SetFontObject(GameFontHighlight);
    return label;
end

function Private.OpenSharedMacroWithData(data)
    ShowMacroMicro()
    macroTree:SelectByValue("new");
    Private.OpenSharedMacro(sharedMacroLabel, data);
end

function Private.OpenSharedMacro(label, data)
    local macroName, macroTexture, macroBody = "", "INTERFACE\\ICONS\\INV_MISC_QUESTIONMARK", ""
    if data then
        macroName = data.macroName
        macroTexture = data.macroTexture
        macroBody = data.macroBody   
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
    local maxMacroButtons = 138;
    for i=1, maxMacroButtons do
        name, texture, body = GetMacroInfo(i);
        
        if name ~= nil then
            local data = {
                value = i,
                text = name,
                icon = texture
            };
            if i < 121 then
                table.insert(accountMacros, data);
            else
                table.insert(characterMacros, data);
            end
        end
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
    frame:SetStatusTable(fameStatusTable);
    -- Setting the frame to high as it was above the delete macro dialog box
    frame.frame:SetFrameStrata("HIGH");
    frame:SetTitle("MacroMicro");
    frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end);
    frame:SetLayout("Fill");
    

    iconPickerParent = iconPickerParent or AceGUI:Create("Window");
    iconPickerParent:SetLayout("Fill");
    iconPickerParent.iconPicker = Private.IconPicker(frame.frame);
    iconPickerParent:Hide();

    -- Close on escape taken from https://stackoverflow.com/a/61215014
    -- Add the frame as a global variable under the name `MyGlobalFrameName`
    _G["MacroMicroFrame"] = frame.frame
    _G["MacroMicroIconPickerFrame"] = iconPickerParent.frame;
    -- Register the global variable `MyGlobalFrameName` as a "special frame"
    -- so that it is closed when the escape key is pressed.
    tinsert(UISpecialFrames, "MacroMicroFrame")
    tinsert(UISpecialFrames, "MacroMicroIconPickerFrame")

    local macroTreeContainer = AceGUI:Create("SimpleGroup");
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

    local newButton = AceGUI:Create("Button");
    newButton:SetText("New Macro");
    newButton:SetCallback("OnClick", function()
        Private.OpenSharedMacro(self, nil);
    end);

    macroTreeContainer:SetFullWidth(true);
    macroTreeContainer:AddChild(macroTree);


    local macroTypeGroup = AceGUI:Create("SimpleGroup");
    macroTypeGroup:SetLayout("Flow");

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
    
    macroBodyEditBox = AceGUI:Create("MultiLineEditBox");
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

    local changeIconButton = AceGUI:Create("Button");
    changeIconButton:SetText("Change");
    changeIconButton:SetWidth(100);
    changeIconButton:SetCallback("OnClick", function()
        -- iconPickerParent.iconPicker.frame:SetFrameStrata("HIGH");
        -- iconPickerParent.iconPicker.frame:Raise();
        iconPickerParent:AddChild(iconPickerParent.iconPicker);
        iconPickerParent.iconPicker:Open(baseObject, paths, groupIcon, function(pickedIcon)
            macroIcon:SetImage(pickedIcon);
        end);
        iconPickerParent:Show();
    end);

    local saveButton = AceGUI:Create("Button");
    saveButton:SetText("Save");
    saveButton:SetWidth(100);
    saveButton:SetCallback("OnClick", function()
        local newName = macroNameEditBox:GetText();
        local newBody = macroBodyEditBox:GetText();
        local newIcon = macroIcon.image:GetTexture();
        local selectedMacroType, selectedMacroIndex = GetSelectedMacroTypeAndId();
        local editorMacroType = GetMacroTypeSelected();

        if selectedMacroType == "new" then
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


    scroll:AddChild(macroTypeGroup);
    scroll:AddChild(macroNameEditBox);
    scroll:AddChild(macroIcon);
    scroll:AddChild(changeIconButton);
    scroll:AddChild(macroBodyEditBox);
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
SLASH_MACROMICRO1 = "/macromicro";
SLASH_MACROMICRO2 = "/mm";


function ShowMacroMicro() 
    if frame and frame:IsVisible() then
        frame.frame:Hide();
    end
    MacroMicro.spellCache.Build();
    Show_Options();
end

-- Handle coroutines
local dynFrame = {};
do
  -- Internal data
  dynFrame.frame = CreateFrame("Frame");
  dynFrame.update = {};
  dynFrame.size = 0;

  -- Add an action to be resumed via OnUpdate
  function dynFrame.AddAction(self, name, func)
    if not name then
      name = string.format("NIL", dynFrame.size+1);
    end

    if not dynFrame.update[name] then
      dynFrame.update[name] = func;
      dynFrame.size = dynFrame.size + 1
      dynFrame.frame:Show();
    end
  end

  -- Remove an action from OnUpdate
  function dynFrame.RemoveAction(self, name)
    if dynFrame.update[name] then
      dynFrame.update[name] = nil;
      dynFrame.size = dynFrame.size - 1
      if dynFrame.size == 0 then
        dynFrame.frame:Hide();
      end
    end
  end

  -- Setup frame
  dynFrame.frame:Hide();
  dynFrame.frame:SetScript("OnUpdate", function(self, elapsed)
    -- Start timing
    local start = debugprofilestop();
    local hasData = true;

    -- Resume as often as possible (Limit to 16ms per frame -> 60 FPS)
    while (debugprofilestop() - start < 16 and hasData) do
      -- Stop loop without data
      hasData = false;

      -- Resume all coroutines
      for name, func in pairs(dynFrame.update) do
        -- Loop has data
        hasData = true;

        -- Resume or remove
        if coroutine.status(func) ~= "dead" then
          local ok, msg = coroutine.resume(func)
          if not ok then
            geterrorhandler()(msg .. '\n' .. debugstack(func))
          end
        else
          dynFrame:RemoveAction(name);
        end
      end
    end
  end);
end

Private.dynFrame = dynFrame;

function Private.ValueToPath(data, path, value)
    if not data then
      return
    end
    if(#path == 1) then
      data[path[1]] = value;
    else
      local reducedPath = {};
      for i=2,#path do
        reducedPath[i-1] = path[i];
      end
      Private.ValueToPath(data[path[1]], reducedPath, value);
    end
  end
